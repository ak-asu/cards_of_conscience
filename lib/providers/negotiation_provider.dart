import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/agent_model.dart';
import '../models/chat_message.dart';
import '../models/policy_models.dart';
import '../services/gemini_chat_service.dart';

enum NegotiationStage {
  initialClaim,
  counterclaim,
  rebuttal,
  conclusion,
  claim
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
        orElse: () => NegotiationStage.initialClaim,
      ),
      domainId: json['domainId'],
      policyId: json['policyId'],
    );
  }

  Map<String, dynamic> toMap() => toJson();
  
  static NegotiationMessage fromMap(Map<String, dynamic> map) => 
      NegotiationMessage.fromJson(map);
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
}

class EnhancedNegotiationProvider extends ChangeNotifier {
  final GeminiChatService _chatService = GeminiChatService();
  
  bool _isLoading = true;
  bool _isNegotiating = false;
  String? _currentTopicId;
  List<NegotiationTopic> _topics = [];
  Map<String, List<SentimentAnalysis>> _sentimentAnalyses = {};
  Map<String, Map<String, dynamic>> _policyAnalytics = {};

  bool get isLoading => _isLoading;
  bool get isNegotiating => _isNegotiating;
  String? get currentTopicId => _currentTopicId;
  List<NegotiationTopic> get topics => _topics;
  NegotiationTopic? get currentTopic => _currentTopicId == null 
      ? null 
      : _topics.firstWhere((topic) => topic.id == _currentTopicId, orElse: () => NegotiationTopic.empty());
  
  Map<String, List<SentimentAnalysis>> get sentimentAnalyses => _sentimentAnalyses;
  Map<String, dynamic> getDomainAnalytics(String domainId) => _policyAnalytics[domainId] ?? {};

