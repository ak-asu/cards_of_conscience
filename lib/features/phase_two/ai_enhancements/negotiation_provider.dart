import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../phase_one/models/agent_model.dart';
import '../../phase_one/models/policy_models.dart';
import '../analytics/analytics_service.dart';

enum NegotiationStage {
  initialClaim,
  counterclaim,
  rebuttal,
  conclusion
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

class EnhancedNegotiationProvider with ChangeNotifier {
  List<NegotiationTopic> _topics = [];
  bool _isNegotiating = false;
  String? _currentTopicId;
  bool _isLoading = false;
  String? _error;
  final AnalyticsService _analytics = AnalyticsService();
  final String _storageKey = 'negotiation_state';

  List<NegotiationTopic> get topics => _topics;
  bool get isNegotiating => _isNegotiating;
  String? get currentTopicId => _currentTopicId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NegotiationTopic? get currentTopic {
    if (_currentTopicId == null) return null;
    try {
      return _topics.firstWhere((topic) => topic.id == _currentTopicId);
    } catch (e) {
      return null;
    }
  }

  Future<void> startNegotiation(List<Agent> agents, List<PolicyDomain> domains) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to restore saved state
      final restored = await _restoreState();
      
      if (!restored) {
        _topics = _generateNegotiationTopics(domains);
        _isNegotiating = true;
        _currentTopicId = _topics.isNotEmpty ? _topics[0].id : null;
        
        // Generate initial claims for the first topic
        if (_currentTopicId != null) {
          _generateInitialClaims(agents, _getTopicById(_currentTopicId!), domains);
        }
        
        // Save the initial state
        await _saveState();
      }
      
      _isLoading = false;
      notifyListeners();
      
      // Log analytics
      if (_currentTopicId != null) {
        await _analytics.logNegotiationStage(
          topicId: _currentTopicId!,
          stage: 'negotiation_started',
          messageCount: _getTopicById(_currentTopicId!)?.messages.length ?? 0,
          isUserParticipating: false,
        );
      }
    } catch (e) {
      _error = 'Failed to start negotiation: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveToNextTopic(List<Agent> agents, List<PolicyDomain> domains) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    
    final currentIndex = _topics.indexWhere((topic) => topic.id == _currentTopicId);
    if (currentIndex < 0 || currentIndex >= _topics.length - 1) {
      _isNegotiating = false;
      _currentTopicId = null;
      notifyListeners();
      return;
    }
    
    // Mark current topic as completed
    final updatedTopics = List<NegotiationTopic>.from(_topics);
    updatedTopics[currentIndex] = updatedTopics[currentIndex].copyWith(isCompleted: true);
    
    // Move to next topic
    _currentTopicId = _topics[currentIndex + 1].id;
    _topics = updatedTopics;
    
    // Generate initial claims for the new topic
    _generateInitialClaims(agents, _getTopicById(_currentTopicId!), domains);
    
    // Save state after moving to next topic
    await _saveState();
    
    notifyListeners();
    
    // Log analytics
    final currentTopic = _getTopicById(_currentTopicId!);
    if (currentTopic != null) {
      await _analytics.logNegotiationStage(
        topicId: _currentTopicId!,
        stage: 'topic_changed',
        messageCount: currentTopic.messages.length,
        isUserParticipating: false,
      );
    }
  }

  Future<void> addMessage(NegotiationMessage message) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    
    final topicIndex = _topics.indexWhere((topic) => topic.id == _currentTopicId);
    if (topicIndex < 0) return;
    
    final topic = _topics[topicIndex];
    final updatedMessages = List<NegotiationMessage>.from(topic.messages)..add(message);
    
    final updatedTopic = topic.copyWith(messages: updatedMessages);
    
    final updatedTopics = List<NegotiationTopic>.from(_topics);
    updatedTopics[topicIndex] = updatedTopic;
    
    _topics = updatedTopics;
    
    // Save state after adding a message
    await _saveState();
    
    notifyListeners();
    
