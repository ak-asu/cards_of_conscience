import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnalyticsEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    id: json['id'],
    type: json['type'],
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'],
  );
}

class AnalyticsService {
  final List<AnalyticsEvent> _events = [];
  final String _storageKey = 'analytics_events';
  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;

  Future<void> _init() async {
    if (_isInitialized) return;
    
    await _loadEvents();
    _isInitialized = true;
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEvents = prefs.getString(_storageKey);
      
      if (savedEvents != null) {
        final List<dynamic> eventsJson = jsonDecode(savedEvents);
        final events = eventsJson.map((e) => AnalyticsEvent.fromJson(e)).toList();
        _events.addAll(events);
      }
    } catch (e) {
      debugPrint('Failed to load analytics events: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only keep the most recent 1000 events to avoid storage issues
      final eventsToSave = _events.length > 1000 
          ? _events.sublist(_events.length - 1000) 
          : _events;
      
      final eventsJson = eventsToSave.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(eventsJson));
    } catch (e) {
      debugPrint('Failed to save analytics events: $e');
    }
  }

  // Log user interactions
  Future<void> logUserMessage({
    required String topicId,
    required bool isVoiceMessage,
    int? characterCount,
    int? durationMs,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'user_message',
      timestamp: DateTime.now(),
      data: {
        'topicId': topicId,
        'isVoiceMessage': false, // Always false since we removed voice functionality
        if (characterCount != null) 'characterCount': characterCount,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logAgentResponse({
    required String agentId,
    required String topicId,
    required String messageType,
    required int characterCount,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'agent_response',
      timestamp: DateTime.now(),
      data: {
        'agentId': agentId,
        'topicId': topicId,
        'messageType': messageType,
        'characterCount': characterCount,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logNegotiationStage({
    required String topicId,
    required String stage,
    required int messageCount,
    required bool isUserParticipating,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'negotiation_stage',
      timestamp: DateTime.now(),
      data: {
        'topicId': topicId,
        'stage': stage,
        'messageCount': messageCount,
        'isUserParticipating': isUserParticipating,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logPolicyDiscussed({
    required String domainId,
    required String policyId,
    required int participantCount,
    required bool reachedConsensus,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'policy_discussed',
      timestamp: DateTime.now(),
      data: {
        'domainId': domainId,
        'policyId': policyId,
        'participantCount': participantCount,
        'reachedConsensus': reachedConsensus,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logUserPolicySelection({
    required String domainId,
    required String policyId,
    required int selectionTimeMs,
    required bool changedMind,
    String? previousPolicyId,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'user_policy_selection',
      timestamp: DateTime.now(),
      data: {
        'domainId': domainId,
        'policyId': policyId,
        'selectionTimeMs': selectionTimeMs,
        'changedMind': changedMind,
        if (previousPolicyId != null) 'previousPolicyId': previousPolicyId,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logAgentEmotionChange({
    required String agentId,
    required String emotionType,
    required double intensity,
    required String triggerEvent,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'agent_emotion_change',
      timestamp: DateTime.now(),
      data: {
        'agentId': agentId,
        'emotionType': emotionType,
        'intensity': intensity,
        'triggerEvent': triggerEvent,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logSessionStart() async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'session_start',
      timestamp: DateTime.now(),
      data: {},
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logSessionEnd({
    required int durationMs,
    required int screensViewed,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'session_end',
      timestamp: DateTime.now(),
      data: {
        'durationMs': durationMs,
        'screensViewed': screensViewed,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  // New methods for tracking phase transitions
  Future<void> logPhaseTransition({
    required String fromPhase,
    required String toPhase,
    required int timeSpentInPreviousPhaseMs,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'phase_transition',
      timestamp: DateTime.now(),
      data: {
        'fromPhase': fromPhase,
        'toPhase': toPhase,
        'timeSpentInPreviousPhaseMs': timeSpentInPreviousPhaseMs,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logUserDecision({
    required String decisionType,
    required String decisionContext,
    required String choice,
    required int decisionTimeMs,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'user_decision',
      timestamp: DateTime.now(),
      data: {
        'decisionType': decisionType,
        'decisionContext': decisionContext,
        'choice': choice,
        'decisionTimeMs': decisionTimeMs,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  Future<void> logFeatureUsage({
    required String featureName,
    required String action,
    Map<String, dynamic>? additionalData,
  }) async {
    await _init();
    
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      type: 'feature_usage',
      timestamp: DateTime.now(),
      data: {
        'featureName': featureName,
        'action': action,
        if (additionalData != null) ...additionalData,
      },
    );
    
    _events.add(event);
    await _saveEvents();
  }

  // Analytics reporting methods
  Future<Map<String, dynamic>> getUserEngagementMetrics() async {
    await _init();
    
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastWeek = now.subtract(const Duration(days: 7));
    
    // Count user messages
    final totalMessages = _events.where((e) => e.type == 'user_message').length;
    final messagesLast24h = _events.where((e) => 
        e.type == 'user_message' && e.timestamp.isAfter(last24Hours)).length;
    final messagesLastWeek = _events.where((e) => 
        e.type == 'user_message' && e.timestamp.isAfter(lastWeek)).length;
    
    // Calculate average message length
    final characterCounts = _events
        .where((e) => e.type == 'user_message' && e.data.containsKey('characterCount'))
        .map((e) => e.data['characterCount'] as int);
    
    final int totalCharacters = characterCounts.isNotEmpty 
        ? characterCounts.reduce((a, b) => a + b) 
        : 0;
    
    final double averageMessageLength = characterCounts.isNotEmpty 
        ? totalCharacters / characterCounts.length 
        : 0;
    
    // Calculate voice message metrics
    final voiceMessages = _events.where((e) => 
        e.type == 'user_message' && e.data['isVoiceMessage'] == true);
    
    final durations = voiceMessages
        .where((e) => e.data.containsKey('durationMs'))
        .map((e) => e.data['durationMs'] as int);
    
    final int totalDurationMs = durations.isNotEmpty 
        ? durations.reduce((a, b) => a + b) 
        : 0;
    
    final double averageVoiceDurationMs = durations.isNotEmpty 
        ? totalDurationMs / durations.length 
        : 0;
    
    return {
      'totalMessages': totalMessages,
      'messagesLast24h': messagesLast24h,
      'messagesLastWeek': messagesLastWeek,
      'averageMessageLength': averageMessageLength,
      'totalVoiceMessages': voiceMessages.length,
      'averageVoiceDurationMs': averageVoiceDurationMs,
    };
  }

  Future<Map<String, dynamic>> getAgentInteractionMetrics() async {
    await _init();
    
    // Count agent responses per agent
    final Map<String, int> responsesByAgent = {};
    
    for (final event in _events.where((e) => e.type == 'agent_response')) {
      final agentId = event.data['agentId'] as String;
      responsesByAgent[agentId] = (responsesByAgent[agentId] ?? 0) + 1;
    }
    
    // Count negotiation stages
    final Map<String, int> stageCount = {};
    
    for (final event in _events.where((e) => e.type == 'negotiation_stage')) {
      final stage = event.data['stage'] as String;
      stageCount[stage] = (stageCount[stage] ?? 0) + 1;
    }
    
    // Count policy discussions and consensus outcomes
    final policyDiscussions = _events.where((e) => e.type == 'policy_discussed').length;
    final consensusReached = _events.where((e) => 
        e.type == 'policy_discussed' && e.data['reachedConsensus'] == true).length;
    
    // Calculate consensus rate
    final double consensusRate = policyDiscussions > 0 
        ? consensusReached / policyDiscussions 
        : 0;
    
    return {
      'responsesByAgent': responsesByAgent,
      'stageCount': stageCount,
      'policyDiscussions': policyDiscussions,
      'consensusReached': consensusReached,
      'consensusRate': consensusRate,
    };
  }

  Future<Map<String, dynamic>> getEmotionMetrics() async {
    await _init();
    
    // Analyze emotion changes by agent
    final Map<String, Map<String, int>> emotionsByAgent = {};
    
    for (final event in _events.where((e) => e.type == 'agent_emotion_change')) {
      final agentId = event.data['agentId'] as String;
      final emotionType = event.data['emotionType'] as String;
      
      if (!emotionsByAgent.containsKey(agentId)) {
        emotionsByAgent[agentId] = {};
      }
      
      emotionsByAgent[agentId]![emotionType] = 
          (emotionsByAgent[agentId]![emotionType] ?? 0) + 1;
    }
    
    // Find most common trigger events
    final Map<String, int> triggerEvents = {};
    
    for (final event in _events.where((e) => e.type == 'agent_emotion_change')) {
      final trigger = event.data['triggerEvent'] as String;
      triggerEvents[trigger] = (triggerEvents[trigger] ?? 0) + 1;
    }
    
    return {
      'emotionsByAgent': emotionsByAgent,
      'triggerEvents': triggerEvents,
    };
  }

  Future<Map<String, dynamic>> getSessionMetrics() async {
    await _init();
    
    // Count sessions
    final sessionStarts = _events.where((e) => e.type == 'session_start').length;
    
    // Calculate average session duration
    final sessionDurations = _events
        .where((e) => e.type == 'session_end' && e.data.containsKey('durationMs'))
        .map((e) => e.data['durationMs'] as int);
    
    final int totalDurationMs = sessionDurations.isNotEmpty 
        ? sessionDurations.reduce((a, b) => a + b) 
        : 0;
    
    final double averageSessionDurationMs = sessionDurations.isNotEmpty 
        ? totalDurationMs / sessionDurations.length 
        : 0;
    
    // Calculate average screens per session
    final screensViewed = _events
        .where((e) => e.type == 'session_end' && e.data.containsKey('screensViewed'))
        .map((e) => e.data['screensViewed'] as int);
    
    final int totalScreens = screensViewed.isNotEmpty 
        ? screensViewed.reduce((a, b) => a + b) 
        : 0;
    
    final double averageScreensPerSession = screensViewed.isNotEmpty 
        ? totalScreens / screensViewed.length 
        : 0;
    
    return {
      'sessionCount': sessionStarts,
      'averageSessionDurationMs': averageSessionDurationMs,
      'averageScreensPerSession': averageScreensPerSession,
    };
  }

  // Enhanced analytics reporting methods
  Future<Map<String, dynamic>> getPhaseProgressionMetrics() async {
    await _init();
    
    final phaseTransitions = _events.where((e) => e.type == 'phase_transition');
    
    // Calculate average time spent in each phase
    final Map<String, List<int>> timeSpentByPhase = {};
    
    for (final event in phaseTransitions) {
      final fromPhase = event.data['fromPhase'] as String;
      final timeSpent = event.data['timeSpentInPreviousPhaseMs'] as int;
      
      if (!timeSpentByPhase.containsKey(fromPhase)) {
        timeSpentByPhase[fromPhase] = [];
      }
      
      timeSpentByPhase[fromPhase]!.add(timeSpent);
    }
    
    final Map<String, double> averageTimeByPhase = {};
    
    timeSpentByPhase.forEach((phase, times) {
      final totalTime = times.reduce((a, b) => a + b);
      averageTimeByPhase[phase] = totalTime / times.length;
    });
    
    // Count phase transition patterns
    final Map<String, int> transitionPatterns = {};
    
    for (final event in phaseTransitions) {
      final fromPhase = event.data['fromPhase'] as String;
      final toPhase = event.data['toPhase'] as String;
      final pattern = '$fromPhase->$toPhase';
      
      transitionPatterns[pattern] = (transitionPatterns[pattern] ?? 0) + 1;
    }
    
    return {
      'averageTimeByPhase': averageTimeByPhase,
      'transitionPatterns': transitionPatterns,
    };
  }

  Future<Map<String, dynamic>> getUserDecisionMetrics() async {
    await _init();
    
    final userDecisions = _events.where((e) => e.type == 'user_decision');
    
    // Count decisions by type
    final Map<String, int> decisionsByType = {};
    
    for (final event in userDecisions) {
      final decisionType = event.data['decisionType'] as String;
      decisionsByType[decisionType] = (decisionsByType[decisionType] ?? 0) + 1;
    }
    
    // Analyze decision patterns
    final Map<String, Map<String, int>> choicesByDecisionType = {};
    
    for (final event in userDecisions) {
      final decisionType = event.data['decisionType'] as String;
      final choice = event.data['choice'] as String;
      
      if (!choicesByDecisionType.containsKey(decisionType)) {
        choicesByDecisionType[decisionType] = {};
      }
      
      choicesByDecisionType[decisionType]![choice] = 
          (choicesByDecisionType[decisionType]![choice] ?? 0) + 1;
    }
    
    // Calculate average decision time by type
    final Map<String, List<int>> decisionTimesByType = {};
    
    for (final event in userDecisions) {
      final decisionType = event.data['decisionType'] as String;
      final decisionTime = event.data['decisionTimeMs'] as int;
      
      if (!decisionTimesByType.containsKey(decisionType)) {
        decisionTimesByType[decisionType] = [];
      }
      
      decisionTimesByType[decisionType]!.add(decisionTime);
    }
    
    final Map<String, double> averageDecisionTimesByType = {};
    
    decisionTimesByType.forEach((type, times) {
      final totalTime = times.reduce((a, b) => a + b);
      averageDecisionTimesByType[type] = totalTime / times.length;
    });
    
    return {
      'decisionsByType': decisionsByType,
      'choicesByDecisionType': choicesByDecisionType,
      'averageDecisionTimesByType': averageDecisionTimesByType,
    };
  }

  Future<Map<String, dynamic>> getFeatureUsageMetrics() async {
    await _init();
    
    final featureUsage = _events.where((e) => e.type == 'feature_usage');
    
    // Count usage by feature name
    final Map<String, int> usageByFeature = {};
    
    for (final event in featureUsage) {
      final featureName = event.data['featureName'] as String;
      usageByFeature[featureName] = (usageByFeature[featureName] ?? 0) + 1;
    }
    
    // Count actions per feature
    final Map<String, Map<String, int>> actionsByFeature = {};
    
    for (final event in featureUsage) {
      final featureName = event.data['featureName'] as String;
      final action = event.data['action'] as String;
      
      if (!actionsByFeature.containsKey(featureName)) {
        actionsByFeature[featureName] = {};
      }
      
      actionsByFeature[featureName]![action] = 
          (actionsByFeature[featureName]![action] ?? 0) + 1;
    }
    
    return {
      'usageByFeature': usageByFeature,
      'actionsByFeature': actionsByFeature,
    };
  }

  // Export functionality
  Future<String> exportAnalyticsData() async {
    await _init();
    
    if (_events.isEmpty) {
      return '';
    }
    
    try {
      // Create a DateTime string for the filename
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final dateString = dateFormat.format(DateTime.now());
      
      // Get the directory for storing the export
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/analytics_export_$dateString.json';
      
      // Prepare the export data
      final Map<String, dynamic> exportData = {
        'exportTimestamp': DateTime.now().toIso8601String(),
        'events': _events.map((e) => e.toJson()).toList(),
        'eventCount': _events.length,
        'metrics': {
          'userEngagement': await getUserEngagementMetrics(),
          'agentInteraction': await getAgentInteractionMetrics(),
          'emotions': await getEmotionMetrics(),
          'sessions': await getSessionMetrics(),
          'phaseProgression': await getPhaseProgressionMetrics(),
          'userDecisions': await getUserDecisionMetrics(),
          'featureUsage': await getFeatureUsageMetrics(),
        }
      };
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonEncode(exportData));
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to export analytics data: $e');
      return '';
    }
  }

  // Fetch aggregated data for dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    await _init();
    
    return {
      'userEngagement': await getUserEngagementMetrics(),
      'agentInteraction': await getAgentInteractionMetrics(),
      'emotions': await getEmotionMetrics(),
      'sessions': await getSessionMetrics(),
      'phaseProgression': await getPhaseProgressionMetrics(),
      'userDecisions': await getUserDecisionMetrics(),
      'featureUsage': await getFeatureUsageMetrics(),
      'totalEventsRecorded': _events.length,
      'firstEventRecorded': _events.isNotEmpty ? _events.first.timestamp.toIso8601String() : null,
      'lastEventRecorded': _events.isNotEmpty ? _events.last.timestamp.toIso8601String() : null,
    };
  }

  Future<void> clearAllEvents() async {
    _events.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Failed to clear analytics events: $e');
    }
  }
}