import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/agent_model.dart';
import '../models/chat_message.dart';
import '../models/policy_models.dart';
import '../services/gemini_chat_service.dart';

enum NegotiationStage {
  claim,
  counterclaim,
  rebuttal,
  conclusion,
}

class NegotiationMessage {
  final String agentId;
  final String message;
  final DateTime timestamp;
  final NegotiationStage stage;
  final String? domainId;
  final String? policyId;

  NegotiationMessage({
    required this.agentId,
    required this.message,
    required this.stage,
    this.domainId,
    this.policyId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'stage': stage.toString().split('.').last,
      'domainId': domainId,
      'policyId': policyId,
    };
  }

  factory NegotiationMessage.fromJson(Map<String, dynamic> json) {
    return NegotiationMessage(
      agentId: json['agentId'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      stage: NegotiationStage.values.firstWhere(
        (e) => e.toString().split('.').last == json['stage'],
        orElse: () => NegotiationStage.claim,
      ),
      domainId: json['domainId'],
      policyId: json['policyId'],
    );
  }

  Map<String, dynamic> toMap() => toJson();
  
  static NegotiationMessage fromMap(Map<String, dynamic> map) => 
      NegotiationMessage.fromJson(map);
      
  ChatMessage toChatMessage(String senderName) {
    return ChatMessage(
      senderId: agentId,
      senderName: senderName,
      content: message,
      timestamp: timestamp,
      stage: stage.toString().split('.').last,
      topic: domainId,
    );
  }
  
  static NegotiationMessage fromChatMessage(ChatMessage chatMessage, NegotiationStage stage) {
    return NegotiationMessage(
      agentId: chatMessage.senderId,
      message: chatMessage.content,
      timestamp: chatMessage.timestamp,
      stage: stage,
      domainId: chatMessage.topic,
    );
  }
}

class EnhancedNegotiationProvider extends ChangeNotifier {
  final GeminiChatService _geminiService = GeminiChatService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String _error = '';
  
  List<Agent> _agents = [];
  List<PolicyDomain> _domains = [];
  Map<String, int> _userSelections = {};
  Map<Agent, Map<String, int>> _agentSelections = {};
  
  List<ChatMessage> _messages = [];
  Agent? _currentDiplomat;
  PolicyDomain? _currentDomain;
  NegotiationStage _currentStage = NegotiationStage.claim;
  int _currentRound = 1;
  final int _maxRounds = 4;
  
  // Modified topic structure
  Map<String, List<NegotiationMessage>> _topicMessages = {};
  Map<String, bool> _topicCompletionStatus = {};
  Map<String, Map<String, String>> _topicAgentPositions = {};
  String? _currentTopicId;
  Map<String, Map<String, dynamic>> _policyAnalytics = {};
  
  Map<String, SentimentAnalysis> _messageSentiments = {};
  
  // Track user inactivity
  DateTime _lastUserActivity = DateTime.now();
  Timer? _inactivityTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isNegotiating => _isInitialized && _currentTopicId != null;
  
  List<Agent> get agents => _agents;
  List<PolicyDomain> get domains => _domains;
  List<ChatMessage> get messages => _messages;
  Agent? get currentDiplomat => _currentDiplomat;
  PolicyDomain? get currentDomain => _currentDomain;
  NegotiationStage get currentStage => _currentStage;
  int get currentRound => _currentRound;
  
  // Modified topic getters
  List<String> get topicIds => _topicMessages.keys.toList();
  String? get currentTopicId => _currentTopicId;
  List<NegotiationMessage> getTopicMessages(String topicId) => _topicMessages[topicId] ?? [];
  bool isTopicCompleted(String topicId) => _topicCompletionStatus[topicId] ?? false;
  Map<String, dynamic> getDomainAnalytics(String domainId) => _policyAnalytics[domainId] ?? {};
  