  Future<void> initializeNegotiation(
    List<Agent> agents, 
    List<PolicyDomain> domains,
    Map<String, int> userSelections,
    Map<Agent, Map<String, int>> aiSelections,
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _topics = [];
      _sentimentAnalyses = {};
      _policyAnalytics = {};
      
      for (final domain in domains) {
        final topicId = 'topic_${domain.id}';
        
        final List<ChatMessage> initialMessages = [];
        _topics.add(NegotiationTopic(
          id: topicId,
          domainId: domain.id,
          stage: NegotiationStage.claim,
          messages: initialMessages,
          agentSelections: {},
          finalSelection: null,
        ));
        
        // Pre-compute agent selections for this domain
        final Map<String, int> agentSelections = {};
        
        // Add user selection
        agentSelections['user'] = userSelections[domain.id] ?? 1;
        
        // Add AI agent selections
        for (final agentEntry in aiSelections.entries) {
          final agent = agentEntry.key;
          final selections = agentEntry.value;
          agentSelections[agent.id] = selections[domain.id] ?? 1;
        }
        
        // Save the selections to the topic
        final topic = _topics.firstWhere((t) => t.id == topicId);
        topic.agentSelections = agentSelections;
      }
      
      if (_topics.isNotEmpty) {
        _currentTopicId = _topics.first.id;
        _isNegotiating = true;
      }
      
      _isLoading = false;
      notifyListeners();
      
      // Initialize the first topic with AI agent opening statements
      if (_topics.isNotEmpty) {
        await _generateClaimsForCurrentTopic(agents, domains);
      }
    } catch (e) {
      debugPrint('Error initializing negotiation: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _generateClaimsForCurrentTopic(List<Agent> agents, List<PolicyDomain> domains) async {
    if (currentTopic == null) return;
    
    final topic = currentTopic!;
    final domain = domains.firstWhere(
      (d) => d.id == topic.domainId, 
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown', description: '', options: [])
    );
    
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    for (final agent in diplomats) {
      final selection = topic.agentSelections[agent.id] ?? 1;
      
      final message = await _generateAgentMessage(
        agent: agent,
        domain: domain,
        selection: selection,
        stage: NegotiationStage.claim,
        topic: topic,
      );
      
      topic.messages.add(message);
      notifyListeners();
      
      // Analyze sentiment after each message
      await _analyzeSentiment(message, topic.id);
    }
  }
  
  Future<void> _analyzeSentiment(ChatMessage message, String topicId) async {
    try {
      final analysis = await _chatService.analyzeSentiment(message.text);
      
      if (!_sentimentAnalyses.containsKey(topicId)) {
        _sentimentAnalyses[topicId] = [];
      }
      
      _sentimentAnalyses[topicId]!.add(analysis);
      notifyListeners();
    } catch (e) {
      debugPrint('Error analyzing sentiment: $e');
    }
  }

  Future<void> moveToNextTopic(List<Agent> agents, List<PolicyDomain> domains) async {
    if (_topics.isEmpty || _currentTopicId == null) return;
    
    final currentIndex = _topics.indexWhere((topic) => topic.id == _currentTopicId);
    if (currentIndex < 0 || currentIndex >= _topics.length - 1) {
      // We're at the last topic, nothing to do
      return;
    }
    
    // Analyze the current topic before moving on
    await _analyzeCurrentTopic(domains);
    
    // Move to the next topic
    _currentTopicId = _topics[currentIndex + 1].id;
    notifyListeners();
    
    // Generate claims for the new current topic if it doesn't have any messages yet
    final newCurrentTopic = currentTopic;
    if (newCurrentTopic != null && newCurrentTopic.messages.isEmpty) {
      await _generateClaimsForCurrentTopic(agents, domains);
    }
  }
  
  Future<void> _analyzeCurrentTopic(List<PolicyDomain> domains) async {
    if (currentTopic == null) return;
    
    final topic = currentTopic!;
    final domainId = topic.domainId;
    
    // Find the domain
    final domain = domains.firstWhere(
      (d) => d.id == domainId, 
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown', description: '', options: [])
    );
    
    try {
      // Create a map of domain impacts for analysis
      final Map<PolicyDomain, List<double>> domainImpacts = {};
      domainImpacts[domain] = [0.5, 0.5, 0.7]; // Placeholder impact scores
      
      // Get ethical tradeoff analysis
      final tradeoffAnalysis = await _chatService.generateEthicalTradeoffAnalysis(
        topic.agentSelections,
        domainImpacts,
      );
      
      // Get policy impact projections
      final impactProjections = await _chatService.generatePolicyImpactProjections(
        topic.agentSelections,
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
  
  Future<void> advanceCurrentTopicStage(List<Agent> agents, List<PolicyDomain> domains) async {
    if (currentTopic == null) return;
    
    final topic = currentTopic!;
    final currentStage = topic.stage;
    NegotiationStage nextStage;
    
    switch (currentStage) {
      case NegotiationStage.claim:
        nextStage = NegotiationStage.counterclaim;
        break;
      case NegotiationStage.counterclaim:
        nextStage = NegotiationStage.rebuttal;
        break;
      case NegotiationStage.rebuttal:
        nextStage = NegotiationStage.conclusion;
        break;
      case NegotiationStage.conclusion:
        // We're already at the conclusion, nothing to do
        return;
    }
    
    topic.stage = nextStage;
    notifyListeners();
    
    // Generate responses for the new stage
    await _generateResponsesForCurrentStage(agents, domains);
  }
  
  Future<void> _generateResponsesForCurrentStage(List<Agent> agents, List<PolicyDomain> domains) async {
    if (currentTopic == null) return;
    
    final topic = currentTopic!;
    final domain = domains.firstWhere(
      (d) => d.id == topic.domainId, 
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown', description: '', options: [])
    );
    
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    for (final agent in diplomats) {
      final selection = topic.agentSelections[agent.id] ?? 1;
      
      final message = await _generateAgentMessage(
        agent: agent,
        domain: domain,
        selection: selection,
        stage: topic.stage,
        topic: topic,
      );
      
      topic.messages.add(message);
      notifyListeners();
      
      // Analyze sentiment after each message
      await _analyzeSentiment(message, topic.id);
      
      // Add a small delay between messages to make it feel more natural
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }
  
  Future<ChatMessage> _generateAgentMessage({
    required Agent agent,
    required PolicyDomain domain,
    required int selection,
    required NegotiationStage stage,
    required NegotiationTopic topic,
  }) async {
    try {
      // Get conversation history
      final List<String> conversationHistory = topic.messages
          .map((m) => '${m.senderName}: ${m.text}')
          .toList();
      
      // Generate response
      final response = await _chatService.generateResponse(
        agent: agent,
        conversationHistory: conversationHistory,
        currentDomain: domain,
        selectedPolicies: {domain.id: selection},
        stage: stage,
      );
      
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${agent.id}',
        senderId: agent.id,
        senderName: agent.name,
        text: response,
        timestamp: DateTime.now(),
        stage: stage,
        policyOption: selection,
      );
    } catch (e) {
      debugPrint('Error generating agent message: $e');
      
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${agent.id}',
        senderId: agent.id,
        senderName: agent.name,
        text: "I apologize, but I'm having trouble articulating my position right now.",
        timestamp: DateTime.now(),
        stage: stage,
        policyOption: selection,
      );
    }
  }
  
  Future<void> addUserMessage(String message, List<Agent> agents, List<PolicyDomain> domains) async {
    if (currentTopic == null) return;
    
    final topic = currentTopic!;
    
    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      senderId: 'user',
      senderName: 'You',
      text: message,
      timestamp: DateTime.now(),
      stage: topic.stage,
      policyOption: topic.agentSelections['user'] ?? 1,
    );
    
    topic.messages.add(userMessage);
    notifyListeners();
    
    // Analyze sentiment
    await _analyzeSentiment(userMessage, topic.id);
    
    // Generate responses from AI agents
    final domain = domains.firstWhere(
      (d) => d.id == topic.domainId, 
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown', description: '', options: [])
    );
    
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    // Select one agent to respond directly to the user
    if (diplomats.isNotEmpty) {
      final respondingAgent = diplomats[DateTime.now().second % diplomats.length];
      final selection = topic.agentSelections[respondingAgent.id] ?? 1;
      
      final responseMessage = await _generateAgentMessage(
        agent: respondingAgent,
        domain: domain,
        selection: selection,
        stage: topic.stage,
        topic: topic,
      );
      
      topic.messages.add(responseMessage);
      notifyListeners();
      
      // Analyze sentiment
      await _analyzeSentiment(responseMessage, topic.id);
    }
  }
  
  void resetNegotiation() {
    _isNegotiating = false;
    _currentTopicId = null;
    _topics = [];
    _sentimentAnalyses = {};
    _policyAnalytics = {};
    notifyListeners();
  }
}

class NegotiationTopic {
  final String id;
  final String domainId;
  NegotiationStage stage;
  final List<ChatMessage> messages;
  Map<String, int> agentSelections;
  int? finalSelection;
  
  NegotiationTopic({
    required this.id,
    required this.domainId,
    required this.stage,
    required this.messages,
    required this.agentSelections,
    this.finalSelection,
  });
  
  factory NegotiationTopic.empty() {
    return NegotiationTopic(
      id: 'empty',
      domainId: 'empty',
      stage: NegotiationStage.claim,
      messages: [],
      agentSelections: {},
    );
  }
}