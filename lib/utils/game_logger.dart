import 'package:hive_flutter/hive_flutter.dart';

import '../models/policy_models.dart';

class GameLogger {
  static const String _gameLogBox = 'gameLogBox';
  static const String _aiSelectionsKey = 'aiSelections';
  static const String _humanSelectionsKey = 'humanSelections';
  static const String _timestampKey = 'timestamp';

  static String get aiSelectionsKey => _aiSelectionsKey;
  static String get humanSelectionsKey => _humanSelectionsKey;
  static String get timestampKey => _timestampKey;

  static Future<void> logGameSelections({
    required Map<String, PolicyOption> humanSelections,
    required Map<String, Map<String, PolicyOption>> aiSelections,
  }) async {
    try {
      final box = await Hive.openBox(_gameLogBox);
      
      final gameLog = {
        _humanSelectionsKey: _serializeSelections(humanSelections),
        _aiSelectionsKey: _serializeAiSelections(aiSelections),
        _timestampKey: DateTime.now().toIso8601String(),
      };
      
      await box.add(gameLog);
      
    } catch (e) {
      print('Error logging game data: $e');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getGameLogs() async {
    try {
      final box = await Hive.openBox(_gameLogBox);
      final logs = <Map<String, dynamic>>[];
      
      for (var i = 0; i < box.length; i++) {
        final log = box.getAt(i);
        if (log != null) {
          logs.add(Map<String, dynamic>.from(log));
        }
      }
      
      return logs;
      
    } catch (e) {
      print('Error retrieving game logs: $e');
      return [];
    }
  }
  
  static Map<String, dynamic> _serializeSelections(Map<String, PolicyOption> selections) {
    return selections.map((key, value) => MapEntry(key, value.toJson()));
  }
  
  static Map<String, dynamic> _serializeAiSelections(Map<String, Map<String, PolicyOption>> aiSelections) {
    return aiSelections.map((agentId, selections) {
      return MapEntry(agentId, _serializeSelections(selections));
    });
  }
  
  static Map<String, PolicyOption> deserializeSelections(Map<String, dynamic> serializedSelections) {
    return serializedSelections.map((key, value) => 
      MapEntry(key, PolicyOption.fromJson(Map<String, dynamic>.from(value)))
    );
  }
}