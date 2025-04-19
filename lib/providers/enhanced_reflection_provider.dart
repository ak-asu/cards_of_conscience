import 'package:flutter/foundation.dart';

import '../models/enhanced_reflection_data.dart';
import '../models/policy_models.dart';
import '../services/chat_service.dart';
import '../utils/game_logger.dart';

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
  
  ReflectionData copyWith({
    Map<String, PolicyOption>? humanSelections,
    Map<String, Map<String, PolicyOption>>? aiSelections,
    DateTime? timestamp,
    Map<String, List<String>>? analysisResults,
    List<String>? insights,
    double? agreementScore,
  }) {
    return ReflectionData(
      humanSelections: humanSelections ?? this.humanSelections,
      aiSelections: aiSelections ?? this.aiSelections,
      timestamp: timestamp ?? this.timestamp,
      analysisResults: analysisResults ?? this.analysisResults,
      insights: insights ?? this.insights,
      agreementScore: agreementScore ?? this.agreementScore,
    );
  }
}

class EnhancedReflectionProvider with ChangeNotifier {
  EnhancedReflectionData _enhancedData = EnhancedReflectionData();
  ReflectionData _basicData = ReflectionData.empty();
  bool _isLoading = true;
  String? _error;
  final ChatService _chatService;

  EnhancedReflectionData get enhancedData => _enhancedData;
  ReflectionData get basicData => _basicData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EnhancedReflectionProvider({required ChatService chatService}) 
      : _chatService = chatService {
    _loadReflectionData();
  }

  Future<void> _loadReflectionData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First, load basic reflection data
      await _loadBasicReflectionData();
      
      // Then, load enhanced reflection data
      await _loadEnhancedReflectionData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading reflection data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadBasicReflectionData() async {
    try {
      final gameLogsList = await GameLogger.getGameLogs();
      
      if (gameLogsList.isEmpty) {
        _error = 'No game data found. Please play a game first.';
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
      
      _basicData = ReflectionData(
        humanSelections: humanSelections,
        aiSelections: aiSelections,
        timestamp: timestamp,
        analysisResults: analysisResults,
        insights: insights,
        agreementScore: agreementScore,
      );
    } catch (e) {
      _error = 'Error loading basic reflection data: $e';
    }
  }

  Future<void> _loadEnhancedReflectionData() async {
    try {
      if (_error != null) return;
      
      // Create a data object directly
      final dataProvider = EnhancedReflectionData();
      
      // Initialize with empty data
      _enhancedData = dataProvider;
      
    } catch (e) {
      _error = 'Error loading enhanced reflection data: $e';
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
      final percentageAgreement = totalAgents > 0 ? (agentsWithSameChoice / totalAgents) * 100 : 0;
      
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

  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _loadReflectionData();
  }
  
  // Additional methods for enhanced analytics
  
  Map<String, double> getDomainWeightings() {
    final Map<String, double> weightings = {};
    
    if (_basicData.humanSelections.isEmpty) return weightings;
    
    final totalCost = _basicData.humanSelections.values.fold(0, (sum, option) => sum + option.cost);
    
    _basicData.humanSelections.forEach((domainId, option) {
      weightings[domainId] = totalCost > 0 ? option.cost / totalCost : 0;
    });
    
    return weightings;
  }
  
  List<String> getContrastingInsights() {
    final List<String> contrastingInsights = [];
    
    // Compare basic insights with enhanced insights
    final basicTopics = _basicData.insights.map((insight) => insight.split(' ').take(3).join(' ')).toSet();
    final enhancedTopics = _enhancedData.justiceOrientedFeedback['strengths']?.map((insight) => 
        insight.toString().split(' ').take(3).join(' ')).toSet() ?? <String>{};
    
    // Find topics in enhanced that aren't in basic
    final uniqueTopics = enhancedTopics.difference(basicTopics);
    
    if (uniqueTopics.isNotEmpty) {
      contrastingInsights.add('Enhanced analysis revealed additional perspectives not covered in basic analysis.');
      
      // Find the full insights for these unique topics
      for (final topic in uniqueTopics) {
        final matchingInsights = (_enhancedData.justiceOrientedFeedback['strengths'] as List<dynamic>?)
            ?.where((insight) => insight.toString().startsWith(topic))
            .map((e) => e.toString())
            .toList() ?? [];
        
        contrastingInsights.addAll(matchingInsights);
      }
    }
    
    return contrastingInsights;
  }
  
  List<Map<String, dynamic>> getCombinedAnalytics() {
    final List<Map<String, dynamic>> combinedAnalytics = [];
    
    _basicData.humanSelections.forEach((domainId, option) {
      final basicAnalysis = _basicData.analysisResults[domainId] ?? [];
      final enhancedAnalysis = _enhancedData.policyImpacts[domainId] as List<dynamic>? ?? [];
      
      combinedAnalytics.add({
        'domainId': domainId,
        'domainName': option.domain,
        'selectedOption': option.title,
        'cost': option.cost,
        'basicAnalysis': basicAnalysis,
        'enhancedAnalysis': enhancedAnalysis,
        'agreementScore': _getDomainAgreementScore(domainId),
      });
    });
    
    return combinedAnalytics;
  }
  
  double _getDomainAgreementScore(String domainId) {
    if (!_basicData.humanSelections.containsKey(domainId)) return 0.0;
    
    final humanOption = _basicData.humanSelections[domainId]!;
    int agreementCount = 0;
    int totalAgents = 0;
    
    _basicData.aiSelections.forEach((agentId, selections) {
      if (selections.containsKey(domainId)) {
        totalAgents++;
        if (selections[domainId]!.id == humanOption.id) {
          agreementCount++;
        }
      }
    });
    
    return totalAgents > 0 ? (agreementCount / totalAgents) * 100 : 0.0;
  }
}