  // Get agent positions for a specific topic
  Map<String, String> getAgentPositions(String topicId) => _topicAgentPositions[topicId] ?? {};
  
  Map<String, SentimentAnalysis> get messageSentiments => _messageSentiments;
  
  // Calculate progress percentage based on stage and round
  double get progressPercentage {
    final totalStages = 4; // claim, counterclaim, rebuttal, conclusion
    final stageIndex = _currentStage.index;
    return (stageIndex / totalStages) * 100;
  }
  
  // Initialize negotiation with user and agent selections
  Future<void> initializeNegotiation(
    List<Agent> agents,
    List<PolicyDomain> domains,
    Map<String, int> userSelections,
    Map<Agent, Map<String, int>> agentSelections,
  ) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _agents = List.from(agents.where((a) => a.id.startsWith('diplomat')));
      _domains = List.from(domains);
      _userSelections = Map.from(userSelections);
      _agentSelections = Map.from(agentSelections);
      
      // Initialize topics
      _topicMessages = {};
      _topicCompletionStatus = {};
      _topicAgentPositions = {};
      _policyAnalytics = {};
      
      for (final domain in domains) {
        final topicId = 'topic_${domain.id}';
        
        _topicMessages[topicId] = [];
        _topicCompletionStatus[topicId] = false;
        _topicAgentPositions[topicId] = {};
      }
      
      if (_topicMessages.isNotEmpty) {
        _currentTopicId = _topicMessages.keys.first;
      }
      
      // Initialize with the first domain and first diplomat
      if (_domains.isNotEmpty && _agents.isNotEmpty) {
        _currentDomain = _domains.first;
        _currentDiplomat = _agents.first;
        _currentStage = NegotiationStage.claim;
        _currentRound = 1;
        
        // Add system message to start the conversation
        _messages.add(ChatMessage(
          senderId: 'system',
          senderName: 'System',
          content: 'Welcome to the policy negotiation for ${_currentDomain!.name}. Each diplomat will present their initial position, followed by responses and counter-arguments, before reaching a conclusion.',
          type: MessageType.system,
        ));
        
        // Generate opening claim from the first diplomat
        await _generateResponse();
      }
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize negotiation: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }
  
