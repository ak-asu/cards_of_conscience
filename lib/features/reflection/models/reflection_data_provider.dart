import 'package:flutter/foundation.dart';

import '../../phase_one/models/game_logger.dart';
import '../../phase_one/models/policy_models.dart';

class ReflectionData {
  final Map<String, PolicyOption> humanSelections;
  final Map<String, Map<String, PolicyOption>> aiSelections;
  final DateTime timestamp;
  final Map<String, List<String>> analysisResults;
  final List<String> insights;
  final double agreementScore;

  ReflectionData({
    required this.humanSelections,
    required this.aiSelections,
    required this.timestamp,
    required this.analysisResults,
    required this.insights,
    required this.agreementScore,
  });

  factory ReflectionData.empty() {
    return ReflectionData(
      humanSelections: {},
      aiSelections: {},
      timestamp: DateTime.now(),
      analysisResults: {},
      insights: [],
      agreementScore: 0.0,
    );
  }
}

class ReflectionDataProvider with ChangeNotifier {
  ReflectionData _reflectionData = ReflectionData.empty();
  bool _isLoading = true;
  String? _error;

  ReflectionData get reflectionData => _reflectionData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReflectionData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final gameLogsList = await GameLogger.getGameLogs();
      
      if (gameLogsList.isEmpty) {
        _error = 'No game data found. Please play a game first.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Use the most recent game log
      final latestLog = gameLogsList.last;
      
      // Parse human selections
      final humanSelectionsJson = latestLog[GameLogger.humanSelectionsKey] as Map<String, dynamic>;
      final humanSelections = GameLogger.deserializeSelections(humanSelectionsJson);
      
      // Parse AI selections
      final aiSelectionsJson = latestLog[GameLogger.aiSelectionsKey] as Map<String, dynamic>;
      final aiSelections = <String, Map<String, PolicyOption>>{};
      
      aiSelectionsJson.forEach((agentId, selectionsJson) {
        aiSelections[agentId] = GameLogger.deserializeSelections(selectionsJson as Map<String, dynamic>);
      });
      
      // Parse timestamp
      final timestampStr = latestLog[GameLogger.timestampKey] as String;
      final timestamp = DateTime.parse(timestampStr);
      
      // Generate analysis
      final analysisResults = _analyzeSelections(humanSelections, aiSelections);
      final insights = _generateInsights(humanSelections, aiSelections, analysisResults);
      final agreementScore = _calculateAgreementScore(humanSelections, aiSelections);
      
      _reflectionData = ReflectionData(
        humanSelections: humanSelections,
        aiSelections: aiSelections,
        timestamp: timestamp,
        analysisResults: analysisResults,
        insights: insights,
        agreementScore: agreementScore,
      );
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _error = 'Error loading reflection data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, List<String>> _analyzeSelections(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    final Map<String, List<String>> results = {};
    
    // Analyze policy domains
    for (final entry in humanSelections.entries) {
      final domainId = entry.key;
      final humanOption = entry.value;
      final List<String> domainAnalysis = [];
      
      // Policy cost analysis
      domainAnalysis.add('You allocated ${humanOption.cost} units to this domain.');
      
      // Compare with AI agents
      int agentsWithSameChoice = 0;
      final List<String> agentsWithDifferentChoices = [];
      
      aiSelections.forEach((agentId, selections) {
        if (selections.containsKey(domainId)) {
          final aiOption = selections[domainId]!;
          if (aiOption.id == humanOption.id) {
            agentsWithSameChoice++;
          } else {
            agentsWithDifferentChoices.add(agentId);
          }
        }
      });
      
      final totalAgents = aiSelections.length;
      final percentageAgreement = (agentsWithSameChoice / totalAgents) * 100;
      
      domainAnalysis.add('${percentageAgreement.toStringAsFixed(0)}% of AI agents made the same choice as you.');
      
      if (agentsWithDifferentChoices.isNotEmpty) {
        domainAnalysis.add('AI agents with different selections: ${agentsWithDifferentChoices.length}');
      }
      
      results[domainId] = domainAnalysis;
    }
    
    return results;
  }
  
  List<String> _generateInsights(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
    Map<String, List<String>> analysisResults,
  ) {
    final List<String> insights = [];
    
    // Calculate total cost allocated by the human player
    final totalHumanCost = humanSelections.values.fold(0, (total, option) => total + option.cost);
    insights.add('You allocated a total of $totalHumanCost budget units across all policy domains.');
    
    // Compare budget allocation with AI agents
    final aiCosts = <int>[];
    aiSelections.forEach((agentId, selections) {
      final totalAiCost = selections.values.fold(0, (total, option) => total + option.cost);
      aiCosts.add(totalAiCost);
    });
    
    final avgAiCost = aiCosts.isEmpty ? 0 : aiCosts.reduce((a, b) => a + b) / aiCosts.length;
    
    if (totalHumanCost > avgAiCost) {
      insights.add('You allocated more budget units (${(totalHumanCost - avgAiCost).toStringAsFixed(1)} more) than the average AI agent.');
    } else if (totalHumanCost < avgAiCost) {
      insights.add('You allocated fewer budget units (${(avgAiCost - totalHumanCost).toStringAsFixed(1)} fewer) than the average AI agent.');
    } else {
      insights.add('Your budget allocation matched the average AI agent exactly.');
    }
    
    // Analyze highest/lowest cost policy preferences
    final sortedByHumanCost = humanSelections.entries.toList()
      ..sort((a, b) => b.value.cost.compareTo(a.value.cost));
    
    if (sortedByHumanCost.isNotEmpty) {
      final highestCostDomain = sortedByHumanCost.first;
      insights.add('You allocated the most resources to ${highestCostDomain.value.domain} (${highestCostDomain.value.cost} units).');
      
      final lowestCostDomain = sortedByHumanCost.last;
      insights.add('You allocated the least resources to ${lowestCostDomain.value.domain} (${lowestCostDomain.value.cost} units).');
    }
    
    return insights;
  }
  
  double _calculateAgreementScore(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    if (humanSelections.isEmpty || aiSelections.isEmpty) {
      return 0.0;
    }
    
    int totalComparisons = 0;
    int totalAgreements = 0;
    
    humanSelections.forEach((domainId, humanOption) {
      aiSelections.forEach((agentId, aiAgentSelections) {
        if (aiAgentSelections.containsKey(domainId)) {
          totalComparisons++;
          if (aiAgentSelections[domainId]!.id == humanOption.id) {
            totalAgreements++;
          }
        }
      });
    });
    
    return totalComparisons > 0 ? (totalAgreements / totalComparisons) * 100 : 0.0;
  }
}