    // Log analytics
    if (message.agentId != 'user') {
      await _analytics.logAgentResponse(
        agentId: message.agentId,
        topicId: _currentTopicId!,
        messageType: message.stage.toString().split('.').last,
        characterCount: message.message.length,
      );
    }
  }

  Future<void> updateAgentPosition(String agentId, String policyId) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    
    final topicIndex = _topics.indexWhere((topic) => topic.id == _currentTopicId);
    if (topicIndex < 0) return;
    
    final topic = _topics[topicIndex];
    final updatedPositions = Map<String, String>.from(topic.agentPositions);
    updatedPositions[agentId] = policyId;
    
    final updatedTopic = topic.copyWith(agentPositions: updatedPositions);
    
    final updatedTopics = List<NegotiationTopic>.from(_topics);
    updatedTopics[topicIndex] = updatedTopic;
    
    _topics = updatedTopics;
    
    // Save state after updating positions
    await _saveState();
    
    notifyListeners();
  }

  Future<void> generateCounterclaims(List<Agent> agents, int agentIndex, PolicyDomain domain) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    final agent = agents[agentIndex];
    final topic = _getTopicById(_currentTopicId!);
    if (topic == null) return;
    
    // Skip if counterclaims already exist
    if (topic.messages.any((m) => m.stage == NegotiationStage.counterclaim)) return;
    
    final Random random = Random();
    final List<NegotiationMessage> counterclaims = [];
    
    // Create a map of agent policies for this domain
    final Map<String, PolicyOption> agentPolicies = {};
    for (var agent in agents) {
      if (agent.selections.containsKey(domain.id)) {
        agentPolicies[agent.id] = agent.selections[domain.id]!;
      }
    }
    
    // Find disagreements
    final agentsWithDifferentOpinions = agents.where((a) => 
        a.id != agent.id && 
        agentPolicies.containsKey(a.id) && 
        agentPolicies[a.id]!.id != domain.id).toList();
    
    if (agentsWithDifferentOpinions.isEmpty) return;
    
    // Higher probability of counterclaim if strong disagreement
    double counterclaimProbability = 0.7;
    
    // Adjust based on agent personality
    if (agent.riskTolerance?.toLowerCase().contains('high') ?? false) {
      counterclaimProbability += 0.2;
    } else if (agent.riskTolerance?.toLowerCase().contains('low') ?? false) {
      counterclaimProbability -= 0.2;
    }
    
    // Consider previous discussion context - more likely to counter if they've been mentioned
    final previousMessages = topic.messages.where((m) => m.stage == NegotiationStage.initialClaim);
    final hasBeenMentioned = previousMessages.any((m) => 
        m.message.toLowerCase().contains(agent.name.toLowerCase()) || 
        m.message.toLowerCase().contains(domain.name.toLowerCase()));
    
    if (hasBeenMentioned) {
      counterclaimProbability += 0.1;
    }
    
    // Add all counterclaims with slight delays between them
    if (counterclaims.isNotEmpty) {
      for (var claim in counterclaims) {
        await addMessage(claim);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      await _analytics.logNegotiationStage(
        topicId: _currentTopicId!,
        stage: 'counterclaims_generated',
        messageCount: counterclaims.length,
        isUserParticipating: false,
      );
    }
  }

  Future<void> generateRebuttals(List<Agent> agents, PolicyDomain domain) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    
    final topic = _getTopicById(_currentTopicId!);
    if (topic == null) return;
    
    // Skip if rebuttals already exist or no counterclaims to respond to
    if (topic.messages.any((m) => m.stage == NegotiationStage.rebuttal)) return;
    
    // Find all counterclaims in this topic
    final counterclaims = topic.messages
        .where((msg) => msg.stage == NegotiationStage.counterclaim)
        .toList();
    
    if (counterclaims.isEmpty) return;
    
    final Random random = Random();
    final List<NegotiationMessage> rebuttals = [];
    
    // Track which agents have already responded
    final Set<String> respondedAgents = {};
    
    // Create a map of agent policies for this domain
    final Map<String, PolicyOption> agentPolicies = {};
    for (var agent in agents) {
      if (agent.selections.containsKey(domain.id)) {
        agentPolicies[agent.id] = agent.selections[domain.id]!;
      }
    }
    
    // For each counterclaim, decide who should respond and how
    for (var counterclaim in counterclaims) {
      // Find the agent who made the counterclaim
      final claimantId = counterclaim.agentId;
      final claimantAgent = agents.firstWhere((a) => a.id == claimantId);
      final claimantPolicy = agentPolicies[claimantId];
      
      // Find potential responders who haven't responded yet
      final List<Agent> potentialResponders = agents
          .where((a) => a.id != claimantId && !respondedAgents.contains(a.id))
          .toList();
      
      if (potentialResponders.isEmpty) continue;
      
      // Sort responders by relevance to this conversation
      potentialResponders.sort((a, b) {
        // Priority 1: If they were directly addressed in the counterclaim
        final aAddressed = counterclaim.message.toLowerCase().contains(a.name.toLowerCase());
        final bAddressed = counterclaim.message.toLowerCase().contains(b.name.toLowerCase());
        
        if (aAddressed && !bAddressed) return -1;
        if (!aAddressed && bAddressed) return 1;
        
        // Priority 2: If their policy was addressed
        final aPolicyAddressed = agentPolicies.containsKey(a.id) && 
            counterclaim.message.toLowerCase().contains(agentPolicies[a.id]!.title.toLowerCase());
        final bPolicyAddressed = agentPolicies.containsKey(b.id) && 
            counterclaim.message.toLowerCase().contains(agentPolicies[b.id]!.title.toLowerCase());
        
        if (aPolicyAddressed && !bPolicyAddressed) return -1;
        if (!aPolicyAddressed && bPolicyAddressed) return 1;
        
        // Priority 3: Policy alignment with claimant
        final aAligned = agentPolicies.containsKey(a.id) && claimantPolicy != null &&
            agentPolicies[a.id]!.id == claimantPolicy.id;
        final bAligned = agentPolicies.containsKey(b.id) && claimantPolicy != null &&
            agentPolicies[b.id]!.id == claimantPolicy.id;
        
        if (aAligned && !bAligned) return -1;
        if (!aAligned && bAligned) return 1;
        
        // Fallback to random ordering
        return random.nextBool() ? -1 : 1;
      });
      
      // Calculate rebuttal probability
      for (var i = 0; i < min(2, potentialResponders.length); i++) {
        final responder = potentialResponders[i];
        
        double rebuttalProbability = 0.6;
        
        // Adjust based on agent personality
        if (responder.riskTolerance?.toLowerCase().contains('high') ?? false) {
          rebuttalProbability += 0.2;
        } else if (responder.riskTolerance?.toLowerCase().contains('low') ?? false) {
          rebuttalProbability -= 0.2;
        }
        
        // More likely to respond if directly addressed
        if (counterclaim.message.toLowerCase().contains(responder.name.toLowerCase())) {
          rebuttalProbability += 0.3;
        }
        
        // More likely to respond if their policy was addressed
        if (agentPolicies.containsKey(responder.id) && 
            counterclaim.message.toLowerCase().contains(agentPolicies[responder.id]!.title.toLowerCase())) {
          rebuttalProbability += 0.2;
        }
        
        if (random.nextDouble() < rebuttalProbability) {
          // Determine if supporting or opposing
          bool isSupporting;
          
          // If their policy was directly addressed in a negative way, more likely to oppose
          if (agentPolicies.containsKey(responder.id) && 
              counterclaim.message.toLowerCase().contains(agentPolicies[responder.id]!.title.toLowerCase())) {
            // Assume criticism if mentioned in counterclaim
            isSupporting = false;
          } else if (agentPolicies.containsKey(responder.id) && claimantPolicy != null) {
            // Support if policies align, oppose if they differ
            isSupporting = agentPolicies[responder.id]!.id == claimantPolicy.id;
          } else {
            // Default to 50-50 if can't determine from context
            isSupporting = random.nextBool();
          }
          
          final rebuttal = _generateContextualRebuttal(
            responder, 
            claimantAgent, 
            domain,
            isSupporting,
            topic.messages.map((m) => m.message).toList(),
          );
          
          rebuttals.add(NegotiationMessage(
            agentId: responder.id,
            message: rebuttal,
            stage: NegotiationStage.rebuttal,
            domainId: domain.id,
            policyId: responder.selections[domain.id]?.id,
          ));
          
          respondedAgents.add(responder.id);
        }
      }
    }
    
    // Add all rebuttals with slight delays between them
    if (rebuttals.isNotEmpty) {
      for (var rebuttal in rebuttals) {
        await addMessage(rebuttal);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      await _analytics.logNegotiationStage(
        topicId: _currentTopicId!,
        stage: 'rebuttals_generated',
        messageCount: rebuttals.length,
        isUserParticipating: false,
      );
    }
  }

  Future<void> generateConclusions(List<Agent> agents, PolicyDomain domain) async {
    if (!_isNegotiating || _currentTopicId == null) return;
    
    final topic = _getTopicById(_currentTopicId!);
    if (topic == null) return;
    
    // Skip if conclusions already exist
    if (topic.messages.any((m) => m.stage == NegotiationStage.conclusion)) return;
    
    final Random random = Random();
    
    // Analyze the discussion context
    final allMessages = topic.messages.map((m) => m.message).join(' ');
    final Map<String, int> policyMentions = {};
    
    // Count policy mentions in the discussion
    for (var agent in agents) {
      if (agent.selections.containsKey(domain.id)) {
        final policy = agent.selections[domain.id]!;
        final regex = RegExp(policy.title, caseSensitive: false);
        final matches = regex.allMatches(allMessages);
        policyMentions[policy.id] = matches.length;
      }
    }
    
    // Identify most discussed policies
    final sortedPolicies = policyMentions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Choose agents for conclusions - prioritize those with strong opinions or who have been active
    final activeAgentIds = topic.messages
        .map((m) => m.agentId)
        .toSet()
        .where((id) => id != 'user')
        .toList();
    
    final prioritizedAgents = List<Agent>.from(agents)
      ..sort((a, b) {
        // Priority 1: Agents who have been active in the discussion
        final aActive = activeAgentIds.contains(a.id);
        final bActive = activeAgentIds.contains(b.id);
        
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;
        
        // Priority 2: Agents with high risk tolerance (more opinionated)
        final aHighRisk = a.riskTolerance?.toLowerCase().contains('high') ?? false;
        final bHighRisk = b.riskTolerance?.toLowerCase().contains('high') ?? false;
        
        if (aHighRisk && !bHighRisk) return -1;
        if (!aHighRisk && bHighRisk) return 1;
        
        // Priority 3: Agents whose policies were frequently discussed
        final aPolicyId = a.selections[domain.id]?.id;
        final bPolicyId = b.selections[domain.id]?.id;
        
        final aMentions = aPolicyId != null && policyMentions.containsKey(aPolicyId) 
            ? policyMentions[aPolicyId]! : 0;
        final bMentions = bPolicyId != null && policyMentions.containsKey(bPolicyId) 
            ? policyMentions[bPolicyId]! : 0;
        
        return bMentions.compareTo(aMentions);
      });
    
    // Determine how many agents should provide conclusions (1-3 based on discussion activity)
    final messageCount = topic.messages.length;
    int concluderCount;
    
    if (messageCount <= 4) {
      concluderCount = 1;
    } else if (messageCount <= 8) {
      concluderCount = 2;
    } else {
      concluderCount = 3;
    }
    
    concluderCount = min(concluderCount, prioritizedAgents.length);
    final concluders = prioritizedAgents.take(concluderCount).toList();
    
    // Generate and add conclusions
    final List<NegotiationMessage> conclusions = [];
    
    for (var agent in concluders) {
      final conclusion = _generateContextualConclusion(
        agent, 
        domain, 
        topic.messages,
        sortedPolicies.isNotEmpty ? sortedPolicies.first.key : null,
      );
      
      conclusions.add(NegotiationMessage(
        agentId: agent.id,
        message: conclusion,
        stage: NegotiationStage.conclusion,
        domainId: domain.id,
        policyId: agent.selections[domain.id]?.id,
      ));
    }
    
    // Add all conclusions with slight delays between them
    if (conclusions.isNotEmpty) {
      for (var conclusion in conclusions) {
        await addMessage(conclusion);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Check for consensus
      final consensusReached = _checkForConsensus(topic);
      
      // Log analytics
      await _analytics.logNegotiationStage(
        topicId: _currentTopicId!,
        stage: 'conclusions_generated',
        messageCount: conclusions.length,
        isUserParticipating: false,
      );
      
      if (consensusReached != null) {
        await _analytics.logPolicyDiscussed(
          domainId: domain.id,
          policyId: consensusReached,
          participantCount: activeAgentIds.length + (topic.messages.any((m) => m.agentId == 'user') ? 1 : 0),
          reachedConsensus: true,
        );
      } else if (topic.agentPositions.values.toSet().isNotEmpty) {
        // If no consensus but policies were discussed
        await _analytics.logPolicyDiscussed(
          domainId: domain.id,
          policyId: topic.agentPositions.values.first,
          participantCount: activeAgentIds.length + (topic.messages.any((m) => m.agentId == 'user') ? 1 : 0),
          reachedConsensus: false,
        );
      }
    }
  }

  // Private helper methods
  List<NegotiationTopic> _generateNegotiationTopics(List<PolicyDomain> domains) {
    final List<NegotiationTopic> topics = [];
    
    // Create a topic for each policy domain
    for (var domain in domains) {
      topics.add(
        NegotiationTopic(
          id: 'topic_${domain.id}',
          domainId: domain.id,
        ),
      );
    }
    
    return topics;
  }

  void _generateInitialClaims(List<Agent> agents, NegotiationTopic? topic, List<PolicyDomain> domains) {
    if (topic == null) return;
    
    final Random random = Random();
    
    // Get the policy domain for this topic
    final domain = _getDomainById(topic.domainId, domains);
    if (domain == null) return;
    
    // Ensure all agents say something if we have few agents, otherwise pick a random subset
    final isSmallerGroup = agents.length <= 4;
    final speakerCount = isSmallerGroup ? agents.length : 2 + random.nextInt(2);
    final speakers = List<Agent>.from(agents)..shuffle(random);
    speakers.length = min(speakerCount, speakers.length);
    
    for (var agent in speakers) {
      // Skip if no selection for this domain
      if (!agent.selections.containsKey(domain.id)) continue;
      
      final selectedPolicy = agent.selections[domain.id]!;
      final initialClaim = _generateInitialClaim(agent, domain, selectedPolicy);
      
      addMessage(NegotiationMessage(
        agentId: agent.id,
        message: initialClaim,
        stage: NegotiationStage.initialClaim,
        domainId: domain.id,
        policyId: selectedPolicy.id,
      ));
      
      // Update agent position in this topic
      updateAgentPosition(agent.id, selectedPolicy.id);
    }
  }

  String _generateInitialClaim(Agent agent, PolicyDomain domain, PolicyOption option) {
    final List<String> claimPrefixes = [
      'I believe that',
      'In my professional opinion,',
      'From my perspective,',
      'Based on my experience,',
      "I'd like to advocate for",
    ];
    
    final List<String> claimSuffixes = [
      'is the most appropriate approach.',
      'offers the optimal balance of cost and benefit.',
      'is what we should focus on.',
      'represents the best path forward.',
      'is what I want to put forward for consideration.',
    ];
    
    final Random random = Random();
    
    String claim = '${claimPrefixes[random.nextInt(claimPrefixes.length)]} ${option.title} ${claimSuffixes[random.nextInt(claimSuffixes.length)]} ';
    
    // Add justification if available
    if (agent.justifications.containsKey(domain.id)) {
      claim += '${agent.justifications[domain.id]}';
    } else {
      claim += 'It will cost ${option.cost} budget units but provides significant value.';
    }
    
    return claim;
  }

  String _generateCounterclaim(Agent agent, PolicyDomain domain, PolicyOption agentPolicy, 
                              Agent targetAgent, PolicyOption targetPolicy, List<String> previousMessages) {
    final List<String> counterPrefixes = [
      'I must respectfully disagree with ${targetAgent.name}.',
      'I see things differently than ${targetAgent.name}.',
      "I'd like to offer an alternative to ${targetAgent.name}'s approach.",
      "With due respect to ${targetAgent.name}, I believe there's a better option.",
      "I understand ${targetAgent.name}'s position, but I have concerns.",
    ];
    
    final List<String> counterPoints = [
      '${targetPolicy.title} may cost ${targetPolicy.cost} units, but ${agentPolicy.title} is more effective for only ${agentPolicy.cost} units.',
      '${targetPolicy.title} has significant drawbacks that ${agentPolicy.title} addresses.',
      'While ${targetPolicy.title} sounds promising, ${agentPolicy.title} offers more tangible benefits.',
      '${targetPolicy.title} is too ${_getCostDescription(targetPolicy.cost)}, whereas ${agentPolicy.title} is more ${_getCostDescription(agentPolicy.cost)} and practical.',
      "The approach in ${targetPolicy.title} won't work as effectively as ${agentPolicy.title} in addressing the core issues.",
    ];
    
    final Random random = Random();
    
    String counterclaim = '${counterPrefixes[random.nextInt(counterPrefixes.length)]} ';
    
    // Reference specific aspects from previous discussion
    if (previousMessages.isNotEmpty) {
      final keyword = previousMessages[random.nextInt(previousMessages.length)];
      counterclaim += "Earlier we discussed $keyword, and I think this relates to why ${targetPolicy.title} isn't the optimal choice. ";
    }
    
    counterclaim += '${counterPoints[random.nextInt(counterPoints.length)]} ';
    
    // Add agent-specific reasoning based on ideology or perspective
    if (agent.perspective != null) {
      counterclaim += _getAgentPerspectiveStatement(agent);
    } else if (agent.ideology.isNotEmpty) {
      counterclaim += _getAgentIdeologyStatement(agent);
    }
    
    return counterclaim;
  }

  String _generateRebuttal(Agent agent, Agent targetAgent, PolicyDomain domain, bool isSupporting) {
    final Random random = Random();
    
    if (isSupporting) {
      final List<String> supportPrefixes = [
        "I'd like to build on what ${targetAgent.name} said.",
        "I agree with ${targetAgent.name}'s assessment.",
        "${targetAgent.name} makes an excellent point that I'd like to support.",
        "To reinforce ${targetAgent.name}'s argument,",
        'I find myself in agreement with ${targetAgent.name} here.',
      ];
      
      final List<String> supportPoints = [
        'The evidence clearly supports this approach.',
        'This aligns with best practices in similar contexts.',
        'The benefits outweigh the costs significantly.',
        'This offers the most sustainable path forward.',
        'This balanced approach addresses multiple stakeholder concerns.',
      ];
      
      return '${supportPrefixes[random.nextInt(supportPrefixes.length)]} ${supportPoints[random.nextInt(supportPoints.length)]} ${_getAgentValueStatement(agent)}';
    } else {
      final List<String> objectPrefixes = [
        "I see some problems with ${targetAgent.name}'s reasoning.",
        "I must point out some flaws in ${targetAgent.name}'s argument.",
        "I'd like to challenge ${targetAgent.name}'s position.",
        'With respect, I believe ${targetAgent.name} is overlooking key factors.',
        "I have to question the assumptions behind ${targetAgent.name}'s approach.",
      ];
      
      final List<String> objectPoints = [
        'We need to consider the long-term implications more carefully.',
        "This approach doesn't adequately address the core problems.",
        "The cost-benefit analysis doesn't support this conclusion.",
        "There are unintended consequences we shouldn't ignore.",
        'Alternative approaches offer better outcomes for similar investment.',
      ];
      
      return '${objectPrefixes[random.nextInt(objectPrefixes.length)]} ${objectPoints[random.nextInt(objectPoints.length)]} ${_getAgentValueStatement(agent)}';
    }
  }

  String _generateConclusion(Agent agent, PolicyDomain domain) {
    final List<String> conclusionPrefixes = [
      'To conclude this discussion,',
      'As we wrap up our conversation on this topic,',
      'Before we move on,',
      'To summarize my position,',
      "After hearing everyone's perspective,",
    ];
    
    final List<String> conclusionPoints = [
      'I maintain that my approach offers the best balance of cost and effectiveness.',
      'I believe we should prioritize solutions that address the root causes.',
      'I want to emphasize the importance of considering all stakeholders.',
      'I think we should focus on evidence-based approaches with proven track records.',
      'I suggest we consider both short-term needs and long-term sustainability.',
    ];
    
    final Random random = Random();
    
    return '${conclusionPrefixes[random.nextInt(conclusionPrefixes.length)]} ${conclusionPoints[random.nextInt(conclusionPoints.length)]} ${_getAgentFinalStatement(agent)}';
  }

  String _getCostDescription(int cost) {
    switch (cost) {
      case 1:
        return 'modest';
      case 2:
        return 'balanced';
      case 3:
        return 'expensive';
      default:
        return 'costly';
    }
  }

  String _getAgentPerspectiveStatement(Agent agent) {
    final Random random = Random();
    
    switch (agent.id) {
      case 'diplomat1': // Progressive Humanitarian
        final statements = [
          'We must prioritize equity and justice in our decision-making.',
          'The human impact of our policies should be our primary concern.',
          'We need solutions that address systemic inequalities.',
          'Our moral obligation is to support the most vulnerable among us.',
          'True progress requires bold action and substantive change.',
        ];
        return statements[random.nextInt(statements.length)];
        
      case 'diplomat2': // Pragmatic Realist
        final statements = [
          'The data clearly supports a measured approach with proven outcomes.',
          'We need to balance idealism with practical constraints.',
          'Effective policy must be both impactful and implementable.',
          'Our resources are limited, so efficiency must be a priority.',
          "Let's focus on solutions with demonstrated effectiveness.",
        ];
        return statements[random.nextInt(statements.length)];
        
      case 'diplomat3': // Neoliberal Innovator
        final statements = [
          'Technological innovation offers us unprecedented opportunities to solve these challenges.',
          'Data-driven solutions consistently outperform traditional approaches.',
          'We should embrace disruption where it creates measurable improvements.',
          'Scaling effective solutions requires leveraging modern technologies.',
          'The metrics clearly show the potential for transformation through innovative methods.',
        ];
        return statements[random.nextInt(statements.length)];
        
      case 'diplomat4': // Community-Centered Traditionalist
        final statements = [
          'We must respect established community values and practices.',
          'Solutions should build on local knowledge and existing social structures.',
          'Cultural sensitivity is essential to effective policy implementation.',
          'Community stakeholders must be central to our decision-making process.',
          'Gradual, thoughtful change preserves social cohesion while addressing needs.',
        ];
        return statements[random.nextInt(statements.length)];
        
      default:
        return '';
    }
  }

  String _getAgentIdeologyStatement(Agent agent) {
    final Random random = Random();
    
    if (agent.ideology.contains('conservative')) {
      final statements = [
        'We should prioritize individual responsibility and fiscal restraint.',
        'Traditional approaches have proven effective and should be respected.',
        'The private sector often delivers more efficient solutions than government.',
        'We need to be careful about overextending government authority.',
        'Gradual, measured change is preferable to radical restructuring.',
      ];
      return statements[random.nextInt(statements.length)];
    } else if (agent.ideology.contains('progressive')) {
      final statements = [
        'Bold action is needed to address persistent inequalities.',
        'Government has a responsibility to ensure equitable outcomes.',
        'Investment in public goods benefits everyone in society.',
        'Systemic problems require systemic solutions.',
        'We should prioritize the needs of marginalized communities.',
      ];
      return statements[random.nextInt(statements.length)];
    } else if (agent.ideology.contains('libertarian')) {
      final statements = [
        'Individual freedom should be our guiding principle.',
        'Market solutions typically outperform government intervention.',
        'We should minimize restrictions on personal choice.',
        'Innovation thrives with minimal regulatory burden.',
        'Voluntary cooperation is preferable to mandated approaches.',
      ];
      return statements[random.nextInt(statements.length)];
    } else {
      final statements = [
        'We need practical solutions that work regardless of ideology.',
        'Evidence should guide our decisions more than political theory.',
        'Balance is key to effective policy that serves all citizens.',
        "Let's focus on outcomes rather than ideological purity.",
        'Compromise allows us to move forward with broad support.',
      ];
      return statements[random.nextInt(statements.length)];
    }
  }

  String _getAgentValueStatement(Agent agent) {
    final Random random = Random();
    
    if (agent.perspective != null) {
      return _getAgentPerspectiveStatement(agent);
    }
    
    final statements = [
      'This reflects my commitment to finding effective solutions.',
      'I believe this approach best serves our shared goals.',
      'My experience suggests this will yield the best outcomes.',
      'This position is consistent with the values I represent.',
      "I'm advocating for what I believe will truly work.",
    ];
    
    return statements[random.nextInt(statements.length)];
  }

  String _getAgentFinalStatement(Agent agent) {
    final Random random = Random();
    
    final statements = [
      'Thank you for considering my perspective.',
      "I appreciate everyone's input on this complex issue.",
      'I hope we can find common ground as we move forward.',
      'I remain open to evolving my position as we continue our discussion.',
      "Let's keep these important considerations in mind as we proceed.",
    ];
    
    return statements[random.nextInt(statements.length)];
  }

  NegotiationTopic? _getTopicById(String topicId) {
    try {
      return _topics.firstWhere((topic) => topic.id == topicId);
    } catch (e) {
      return null;
    }
  }

  PolicyDomain? _getDomainById(String domainId, List<PolicyDomain> domains) {
    try {
      return domains.firstWhere((domain) => domain.id == domainId);
    } catch (e) {
      return null;
    }
  }

  // Persistence methods
  Future<bool> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'topics': _topics.map((t) => t.toMap()).toList(),
        'isNegotiating': _isNegotiating,
        'currentTopicId': _currentTopicId,
      };
      
      await prefs.setString(_storageKey, jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('Failed to save negotiation state: $e');
      return false;
    }
  }

  Future<bool> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getString(_storageKey);
      
      if (savedState == null || savedState.isEmpty) {
        return false;
      }
      
      final data = jsonDecode(savedState) as Map<String, dynamic>;
      
      _topics = (data['topics'] as List)
          .map((t) => NegotiationTopic.fromMap(t as Map<String, dynamic>))
          .toList();
      
      _isNegotiating = data['isNegotiating'] as bool;
      _currentTopicId = data['currentTopicId'] as String?;
      
      return true;
    } catch (e) {
      debugPrint('Failed to restore negotiation state: $e');
      return false;
    }
  }

  Future<void> clearSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Failed to clear saved state: $e');
    }
  }

  // Helper methods
  String? _checkForConsensus(NegotiationTopic topic) {
    final positions = topic.agentPositions.values.toList();
    if (positions.isEmpty) return null;
    
    // Count occurrences of each policy
    final Map<String, int> policyCounts = {};
    for (var policyId in positions) {
      policyCounts[policyId] = (policyCounts[policyId] ?? 0) + 1;
    }
    
    // Find the most common policy
    String? mostCommonPolicy;
    int maxCount = 0;
    
    policyCounts.forEach((policy, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonPolicy = policy;
      }
    });
    
    // Check if it has majority support
    if (mostCommonPolicy != null && maxCount > positions.length / 2) {
      return mostCommonPolicy;
    }
    
    return null;
  }

  String _generateContextualRebuttal(Agent agent, Agent targetAgent, PolicyDomain domain, 
                                   bool isSupporting, List<String> previousMessages) {
    final Random random = Random();
    
    // Add context-awareness - analyze previous messages to make more relevant rebuttals
    final relevantKeywords = _extractRelevantKeywords(previousMessages);
    
    if (isSupporting) {
      final List<String> supportPrefixes = [
        "I'd like to build on what ${targetAgent.name} said.",
        "I agree with ${targetAgent.name}'s assessment.",
        "${targetAgent.name} makes an excellent point that I'd like to support.",
        "To reinforce ${targetAgent.name}'s argument,",
        'I find myself in agreement with ${targetAgent.name} here.',
      ];
      
      final List<String> supportPoints = [
        'The evidence clearly supports this approach.',
        'This aligns with best practices in similar contexts.',
        'The benefits outweigh the costs significantly.',
        'This offers the most sustainable path forward.',
        'This balanced approach addresses multiple stakeholder concerns.',
      ];
      
      // Incorporate relevant keywords from the discussion
      if (relevantKeywords.isNotEmpty) {
        final keyword = relevantKeywords[random.nextInt(relevantKeywords.length)];
        return '${supportPrefixes[random.nextInt(supportPrefixes.length)]} The point about $keyword is particularly important. ${supportPoints[random.nextInt(supportPoints.length)]} ${_getAgentValueStatement(agent)}';
      }
      
      return '${supportPrefixes[random.nextInt(supportPrefixes.length)]} ${supportPoints[random.nextInt(supportPoints.length)]} ${_getAgentValueStatement(agent)}';
    } else {
      final List<String> objectPrefixes = [
        "I see some problems with ${targetAgent.name}'s reasoning.",
        "I must point out some flaws in ${targetAgent.name}'s argument.",
        "I'd like to challenge ${targetAgent.name}'s position.",
        'With respect, I believe ${targetAgent.name} is overlooking key factors.',
        "I have to question the assumptions behind ${targetAgent.name}'s approach.",
      ];
      
      final List<String> objectPoints = [
        'We need to consider the long-term implications more carefully.',
        "This approach doesn't adequately address the core problems.",
        "The cost-benefit analysis doesn't support this conclusion.",
        "There are unintended consequences we shouldn't ignore.",
        'Alternative approaches offer better outcomes for similar investment.',
      ];
      
      // Incorporate relevant keywords from the discussion
      if (relevantKeywords.isNotEmpty) {
        final keyword = relevantKeywords[random.nextInt(relevantKeywords.length)];
        return '${objectPrefixes[random.nextInt(objectPrefixes.length)]} The discussion around $keyword needs more nuance. ${objectPoints[random.nextInt(objectPoints.length)]} ${_getAgentValueStatement(agent)}';
      }
      
      return '${objectPrefixes[random.nextInt(objectPrefixes.length)]} ${objectPoints[random.nextInt(objectPoints.length)]} ${_getAgentValueStatement(agent)}';
    }
  }

  String _generateContextualConclusion(Agent agent, PolicyDomain domain, 
                                     List<NegotiationMessage> messages, String? mostDiscussedPolicyId) {
    final Random random = Random();
    final List<String> conclusionPrefixes = [
      'To conclude this discussion,',
      'As we wrap up our conversation on this topic,',
      'Before we move on,',
      'To summarize my position,',
      "After hearing everyone's perspective,",
    ];
    
    final List<String> conclusionPoints = [
      'I maintain that my approach offers the best balance of cost and effectiveness.',
      'I believe we should prioritize solutions that address the root causes.',
      'I want to emphasize the importance of considering all stakeholders.',
      'I think we should focus on evidence-based approaches with proven track records.',
      'I suggest we consider both short-term needs and long-term sustainability.',
    ];
    
    // Add context-awareness based on the discussion
    final allParticipants = messages.map((m) => m.agentId).toSet();
    final hasUserParticipated = allParticipants.contains('user');
    final agentPolicy = agent.selections[domain.id];
    
    String contextualConclusion;
    
    if (mostDiscussedPolicyId != null && agentPolicy != null && mostDiscussedPolicyId == agentPolicy.id) {
      // Agent's preferred policy was most discussed - they're more confident
      contextualConclusion = "${conclusionPrefixes[random.nextInt(conclusionPrefixes.length)]} I'm pleased to see that my approach of ${agentPolicy.title} gained significant attention. ${conclusionPoints[random.nextInt(conclusionPoints.length)]} ${_getAgentFinalStatement(agent)}";
    } else if (hasUserParticipated) {
      // Acknowledge user participation
      contextualConclusion = '${conclusionPrefixes[random.nextInt(conclusionPrefixes.length)]} Thank you for your input in this discussion. ${conclusionPoints[random.nextInt(conclusionPoints.length)]} ${_getAgentFinalStatement(agent)}';
    } else {
      // Standard conclusion
      contextualConclusion = '${conclusionPrefixes[random.nextInt(conclusionPrefixes.length)]} ${conclusionPoints[random.nextInt(conclusionPoints.length)]} ${_getAgentFinalStatement(agent)}';
    }
    
    return contextualConclusion;
  }

  List<String> _extractRelevantKeywords(List<String> messages) {
    final allText = messages.join(' ');
    
    // List of common policy-related keywords
    final List<String> keywordsList = [
      'budget', 'cost', 'economy', 'education', 'healthcare', 'environment',
      'sustainability', 'infrastructure', 'security', 'welfare', 'technology',
      'innovation', 'regulation', 'deregulation', 'taxation', 'subsidies',
      'funding', 'investment', 'public', 'private', 'partnership', 'reform',
      'equity', 'equality', 'justice', 'efficiency', 'effectiveness', 'outcomes',
      'impact', 'community', 'society', 'individual', 'rights', 'responsibility',
      'future', 'present', 'past', 'tradition', 'progress', 'conservative', 
      'progressive', 'moderate', 'radical', 'incremental', 'transformative'
    ];
    
    // Find which keywords appear in the messages
    final relevantKeywords = keywordsList
        .where((keyword) => allText.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
    
    return relevantKeywords.isEmpty ? [] : relevantKeywords;
  }
}