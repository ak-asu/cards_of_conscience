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
  
  Map<String, SentimentAnalysis> _messageSentiments = {};
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  List<Agent> get agents => _agents;
  List<PolicyDomain> get domains => _domains;
  List<ChatMessage> get messages => _messages;
  Agent? get currentDiplomat => _currentDiplomat;
  PolicyDomain? get currentDomain => _currentDomain;
  NegotiationStage get currentStage => _currentStage;
  int get currentRound => _currentRound;
  
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
      
      // Initialize with the first domain and first diplomat
      if (_domains.isNotEmpty && _agents.isNotEmpty) {
        _currentDomain = _domains.first;
        _currentDiplomat = _agents.first;
        _currentStage = NegotiationStage.claim;
        _currentRound = 1;
        
        // Add system message to start the conversation
        _messages.add(ChatMessage(
          id: 'system_intro',
          senderId: 'system',
          senderName: 'System',
          text: 'Welcome to the policy negotiation for ${_currentDomain!.name}. Each diplomat will present their initial position, followed by responses and counter-arguments, before reaching a conclusion.',
          timestamp: DateTime.now(),
          isUserMessage: false,
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
        text: response,
        timestamp: DateTime.now(),
        isUserMessage: false,
      );
      
      _messages.add(message);
      
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
      text: text,
      timestamp: DateTime.now(),
      isUserMessage: true,
    );
    
    _messages.add(message);
    
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
          text: _getStageTransitionMessage(_currentStage),
          timestamp: DateTime.now(),
          isUserMessage: false,
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
          text: 'The negotiation has concluded. You can now review the transcript and proceed to the next phase to see the impact of your policy decisions.',
          timestamp: DateTime.now(),
          isUserMessage: false,
        ));
        notifyListeners();
      }
    }
  }
  
  // Reset the negotiation for a new domain
  Future<void> switchToDomain(PolicyDomain domain) async {
    if (_domains.contains(domain) && domain != _currentDomain) {
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
        text: 'Welcome to the policy negotiation for ${domain.name}. Each diplomat will present their initial position, followed by responses and counter-arguments, before reaching a conclusion.',
        timestamp: DateTime.now(),
        isUserMessage: false,
      ));
      
      notifyListeners();
      
      // Generate opening claim from the first diplomat
      await _generateResponse();
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
        text: _getStageTransitionMessage(_currentStage),
        timestamp: DateTime.now(),
        isUserMessage: false,
      ));
      
      notifyListeners();
      
      // Generate response for the first diplomat in the new stage
      await _generateResponse();
    }
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
}