  // Generate next AI response in the negotiation
  Future<void> _generateResponse() async {
    if (_currentDiplomat == null || _currentDomain == null) {
      _error = 'Cannot generate response: diplomat or domain is null';
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final diplomat = _currentDiplomat!;
      final domain = _currentDomain!;
      
      // Get this diplomat's selection for the current domain
      final diplomatSelections = _agentSelections[diplomat] ?? {};
      final selection = diplomatSelections[domain.id] ?? 1;
      
      // Generate response with timeout safeguard
      String response;
      try {
        response = await _geminiService.generateResponse(
          agent: diplomat,
          conversationHistory: _messages,
          domain: domain,
          stage: _currentStage,
          agentSelection: selection,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Response generation timed out');
            return _getFallbackResponse(diplomat, domain, _currentStage);
          },
        );
      } catch (e) {
        debugPrint('Error generating response: $e');
        response = _getFallbackResponse(diplomat, domain, _currentStage);
      }
      
      // Add the response to the messages
      final message = ChatMessage(
        id: 'msg_${_messages.length}',
        senderId: diplomat.id,
        senderName: diplomat.name,
        content: response,
        timestamp: DateTime.now(),
      );
      
      _messages.add(message);
      
      // Also add to topic messages for persistence
      if (_currentTopicId != null && _currentDomain != null) {
        final negotiationMessage = NegotiationMessage(
          agentId: diplomat.id,
          message: response,
          stage: _currentStage,
          domainId: _currentDomain!.id,
          policyId: selection.toString(),
        );
        
        if (_topicMessages.containsKey(_currentTopicId)) {
          _topicMessages[_currentTopicId]!.add(negotiationMessage);
        }
        
        // Update agent position in topic
        if (_topicAgentPositions.containsKey(_currentTopicId)) {
          _topicAgentPositions[_currentTopicId]![diplomat.id] = selection.toString();
        }
      }
      
      // Create a simple sentiment analysis with timeout safeguard
      SentimentAnalysis sentiment;
      try {
        sentiment = await _geminiService.analyzeSentiment(response).timeout(
          const Duration(seconds: 5),
          onTimeout: () => SentimentAnalysis.empty(),
        );
      } catch (e) {
        debugPrint('Error analyzing sentiment: $e');
        sentiment = SentimentAnalysis.empty();
      }
      _messageSentiments[message.id] = sentiment;
      
      _isLoading = false;
      notifyListeners();
      
      // Calculate delay based on message length (5-10 seconds)
      final int messageLength = response.length;
      final int delaySeconds = messageLength < 500 ? 5 : messageLength < 1000 ? 7 : 10;
      
      // Auto-advance to next diplomat or stage after a delay
      if (_currentDiplomat != null) {
        await Future.delayed(Duration(seconds: delaySeconds));
        
        // Check if we should prompt for user input instead of auto-advancing
        if (_shouldPromptForUserInput()) {
          _promptForUserInput();
        } else {
          _advanceNegotiation();
        }
      }
    } catch (e) {
      _error = 'Failed to generate response: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  // Determine if we should prompt for user input
  bool _shouldPromptForUserInput() {
    // Always prompt user after the first diplomat in each stage
    if (_currentDiplomat != null && _agents.indexOf(_currentDiplomat!) == 0) {
      return true;
    }
    
    // Prompt after every other diplomat
    if (_currentDiplomat != null) {
      final currentIndex = _agents.indexOf(_currentDiplomat!);
      return currentIndex % 2 == 0;
    }
    
    // Prompt with 50% chance after any message
    return math.Random().nextDouble() < 0.5;
  }
  
  // Prompt the user to provide input
  void _promptForUserInput() {
    if (_messages.isNotEmpty && _messages.last.senderId != 'system' && _messages.last.senderId != 'user_prompt') {
      _messages.add(ChatMessage(
        id: 'user_prompt_${_messages.length}',
        senderId: 'user_prompt',
        senderName: 'System',
        content: 'What are your thoughts on this discussion? You can contribute to the conversation.',
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
      notifyListeners();
    }
  }

  // Get fallback response if API fails
  String _getFallbackResponse(Agent diplomat, PolicyDomain domain, NegotiationStage stage) {
    final policyOption = domain.options.isNotEmpty ? domain.options.first.title : 'the proposed policy';
    
    switch (stage) {
      case NegotiationStage.claim:
        return 'As ${diplomat.name}, I believe $policyOption is crucial for addressing challenges in ${domain.name}. '
               "With my background in ${diplomat.occupation}, I've seen firsthand how this approach can benefit communities. "
               "We should prioritize this policy direction based on ${diplomat.perspective ?? 'evidence-based practices'}.";
      
      case NegotiationStage.counterclaim:
        return 'While I appreciate the other perspectives, I must emphasize that $policyOption has significant merits. '
               "My experience in ${diplomat.occupation} has taught me that we need to consider ${diplomat.ideology.isNotEmpty ? diplomat.ideology : 'practical solutions'}. "
               'I believe this approach balances various needs more effectively.';
      
      case NegotiationStage.rebuttal:
        return 'I understand the concerns raised, but $policyOption remains the most viable solution for ${domain.name}. '
               "The criticisms don't fully account for the long-term benefits this policy would bring. "
               'From my ${diplomat.education} background, I can affirm that this approach is both sustainable and effective.';
      
      case NegotiationStage.conclusion:
        return 'After this thorough discussion, I still support $policyOption while acknowledging valid points from my colleagues. '
               'Perhaps we can incorporate some elements from other proposals to strengthen our approach. '
               'Ultimately, our shared goal is to create the best policy for all stakeholders involved.';
    }
  }
  
  // Add a user message to the negotiation
  Future<void> addUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final message = ChatMessage(
      id: 'user_${_messages.length}',
      senderId: 'user',
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
      isFromUser: true,
    );
    
    _messages.add(message);
    
    // Also add to topic messages for persistence
    if (_currentTopicId != null && _currentDomain != null) {
      final negotiationMessage = NegotiationMessage(
        agentId: 'user',
        message: text,
        stage: _currentStage,
        domainId: _currentDomain!.id,
      );
      
      if (_topicMessages.containsKey(_currentTopicId)) {
        _topicMessages[_currentTopicId]!.add(negotiationMessage);
      }
    }
    
    // Analyze sentiment of user's message
    final sentiment = await _geminiService.analyzeSentiment(text);
    _messageSentiments[message.id] = sentiment;
    
    notifyListeners();
    
    // Schedule agent response to user's message
    // Choose the most appropriate agent to respond based on context
    _scheduleAgentResponseToUser();
  }
  
  // Schedule an agent to respond to the user's message
  Future<void> _scheduleAgentResponseToUser() async {
    if (_agents.isEmpty) return;
    
    // Find the most appropriate agent to respond
    // 1. If there's a current diplomat, have them respond
    // 2. Otherwise, choose the agent whose opinions align or contrast most with the user's message
    Agent respondingAgent;
    
    if (_currentDiplomat != null) {
      respondingAgent = _currentDiplomat!;
    } else {
      // Select the first diplomat by default if we can't determine the current one
      respondingAgent = _agents.first;
    }
    
    // Add short delay before agent responds (feels more natural)
    await Future.delayed(const Duration(seconds: 2));
    
    // Set the chosen agent as the current diplomat
    _currentDiplomat = respondingAgent;
    
    // Generate their response
    await _generateResponse();
  }
  
  // Track user inactivity
  void startInactivityMonitor() {
    _lastUserActivity = DateTime.now();
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkUserInactivity();
    });
  }
  
