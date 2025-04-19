import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_model.dart';
import 'analytics_service.dart';

class EmotionState {
  final double happiness;
  final double anger;
  final double fear;
  final double surprise;
  final double disgust;
  final double sadness;
  final double trust;
  final double anticipation;

  EmotionState({
    this.happiness = 0.5,
    this.anger = 0.0,
    this.fear = 0.0,
    this.surprise = 0.0,
    this.disgust = 0.0,
    this.sadness = 0.0,
    this.trust = 0.5,
    this.anticipation = 0.3,
  });

  Map<String, dynamic> toJson() => {
    'happiness': happiness,
    'anger': anger,
    'fear': fear,
    'surprise': surprise,
    'disgust': disgust,
    'sadness': sadness,
    'trust': trust,
    'anticipation': anticipation,
  };

  factory EmotionState.fromJson(Map<String, dynamic> json) => EmotionState(
    happiness: json['happiness'] ?? 0.5,
    anger: json['anger'] ?? 0.0,
    fear: json['fear'] ?? 0.0,
    surprise: json['surprise'] ?? 0.0,
    disgust: json['disgust'] ?? 0.0,
    sadness: json['sadness'] ?? 0.0,
    trust: json['trust'] ?? 0.5,
    anticipation: json['anticipation'] ?? 0.3,
  );

  EmotionState copyWith({
    double? happiness,
    double? anger,
    double? fear,
    double? surprise,
    double? disgust,
    double? sadness,
    double? trust,
    double? anticipation,
  }) => EmotionState(
    happiness: happiness ?? this.happiness,
    anger: anger ?? this.anger,
    fear: fear ?? this.fear,
    surprise: surprise ?? this.surprise,
    disgust: disgust ?? this.disgust,
    sadness: sadness ?? this.sadness,
    trust: trust ?? this.trust,
    anticipation: anticipation ?? this.anticipation,
  );

  String getDominantEmotion() {
    final emotions = {
      'happiness': happiness,
      'anger': anger,
      'fear': fear,
      'surprise': surprise,
      'disgust': disgust,
      'sadness': sadness,
      'trust': trust,
      'anticipation': anticipation,
    };

    String dominant = 'neutral';
    double maxIntensity = 0.3; // Threshold for neutral

    emotions.forEach((emotion, intensity) {
      if (intensity > maxIntensity) {
        dominant = emotion;
        maxIntensity = intensity;
      }
    });

    return dominant;
  }

  double getEmotionalIntensity() {
    final values = [happiness, anger, fear, surprise, disgust, sadness, trust, anticipation];
    double sum = 0;

    for (final value in values) {
      sum += value;
    }

    return sum / values.length;
  }
}

enum EmotionEvent {
  agreement,
  disagreement,
  praise,
  criticism,
  surprise,
}

class EmotionModelService with ChangeNotifier {
  final Map<String, EmotionState> _agentEmotions = {};
  final String _storageKey = 'agent_emotions';
  final AnalyticsService _analytics = AnalyticsService();
  final Random _random = Random();
  bool _isInitialized = false;

