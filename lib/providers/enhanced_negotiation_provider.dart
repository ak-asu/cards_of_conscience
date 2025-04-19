import 'dart:async';
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

class NegotiationTopic {
  final String id;
  final String domainId;
  final List<NegotiationMessage> messages;
  final bool isCompleted;
  final Map<String, String> agentPositions; // agentId -> policyId

  NegotiationTopic({
    required this.id,
    required this.domainId,
    List<NegotiationMessage>? messages,
    this.isCompleted = false,
    Map<String, String>? agentPositions,
  }) : 
    messages = messages ?? [],
    agentPositions = agentPositions ?? {};

  NegotiationTopic copyWith({
    String? id,
    String? domainId,
    List<NegotiationMessage>? messages,
    bool? isCompleted,
    Map<String, String>? agentPositions,
  }) {
    return NegotiationTopic(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      messages: messages ?? List.from(this.messages),
      isCompleted: isCompleted ?? this.isCompleted,
      agentPositions: agentPositions ?? Map.from(this.agentPositions),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domainId': domainId,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'isCompleted': isCompleted,
      'agentPositions': agentPositions,
    };
  }

  factory NegotiationTopic.fromJson(Map<String, dynamic> json) {
    return NegotiationTopic(
      id: json['id'],
      domainId: json['domainId'],
      messages: (json['messages'] as List)
          .map((msgJson) => NegotiationMessage.fromJson(msgJson))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
      agentPositions: Map<String, String>.from(json['agentPositions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => toJson();
  
  static NegotiationTopic fromMap(Map<String, dynamic> map) => 
      NegotiationTopic.fromJson(map);

  NegotiationStage get stage => 
      messages.isNotEmpty ? messages.last.stage : NegotiationStage.claim;
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
  
  // Added from original NegotiationProvider
  List<NegotiationTopic> _topics = [];
  String? _currentTopicId;
  Map<String, Map<String, dynamic>> _policyAnalytics = {};
  
  Map<String, SentimentAnalysis> _messageSentiments = {};
  
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
  
  // Added from original provider
  List<NegotiationTopic> get topics => _topics;
  String? get currentTopicId => _currentTopicId;
  NegotiationTopic? get currentTopic => _currentTopicId == null 
      ? null 
      : _topics.firstWhere((topic) => topic.id == _currentTopicId, orElse: () => NegotiationTopic(id: 'empty', domainId: 'empty'));
  Map<String, dynamic> getDomainAnalytics(String domainId) => _policyAnalytics[domainId] ?? {};
  
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
      
      // Initialize topics from original provider
      _topics = [];
      _policyAnalytics = {};
      
      for (final domain in domains) {
        final topicId = 'topic_${domain.id}';
        
        _topics.add(NegotiationTopic(
          id: topicId,
          domainId: domain.id,
          messages: [],
          agentPositions: {},
        ));
      }
      
      if (_topics.isNotEmpty) {
        _currentTopicId = _topics.first.id;
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
      
      // Generate response using Gemini
      final response = await _geminiService.generateResponse(
        agent: diplomat,
        conversationHistory: _messages,
        domain: domain,
        stage: _currentStage,
        agentSelection: selection,
      );
      
      // Add the response to the messages
      final message = ChatMessage(
        id: 'msg_${_messages.length}',
        senderId: diplomat.id,
        senderName: diplomat.name,
        content: response,
        timestamp: DateTime.now(),
      );
      
      _messages.add(message);
      
      // Also add to negotiation topics for persistence
      if (currentTopic != null && _currentDomain != null) {
        final negotiationMessage = NegotiationMessage(
          agentId: diplomat.id,
          message: response,
          stage: _currentStage,
          domainId: _currentDomain!.id,
          policyId: selection.toString(),
        );
        
        final topicIndex = _topics.indexWhere((t) => t.id == _currentTopicId);
        if (topicIndex >= 0) {
          final updatedMessages = List<NegotiationMessage>.from(_topics[topicIndex].messages)
            ..add(negotiationMessage);
          
          _topics[topicIndex] = _topics[topicIndex].copyWith(
            messages: updatedMessages,
          );
        }
      }
      
      // Analyze sentiment
      final sentiment = await _geminiService.analyzeSentiment(response);
      _messageSentiments[message.id] = sentiment;
      
      _isLoading = false;
      notifyListeners();
      
      // Auto-advance to next diplomat or stage after a delay
      if (_currentDiplomat != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _advanceNegotiation();
      }
    } catch (e) {
      _error = 'Failed to generate response: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
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
    
    // Also add to negotiation topics for persistence
    if (currentTopic != null && _currentDomain != null) {
      final negotiationMessage = NegotiationMessage(
        agentId: 'user',
        message: text,
        stage: _currentStage,
        domainId: _currentDomain!.id,
      );
      
      final topicIndex = _topics.indexWhere((t) => t.id == _currentTopicId);
      if (topicIndex >= 0) {
        final updatedMessages = List<NegotiationMessage>.from(_topics[topicIndex].messages)
          ..add(negotiationMessage);
        
        _topics[topicIndex] = _topics[topicIndex].copyWith(
          messages: updatedMessages,
        );
      }
    }
    
    // Analyze sentiment of user's message
    final sentiment = await _geminiService.analyzeSentiment(text);
    _messageSentiments[message.id] = sentiment;
    
    notifyListeners();
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
          final topicIndex = _topics.indexWhere((t) => t.id == _currentTopicId);
          if (topicIndex >= 0) {
            _topics[topicIndex] = _topics[topicIndex].copyWith(isCompleted: true);
          }
        }
        
        // Analyze the current topic
        _analyzeCurrentTopic();
        
        notifyListeners();
      }
    }
  }
  
  // Reset the negotiation for a new domain
  Future<void> switchToDomain(PolicyDomain domain) async {
    if (_domains.contains(domain) && domain != _currentDomain) {
      // Find the corresponding topic for this domain
      final topicId = _topics.firstWhere(
        (t) => t.domainId == domain.id,
        orElse: () => NegotiationTopic(id: 'topic_${domain.id}', domainId: domain.id)
      ).id;
      
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
    
  // Move to the next topic (from original provider)
  Future<void> moveToNextTopic() async {
    if (_topics.isEmpty || _currentTopicId == null) return;
    
    final currentIndex = _topics.indexWhere((topic) => topic.id == _currentTopicId);
    if (currentIndex < 0 || currentIndex >= _topics.length - 1) {
      // We're at the last topic, nothing to do
      return;
    }
    
    // Analyze the current topic before moving on
    await _analyzeCurrentTopic();
    
    // Move to the next topic
    _currentTopicId = _topics[currentIndex + 1].id;
    
    // Update current domain based on the new topic
    final newTopic = _topics[currentIndex + 1];
    final newDomain = _domains.firstWhere(
      (d) => d.id == newTopic.domainId,
      orElse: () => _domains.first
    );
    
    // Use the existing switchToDomain method to handle the transition
    await switchToDomain(newDomain);
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
  
  // Reset the entire negotiation (from original provider)
  void resetNegotiation() {
    _isInitialized = false;
    _currentTopicId = null;
    _topics = [];
    _messageSentiments = {};
    _policyAnalytics = {};
    _messages = [];
    _currentDiplomat = null;
    _currentDomain = null;
    _currentStage = NegotiationStage.claim;
    _currentRound = 1;
    notifyListeners();
  }
}