  // Stop monitoring for user inactivity
  void stopInactivityMonitor() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
  
  // Check if the user has been inactive for too long
  void _checkUserInactivity() {
    final now = DateTime.now();
    final inactiveFor = now.difference(_lastUserActivity).inSeconds;
    
    // If user has been inactive for more than 30 seconds and we're in the middle of a negotiation
    if (inactiveFor > 30 && isNegotiating && _messages.isNotEmpty && _messages.last.senderId != 'system') {
      // Check if last message was from AI
      if (!_messages.last.isFromUser) {
        // If AI already sent the last message, only prompt occasionally to avoid spam
        if (inactiveFor > 90 && math.Random().nextDouble() < 0.3) {
          _promptForUserInput();
        }
      } else {
        // Last message was from user, AI should respond
        _scheduleAgentResponseToUser();
      }
    }
  }
  
  // Update the last user activity timestamp
  void updateUserActivity() {
    _lastUserActivity = DateTime.now();
  }
    
  // Advance to the next diplomat or stage
  void _advanceNegotiation() {
    // If we have more diplomats in the current stage, move to the next diplomat
    final diplomatIndex = _currentDiplomat != null ? _agents.indexOf(_currentDiplomat!) : -1;
    
    if (diplomatIndex < _agents.length - 1) {
      // Move to next diplomat
      _currentDiplomat = _agents[diplomatIndex + 1];
      _generateResponse();
    } else {
      // We've gone through all diplomats in this stage, move to next stage
      final currentStageIndex = _currentStage.index;
      
      if (currentStageIndex < NegotiationStage.values.length - 1) {
        // Move to next stage and start with the first diplomat
        _currentStage = NegotiationStage.values[currentStageIndex + 1];
        _currentDiplomat = _agents.first;
        _currentRound++;
        
        // Add system message for stage transition
        _messages.add(ChatMessage(
          id: 'system_stage_${_currentStage.index}',
          senderId: 'system',
          senderName: 'System',
          content: _getStageTransitionMessage(_currentStage),
          timestamp: DateTime.now(),
          type: MessageType.system,
        ));
        
        notifyListeners();
        
        // Generate response for the first diplomat in the new stage
        _generateResponse();
      } else {
        // We've completed all stages, mark negotiation as complete
        _messages.add(ChatMessage(
          id: 'system_complete',
          senderId: 'system',
          senderName: 'System',
          content: 'The negotiation has concluded. You can now review the transcript and proceed to the next phase to see the impact of your policy decisions.',
          timestamp: DateTime.now(),
        ));
        
        // Mark the current topic as completed
        if (_currentTopicId != null) {
          _topicCompletionStatus[_currentTopicId!] = true;
        }
        
        // Analyze the current topic
        _analyzeCurrentTopic();
        
        notifyListeners();
      }
    }
  }
  