  EmotionModelService() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    
    await _loadEmotionStates();
    _isInitialized = true;
  }

  Future<void> _loadEmotionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmotions = prefs.getString(_storageKey);
      
      if (savedEmotions != null) {
        final Map<String, dynamic> data = jsonDecode(savedEmotions);
        data.forEach((agentId, emotionData) {
          _agentEmotions[agentId] = EmotionState.fromJson(emotionData);
        });
      }
    } catch (e) {
      debugPrint('Failed to load emotion states: $e');
    }
  }

  Future<void> _saveEmotionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      
      _agentEmotions.forEach((agentId, state) {
        data[agentId] = state.toJson();
      });
      
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save emotion states: $e');
    }
  }

  // Initialize emotion states for all agents
  Future<void> initializeAgentEmotions(List<Agent> agents) async {
    await _init();
    
    for (final agent in agents) {
      if (!_agentEmotions.containsKey(agent.id)) {
        _agentEmotions[agent.id] = _createInitialEmotionState(agent);
      }
    }
    
    await _saveEmotionStates();
    notifyListeners();
  }

  // Get emotion state for a specific agent
  EmotionState getAgentEmotionState(String agentId) {
    return _agentEmotions[agentId] ?? EmotionState();
  }

  // Update emotion state based on events
  Future<void> updateEmotionForEvent({
    required String agentId,
    required String eventType,
    String? targetAgentId,
    String? messageContent,
    String? policyId,
  }) async {
    await _init();
    
    if (!_agentEmotions.containsKey(agentId)) {
      _agentEmotions[agentId] = EmotionState();
    }
    
    final currentState = _agentEmotions[agentId]!;
    EmotionState newState;
    
    switch (eventType) {
      case 'agreement':
        newState = _handleAgreementEvent(currentState);
        await _logEmotionChange(agentId, 'happiness', newState.happiness - currentState.happiness, 'agreement');
        break;
        
      case 'disagreement':
        newState = _handleDisagreementEvent(currentState);
        await _logEmotionChange(agentId, 'anger', newState.anger - currentState.anger, 'disagreement');
        break;
        
      case 'user_message':
        newState = _handleUserMessageEvent(currentState, messageContent);
        final dominantChange = newState.getDominantEmotion();
        await _logEmotionChange(agentId, dominantChange, 0.2, 'user_message');
        break;
        
      case 'policy_selection':
        newState = _handlePolicySelectionEvent(currentState, policyId, agentId);
        await _logEmotionChange(agentId, 'anticipation', newState.anticipation - currentState.anticipation, 'policy_selection');
        break;
        
      case 'surprise_information':
        newState = _handleSurpriseInformationEvent(currentState);
        await _logEmotionChange(agentId, 'surprise', newState.surprise - currentState.surprise, 'surprise_information');
        break;
        
      case 'agent_attacked':
        newState = _handleAgentAttackedEvent(currentState, targetAgentId);
        await _logEmotionChange(agentId, 'fear', newState.fear - currentState.fear, 'agent_attacked');
        break;
        
      default:
        newState = currentState;
        break;
    }
    
    _agentEmotions[agentId] = newState;
    await _saveEmotionStates();
    notifyListeners();
  }

  void handleAgentEvent(String agentId, EmotionEvent event) {
    final currentState = getAgentEmotionState(agentId);
    EmotionState updatedState;
    
    switch (event) {
      case EmotionEvent.agreement:
        updatedState = _handleAgreementEvent(currentState);
        break;
      case EmotionEvent.disagreement:
        updatedState = _handleDisagreementEvent(currentState);
        break;
      case EmotionEvent.praise:
        updatedState = _handlePraiseEvent(currentState);
        break;
      case EmotionEvent.criticism:
        updatedState = _handleCriticismEvent(currentState);
        break;
      case EmotionEvent.surprise:
        updatedState = _handleSurpriseEvent(currentState);
        break;
      default:
        updatedState = currentState;
    }
    
    _agentEmotions[agentId] = updatedState;
    notifyListeners();
  }

  // Create context-aware response based on emotional state
  String generateEmotionalResponse(String agentId, String baseResponse, String context) {
    if (!_agentEmotions.containsKey(agentId)) {
      return baseResponse;
    }
    
    final emotionState = _agentEmotions[agentId]!;
    final dominantEmotion = emotionState.getDominantEmotion();
    final intensity = emotionState.getEmotionalIntensity();
    
    // Skip emotional modification if intensity is low
    if (intensity < 0.4) {
      return baseResponse;
    }
    
    // Add emotion-specific language
    final emotionalPrefix = _getEmotionalPrefix(dominantEmotion, intensity);
    final emotionalSuffix = _getEmotionalSuffix(dominantEmotion, intensity);
    
    // Determine if we should add prefix, suffix, or both
    final prefixProbability = 0.7;
    final suffixProbability = 0.5;
    
    final bool addPrefix = _random.nextDouble() < prefixProbability;
    bool addSuffix = _random.nextDouble() < suffixProbability;
    
    // Don't add both for low intensity emotions
    if (intensity < 0.6 && addPrefix && addSuffix) {
      addSuffix = false;
    }
    
    String modifiedResponse = baseResponse;
    
    if (addPrefix && emotionalPrefix.isNotEmpty) {
      modifiedResponse = '$emotionalPrefix $modifiedResponse';
    }
    
    if (addSuffix && emotionalSuffix.isNotEmpty) {
      modifiedResponse = '$modifiedResponse $emotionalSuffix';
    }
    
    return modifiedResponse;
  }

  // Helper methods for emotion event handling
  EmotionState _handleAgreementEvent(EmotionState currentState) {
    return currentState.copyWith(
      happiness: min(1.0, currentState.happiness + 0.2),
      trust: min(1.0, currentState.trust + 0.15),
      anger: max(0.0, currentState.anger - 0.1),
    );
  }

  EmotionState _handleDisagreementEvent(EmotionState currentState) {
    return currentState.copyWith(
      anger: min(1.0, currentState.anger + 0.2),
      happiness: max(0.0, currentState.happiness - 0.1),
      trust: max(0.0, currentState.trust - 0.15),
    );
  }

  EmotionState _handlePraiseEvent(EmotionState currentState) {
    return currentState.copyWith(
      happiness: min(1.0, currentState.happiness + 0.25),
      trust: min(1.0, currentState.trust + 0.2),
      sadness: max(0.0, currentState.sadness - 0.15),
    );
  }

  EmotionState _handleCriticismEvent(EmotionState currentState) {
    return currentState.copyWith(
      sadness: min(1.0, currentState.sadness + 0.2),
      anger: min(1.0, currentState.anger + 0.1),
      happiness: max(0.0, currentState.happiness - 0.15),
    );
  }

  EmotionState _handleUserMessageEvent(EmotionState currentState, String? messageContent) {
    if (messageContent == null || messageContent.isEmpty) {
      return currentState;
    }
    
    // Simple sentiment analysis (in reality, would use NLP)
    final lowerMessage = messageContent.toLowerCase();
    
    // Check for positive sentiment
    final positiveWords = [
      'good', 'great', 'excellent', 'agree', 'thanks', 'appreciate',
      'helpful', 'interesting', 'important', 'valuable', 'insightful'
    ];
    
    // Check for negative sentiment
    final negativeWords = [
      'bad', 'wrong', 'disagree', 'not', 'terrible', 'poor',
      'problem', 'issue', 'concerned', 'worried', 'failure'
    ];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowerMessage.contains(word)) {
        positiveCount++;
      }
    }
    
    for (final word in negativeWords) {
      if (lowerMessage.contains(word)) {
        negativeCount++;
      }
    }
    
    final sentimentScore = (positiveCount - negativeCount) * 0.1;
    
    return currentState.copyWith(
      happiness: min(1.0, max(0.0, currentState.happiness + sentimentScore)),
      sadness: min(1.0, max(0.0, currentState.sadness - sentimentScore)),
      surprise: min(1.0, currentState.surprise + 0.1),
    );
  }

  EmotionState _handlePolicySelectionEvent(EmotionState currentState, String? policyId, String agentId) {
    if (policyId == null) {
      return currentState;
    }
    
    // In a real implementation, check if this policy matches the agent's preference
    final double alignmentFactor = _random.nextDouble() > 0.5 ? 0.2 : -0.2;
    
    return currentState.copyWith(
      happiness: min(1.0, max(0.0, currentState.happiness + alignmentFactor)),
      anger: min(1.0, max(0.0, currentState.anger - alignmentFactor)),
      anticipation: min(1.0, currentState.anticipation + 0.15),
    );
  }

  EmotionState _handleSurpriseInformationEvent(EmotionState currentState) {
    return currentState.copyWith(
      surprise: min(1.0, currentState.surprise + 0.3),
      anticipation: min(1.0, currentState.anticipation + 0.2),
    );
  }

  EmotionState _handleSurpriseEvent(EmotionState currentState) {
    return currentState.copyWith(
      surprise: min(1.0, currentState.surprise + 0.3),
      anticipation: min(1.0, currentState.anticipation + 0.1),
    );
  }

  EmotionState _handleAgentAttackedEvent(EmotionState currentState, String? targetAgentId) {
    return currentState.copyWith(
      fear: min(1.0, currentState.fear + 0.2),
      trust: max(0.0, currentState.trust - 0.15),
      disgust: min(1.0, currentState.disgust + 0.1),
    );
  }

  EmotionState _createInitialEmotionState(Agent agent) {
    // Create personality-driven initial emotional state
    double baseHappiness = 0.5;
    double baseTrust = 0.5;
    double baseAnticipation = 0.3;
    
    // Adjust based on ideology
    if (agent.ideology.contains('progressive')) {
      baseHappiness += 0.1;
      baseAnticipation += 0.1;
    } else if (agent.ideology.contains('conservative')) {
      baseTrust += 0.1;
      baseAnticipation -= 0.05;
    } else if (agent.ideology.contains('technocratic')) {
      baseHappiness += 0.05;
      baseAnticipation += 0.15;
    }
    
    // Adjust based on risk tolerance
    if (agent.riskTolerance?.toLowerCase().contains('high') ?? false) {
      baseAnticipation += 0.1;
      baseTrust -= 0.05;
    } else if (agent.riskTolerance?.toLowerCase().contains('low') ?? false) {
      baseTrust += 0.1;
      baseAnticipation -= 0.05;
    }
    
    // Add some randomness
    final randomFactor = 0.1;
    baseHappiness += (_random.nextDouble() * randomFactor * 2) - randomFactor;
    baseTrust += (_random.nextDouble() * randomFactor * 2) - randomFactor;
    baseAnticipation += (_random.nextDouble() * randomFactor * 2) - randomFactor;
    
    // Ensure within bounds
    baseHappiness = min(1.0, max(0.0, baseHappiness));
    baseTrust = min(1.0, max(0.0, baseTrust));
    baseAnticipation = min(1.0, max(0.0, baseAnticipation));
    
    return EmotionState(
      happiness: baseHappiness,
      trust: baseTrust,
      anticipation: baseAnticipation,
    );
  }

  String _getEmotionalPrefix(String emotion, double intensity) {
    final Map<String, List<String>> prefixes = {
      'happiness': [
        'I\'m delighted that', 
        'I\'m pleased to hear', 
        'Excellent point about',
      ],
      'anger': [
        'I must object to', 
        'I strongly disagree with', 
        'I take issue with',
      ],
      'fear': [
        'I\'m concerned about', 
        'I\'m worried that', 
        'We should be cautious about',
      ],
      'surprise': [
        'I\'m surprised by', 
        'Interestingly,', 
        'I hadn\'t considered that',
      ],
      'disgust': [
        'I find it troubling that', 
        'I\'m disappointed by', 
        'It\'s unfortunate that',
      ],
      'sadness': [
        'Regrettably,', 
        'Unfortunately,', 
        'I\'m saddened that',
      ],
      'trust': [
        'I believe in', 
        'I\'m confident that', 
        'We can rely on',
      ],
      'anticipation': [
        'I\'m looking forward to', 
        'I anticipate that', 
        'I expect that',
      ],
    };
    
    if (!prefixes.containsKey(emotion) || intensity < 0.4) {
      return '';
    }
    
    final options = prefixes[emotion]!;
    return options[_random.nextInt(options.length)];
  }

  String _getEmotionalSuffix(String emotion, double intensity) {
    final Map<String, List<String>> suffixes = {
      'happiness': [
        'which I find quite encouraging.',
        'and I\'m optimistic about this direction.',
        'which makes me quite hopeful.',
      ],
      'anger': [
        'which I find deeply problematic.',
        'and I cannot support such an approach.',
        'which fundamentally contradicts sound policy.',
      ],
      'fear': [
        'and we should proceed with caution.',
        'which could lead to concerning outcomes.',
        'and I\'m anxious about the implications.',
      ],
      'surprise': [
        'which I hadn\'t expected.',
        'and this changes my perspective.',
        'which is quite surprising.',
      ],
      'disgust': [
        'and I find this approach distasteful.',
        'which goes against my principles.',
        'and I cannot condone such measures.',
      ],
      'sadness': [
        'which is truly unfortunate.',
        'and I wish we had better options.',
        'which is disappointing to see.',
      ],
      'trust': [
        'and I stand firmly behind this.',
        'which aligns with my values.',
        'and I believe this is the right path.',
      ],
      'anticipation': [
        'and I\'m eager to see the results.',
        'and I look forward to what comes next.',
        'which opens interesting possibilities.',
      ],
    };
    
    if (!suffixes.containsKey(emotion) || intensity < 0.5) {
      return '';
    }
    
    final options = suffixes[emotion]!;
    return options[_random.nextInt(options.length)];
  }

  Future<void> _logEmotionChange(String agentId, String emotionType, double change, String trigger) async {
    await _analytics.logAgentEmotionChange(
      agentId: agentId,
      emotionType: emotionType,
      intensity: change.abs(),
      triggerEvent: trigger,
    );
  }

  Future<void> reset() async {
    _agentEmotions.clear();
    await _saveEmotionStates();
    notifyListeners();
  }
}