  // Reset the negotiation for a new domain
  Future<void> switchToDomain(PolicyDomain domain) async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    if (_domains.contains(domain)) {
      _isLoading = true;
      notifyListeners();
      
      try {
        // Find or create the topic ID for this domain
        final topicId = 'topic_${domain.id}';
        if (!_topicMessages.containsKey(topicId)) {
          _topicMessages[topicId] = [];
          _topicCompletionStatus[topicId] = false;
          _topicAgentPositions[topicId] = {};
        }
        
        _currentTopicId = topicId;
        _currentDomain = domain;
        _currentStage = NegotiationStage.claim;
        _currentRound = 1;
        _currentDiplomat = _agents.first;
        _messages = [];
        _messageSentiments = {};
        
        // Add system message to start the conversation
        _messages.add(ChatMessage(
          id: 'system_intro',
          senderId: 'system',
          senderName: 'System',
          content: 'Welcome to the policy negotiation for ${domain.name}. Each diplomat will present their initial position, followed by responses and counter-arguments, before reaching a conclusion.',
          timestamp: DateTime.now(),
        ));
        
        notifyListeners();
        
        // Generate opening claim from the first diplomat
        await _generateResponse();
      } catch (e) {
        _error = 'Failed to switch domain: $e';
        debugPrint(_error);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  
  // Functionality to analyze current topic and generate analytics
  Future<void> _analyzeCurrentTopic() async {
    if (_currentDomain == null) return;
    
    final domainId = _currentDomain!.id;
    
    try {
      // Create a map of domain impacts for analysis
      final Map<PolicyDomain, List<double>> domainImpacts = {};
      if (_currentDomain != null) {
        domainImpacts[_currentDomain!] = [0.5, 0.5, 0.7]; // Placeholder impact scores
      }
      
      // Create a map of agent selections for the current domain
      final Map<String, int> agentSelections = {};
      
      for (final entry in _agentSelections.entries) {
        final agent = entry.key;
        final selections = entry.value;
        if (selections.containsKey(domainId)) {
          agentSelections[agent.id] = selections[domainId]!;
        }
      }
      
      // Add user selection
      if (_userSelections.containsKey(domainId)) {
        agentSelections['user'] = _userSelections[domainId]!;
      }
      
      // Get ethical tradeoff analysis
      final tradeoffAnalysis = await _geminiService.generateEthicalTradeoffAnalysis(
        agentSelections,
        domainImpacts,
      );
      
      // Get policy impact projections
      final impactProjections = await _geminiService.generatePolicyImpactProjections(
        agentSelections,
      );
      
      // Combine analyses into a comprehensive analytics package
      _policyAnalytics[domainId] = {
        'ethicalTradeoffs': tradeoffAnalysis['ethicalTradeoffs'] ?? [],
        'justiceIndex': tradeoffAnalysis['justiceIndex'] ?? {},
        'educationalTheoryConnections': tradeoffAnalysis['educationalTheoryConnections'] ?? [],
        'impacts': impactProjections,
      };
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error analyzing current topic: $e');
    }
  }
  
  // Get a transition message for the given stage
  String _getStageTransitionMessage(NegotiationStage stage) {
    switch (stage) {
      case NegotiationStage.claim:
        return 'The diplomats will now present their initial positions.';
      case NegotiationStage.counterclaim:
        return 'The diplomats will now respond to each other\'s positions and present counter-arguments.';
      case NegotiationStage.rebuttal:
        return 'The diplomats will now address critiques of their positions and defend their stances.';
      case NegotiationStage.conclusion:
        return 'The diplomats will now work toward a conclusion and attempt to find common ground.';
    }
  }
  
  // Force advance to next stage (for user-controlled advancement)
  Future<void> forceAdvanceStage() async {
    final currentStageIndex = _currentStage.index;
    
    if (currentStageIndex < NegotiationStage.values.length - 1) {
      // Move to next stage and start with the first diplomat
      _currentStage = NegotiationStage.values[currentStageIndex + 1];
      _currentDiplomat = _agents.first;
      _currentRound++;
      
      // Add system message for stage transition
      _messages.add(ChatMessage(
        id: 'system_stage_${_currentStage.index}',
        senderId: 'system',
        senderName: 'System',
        content: _getStageTransitionMessage(_currentStage),
        timestamp: DateTime.now(),
        type: MessageType.system,
      ));
      
      notifyListeners();
      
      // Generate response for the first diplomat in the new stage
      await _generateResponse();
    }
  }
    
  // Move to the next topic
  Future<void> moveToNextTopic() async {
    final topicIds = _topicMessages.keys.toList();
    if (topicIds.isEmpty || _currentTopicId == null) return;
    
    final currentIndex = topicIds.indexOf(_currentTopicId!);
    if (currentIndex < 0 || currentIndex >= topicIds.length - 1) {
      // We're at the last topic, nothing to do
      return;
    }
    
    // Analyze the current topic before moving on
    await _analyzeCurrentTopic();
    
    // Move to the next topic
    final nextTopicId = topicIds[currentIndex + 1];
    _currentTopicId = nextTopicId;
    
    // Find the domain for this topic
    final domainId = nextTopicId.replaceFirst('topic_', '');
    final nextDomain = _domains.firstWhere(
      (d) => d.id == domainId,
      orElse: () => _domains.first
    );
    
    // Use the existing switchToDomain method to handle the transition
    await switchToDomain(nextDomain);
  }
  
  // Get the stage for the current topic
  NegotiationStage getCurrentTopicStage() {
    if (_currentTopicId == null || !_topicMessages.containsKey(_currentTopicId!)) {
      return NegotiationStage.claim;
    }
    
    final messages = _topicMessages[_currentTopicId!];
    if (messages == null || messages.isEmpty) {
      return NegotiationStage.claim;
    }
    
    return messages.last.stage;
  }
  
  // Get sentiment analysis for a specific message
  SentimentAnalysis getSentimentForMessage(String messageId) {
    return _messageSentiments[messageId] ?? SentimentAnalysis.empty();
  }
  
  // Get dominant themes from all messages
  List<String> getDominantThemes() {
    final allThemes = <String>{};
    
    for (var sentiment in _messageSentiments.values) {
      allThemes.addAll(sentiment.keyThemes);
    }
    
    return allThemes.toList();
  }
  
  // Get all raised concerns from messages
  List<String> getAllConcerns() {
    final allConcerns = <String>{};
    
    for (var sentiment in _messageSentiments.values) {
      allConcerns.addAll(sentiment.concernsRaised);
    }
    
    return allConcerns.toList();
  }
  
  // Get average justice scores across all messages
  Map<JusticeOrientation, double> getAverageJusticeScores() {
    if (_messageSentiments.isEmpty) {
      return {
        JusticeOrientation.equity: 0.5,
        JusticeOrientation.inclusion: 0.5,
        JusticeOrientation.recognition: 0.5,
        JusticeOrientation.procedural: 0.5,
        JusticeOrientation.distributive: 0.5,
      };
    }
    
    final scoreMap = <JusticeOrientation, List<double>>{
      JusticeOrientation.equity: [],
      JusticeOrientation.inclusion: [],
      JusticeOrientation.recognition: [],
      JusticeOrientation.procedural: [],
      JusticeOrientation.distributive: [],
    };
    
    for (var sentiment in _messageSentiments.values) {
      sentiment.justiceScores.forEach((orientation, score) {
        scoreMap[orientation]?.add(score);
      });
    }
    
    return scoreMap.map((orientation, scores) {
      if (scores.isEmpty) return MapEntry(orientation, 0.5);
      final average = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(orientation, average);
    });
  }
  
  // Reset the entire negotiation
  void resetNegotiation() {
    _isInitialized = false;
    _currentTopicId = null;
    _topicMessages = {};
    _topicCompletionStatus = {};
    _topicAgentPositions = {};
    _messageSentiments = {};
    _policyAnalytics = {};
    _messages = [];
    _currentDiplomat = null;
    _currentDomain = null;
    _currentStage = NegotiationStage.claim;
    _currentRound = 1;
    notifyListeners();
  }

  // For testing and fallback - inject mock topics
  void injectMockTopics(Map<String, List<NegotiationMessage>> mockTopics) {
    _isLoading = false;
    _isInitialized = true;
    _error = '';
    
    // Clear existing topics and replace with mock data
    _topicMessages = mockTopics;
    _topicCompletionStatus = Map.fromEntries(
      mockTopics.keys.map((key) => MapEntry(key, false))
    );
    _topicAgentPositions = Map.fromEntries(
      mockTopics.keys.map((key) => MapEntry(key, <String, String>{}))
    );
    
    if (mockTopics.isNotEmpty) {
      // Set the first topic as the current topic
      _currentTopicId = mockTopics.keys.first;
      
      // Find the domain for this topic
      final domainId = _currentTopicId!.replaceFirst('topic_', '');
      if (_domains.isNotEmpty) {
        _currentDomain = _domains.firstWhere(
          (d) => d.id == domainId,
          orElse: () => _domains.first
        );
      }
      
      // Extract messages from the first topic
      final messages = mockTopics[_currentTopicId]?.map((m) {
        final senderName = m.agentId == 'system' 
            ? 'System' 
            : m.agentId == 'user' 
                ? 'You' 
                : _agents.firstWhere(
                    (a) => a.id == m.agentId, 
                    orElse: () => Agent(
                      id: m.agentId, 
                      name: m.agentId.startsWith('diplomat') ? 'Diplomat' : m.agentId,
                      occupation: 'Unknown',
                      age: 0,
                      education: 'Unknown',
                      socioeconomicStatus: 'Unknown',
                      ideology: '',
                    )
                  ).name;
        
        return ChatMessage(
          id: 'msg_${_messages.length + 1}',
          senderId: m.agentId,
          senderName: senderName,
          content: m.message,
          timestamp: m.timestamp,
        );
      }).toList() ?? [];
      
      _messages = messages;
      
      // Determine current stage based on messages
      final topicMessages = mockTopics[_currentTopicId] ?? [];
      if (topicMessages.any((m) => m.stage == NegotiationStage.conclusion)) {
        _currentStage = NegotiationStage.conclusion;
      } else if (topicMessages.any((m) => m.stage == NegotiationStage.rebuttal)) {
        _currentStage = NegotiationStage.rebuttal;
      } else if (topicMessages.any((m) => m.stage == NegotiationStage.counterclaim)) {
        _currentStage = NegotiationStage.counterclaim;
      } else {
        _currentStage = NegotiationStage.claim;
      }
    }
    
    notifyListeners();
  }
}