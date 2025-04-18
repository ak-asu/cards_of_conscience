import 'dart:math';

import 'package:flutter/foundation.dart';

import '../features/phase_two/group_comm/services/chat_service.dart';
import '../utils/sentiment_analyzer.dart';
import 'game_logger.dart';
import 'policy_models.dart';

class JusticeIndex {
  final double inclusivityScore;
  final double equityScore;
  final double sustainabilityScore;
  final double overallScore;

  JusticeIndex({
    required this.inclusivityScore,
    required this.equityScore,
    required this.sustainabilityScore,
    required this.overallScore,
  });

  factory JusticeIndex.empty() {
    return JusticeIndex(
      inclusivityScore: 0.0,
      equityScore: 0.0,
      sustainabilityScore: 0.0,
      overallScore: 0.0,
    );
  }
}

class ImpactMetrics {
  final Map<String, double> immediateOutcomes;
  final Map<String, double> socialMetrics;
  final Map<String, double> longTermImpacts;
  final Map<String, Map<int, double>> timeSeriesProjections;

  ImpactMetrics({
    required this.immediateOutcomes,
    required this.socialMetrics,
    required this.longTermImpacts,
    required this.timeSeriesProjections,
  });

  factory ImpactMetrics.empty() {
    return ImpactMetrics(
      immediateOutcomes: {},
      socialMetrics: {},
      longTermImpacts: {},
      timeSeriesProjections: {},
    );
  }
}

class MessageSentimentAnalysis {
  final String messageId;
  final String senderId;
  final String content;
  final Map<String, double> sentimentScores;
  final List<String> detectedKeywords;
  final List<String> ethicalConcepts;
  final DateTime timestamp;

  MessageSentimentAnalysis({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.sentimentScores,
    required this.detectedKeywords,
    required this.ethicalConcepts,
    required this.timestamp,
  });
}

class EnhancedReflectionData {
  final Map<String, PolicyOption> humanSelections;
  final Map<String, Map<String, PolicyOption>> aiSelections;
  final DateTime timestamp;
  
  // Enhanced metrics
  final JusticeIndex justiceIndex;
  final ImpactMetrics impactMetrics;
  final List<MessageSentimentAnalysis> messageSentiments;
  final Map<String, double> domainImpactScores;
  final List<String> ethicalTradeoffs;
  final Map<String, List<String>> policyRecommendations;
  final Map<String, List<String>> sentimentAnalysisInsights;
  final double agreementScore;

  EnhancedReflectionData({
    required this.humanSelections,
    required this.aiSelections,
    required this.timestamp,
    required this.justiceIndex,
    required this.impactMetrics,
    required this.messageSentiments,
    required this.domainImpactScores,
    required this.ethicalTradeoffs,
    required this.policyRecommendations,
    required this.sentimentAnalysisInsights,
    required this.agreementScore,
  });

  factory EnhancedReflectionData.empty() {
    return EnhancedReflectionData(
      humanSelections: {},
      aiSelections: {},
      timestamp: DateTime.now(),
      justiceIndex: JusticeIndex.empty(),
      impactMetrics: ImpactMetrics.empty(),
      messageSentiments: [],
      domainImpactScores: {},
      ethicalTradeoffs: [],
      policyRecommendations: {},
      sentimentAnalysisInsights: {},
      agreementScore: 0.0,
    );
  }
}

class EnhancedReflectionDataProvider with ChangeNotifier {
  EnhancedReflectionData _reflectionData = EnhancedReflectionData.empty();
  bool _isLoading = true;
  String? _error;
  final ChatService _chatService;
  final SentimentAnalyzer _sentimentAnalyzer = SentimentAnalyzer();

  EnhancedReflectionData get reflectionData => _reflectionData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EnhancedReflectionDataProvider({required ChatService chatService})
      : _chatService = chatService;

  Future<void> loadEnhancedReflectionData() async {
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
      
      // Generate enhanced analysis
      final justiceIndex = _calculateJusticeIndex(humanSelections, aiSelections);
      final impactMetrics = _calculateImpactMetrics(humanSelections, aiSelections);
      final messageSentiments = await _analyzeConversationSentiments();
      final domainImpactScores = _calculateDomainImpactScores(humanSelections, aiSelections);
      final ethicalTradeoffs = _identifyEthicalTradeoffs(humanSelections, aiSelections);
      final policyRecommendations = _generatePolicyRecommendations(humanSelections, aiSelections, domainImpactScores);
      final sentimentAnalysisInsights = _generateSentimentAnalysisInsights(messageSentiments);
      final agreementScore = _calculateAgreementScore(humanSelections, aiSelections);
      
      _reflectionData = EnhancedReflectionData(
        humanSelections: humanSelections,
        aiSelections: aiSelections,
        timestamp: timestamp,
        justiceIndex: justiceIndex,
        impactMetrics: impactMetrics,
        messageSentiments: messageSentiments,
        domainImpactScores: domainImpactScores,
        ethicalTradeoffs: ethicalTradeoffs,
        policyRecommendations: policyRecommendations,
        sentimentAnalysisInsights: sentimentAnalysisInsights,
        agreementScore: agreementScore,
      );
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _error = 'Error loading enhanced reflection data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  JusticeIndex _calculateJusticeIndex(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    if (humanSelections.isEmpty) {
      return JusticeIndex.empty();
    }

    // In a real implementation, these would be calculated based on specific policy details
    // For now, we'll use a heuristic calculation based on policy costs and alignment with AI agents
    
    // Simulate inclusivity score based on policy choices
    double inclusivityScore = 0.0;
    double equityScore = 0.0;
    double sustainabilityScore = 0.0;
    
    // Example calculation:
    // - Policies with higher cost tend to be more inclusivity-focused
    // - Policies that align with more AI agents are generally more balanced (equity)
    // - Policies in certain domains affect sustainability more
    
    double costTotal = 0.0;
    int policyCount = 0;
    
    // Calculate inclusivity based on average policy cost (higher cost = more inclusive programs)
    humanSelections.forEach((domainId, option) {
      costTotal += option.cost;
      policyCount++;
      
      // Domain-specific contributions
      if (domainId.contains('education')) {
        inclusivityScore += 10.0;
        equityScore += 15.0;
        sustainabilityScore += 5.0;
      } else if (domainId.contains('healthcare')) {
        inclusivityScore += 15.0;
        equityScore += 10.0;
        sustainabilityScore += 5.0;
      } else if (domainId.contains('environment')) {
        inclusivityScore += 5.0;
        equityScore += 5.0;
        sustainabilityScore += 20.0;
      } else if (domainId.contains('economy')) {
        inclusivityScore += 10.0;
        equityScore += 10.0;
        sustainabilityScore += 10.0;
      } else {
        inclusivityScore += 8.0;
        equityScore += 8.0;
        sustainabilityScore += 8.0;
      }
    });
    
    // Adjust scores based on policy costs
    if (policyCount > 0) {
      final avgCost = costTotal / policyCount;
      inclusivityScore += avgCost * 10; // Higher cost policies often include more support mechanisms
    }
    
    // Calculate equity score based on agreement with AI agents
    int totalComparisons = 0;
    int alignedChoices = 0;
    
    humanSelections.forEach((domainId, humanOption) {
      aiSelections.forEach((agentId, selections) {
        if (selections.containsKey(domainId)) {
          totalComparisons++;
          if (selections[domainId]!.id == humanOption.id) {
            alignedChoices++;
          }
        }
      });
    });
    
    if (totalComparisons > 0) {
      final alignmentRate = alignedChoices / totalComparisons;
      equityScore += alignmentRate * 30; // Policies with broad consensus tend to be more equitable
    }
    
    // Add random variation to make the data more interesting (in a real implementation,
    // this would be based on specific policy attributes)
    final random = Random();
    inclusivityScore += random.nextDouble() * 20 - 10; // +/- 10 points
    equityScore += random.nextDouble() * 20 - 10;
    sustainabilityScore += random.nextDouble() * 20 - 10;
    
    // Normalize scores to 0-100 range
    inclusivityScore = max(0, min(100, inclusivityScore));
    equityScore = max(0, min(100, equityScore));
    sustainabilityScore = max(0, min(100, sustainabilityScore));
    
    // Calculate overall score as weighted average
    final overallScore = (inclusivityScore * 0.4) + (equityScore * 0.3) + (sustainabilityScore * 0.3);
    
    return JusticeIndex(
      inclusivityScore: inclusivityScore,
      equityScore: equityScore,
      sustainabilityScore: sustainabilityScore,
      overallScore: overallScore,
    );
  }

  ImpactMetrics _calculateImpactMetrics(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    if (humanSelections.isEmpty) {
      return ImpactMetrics.empty();
    }

    // In a real implementation, these would be calculated based on specific policy details
    // For now, we'll use dummy data to demonstrate the UI capabilities
    
    // Immediate outcomes
    final Map<String, double> immediateOutcomes = {
      'budget_efficiency': 67.5,
      'social_welfare': 72.3,
      'economic_growth': 54.8,
      'public_health': 81.2,
      'education_quality': 63.7,
      'environmental_impact': 58.9,
    };
    
    // Social metrics
    final Map<String, double> socialMetrics = {
      'community_satisfaction': 65.2,
      'inequality_reduction': 58.7,
      'social_mobility': 48.3,
      'public_trust': 72.5,
      'civic_engagement': 53.8,
    };
    
    // Long-term impacts
    final Map<String, double> longTermImpacts = {
      'economic_stability': 62.1,
      'health_outcomes': 74.8,
      'educational_attainment': 60.5,
      'environmental_sustainability': 55.2,
      'infrastructure_quality': 58.7,
      'innovation_capacity': 65.3,
    };
    
    // Time series projections
    final Map<String, Map<int, double>> timeSeriesProjections = {
      'economic_growth': {
        1: 1.2,
        2: 2.5,
        3: 3.8,
        4: 4.2,
        5: 4.9,
      },
      'literacy_rate': {
        1: 85.2,
        2: 87.5,
        3: 89.8,
        4: 91.2,
        5: 92.5,
      },
      'healthcare_access': {
        1: 78.3,
        2: 82.1,
        3: 85.7,
        4: 88.2,
        5: 90.5,
      },
      'environmental_quality': {
        1: 62.5,
        2: 65.8,
        3: 69.3,
        4: 72.7,
        5: 75.2,
      },
    };
    
    return ImpactMetrics(
      immediateOutcomes: immediateOutcomes,
      socialMetrics: socialMetrics,
      longTermImpacts: longTermImpacts,
      timeSeriesProjections: timeSeriesProjections,
    );
  }

  Future<List<MessageSentimentAnalysis>> _analyzeConversationSentiments() async {
    final List<MessageSentimentAnalysis> results = [];
    
    try {
      // Get messages from the chat service
      final messages = _chatService.messages;
      
      for (final message in messages) {
        final sentimentScores = _sentimentAnalyzer.analyzeSentiment(message.content);
        final keywords = _sentimentAnalyzer.extractKeywords(message.content);
        final ethicalConcepts = _sentimentAnalyzer.identifyEthicalConcepts(message.content);
        
        results.add(MessageSentimentAnalysis(
          messageId: message.id,
          senderId: message.senderId,
          content: message.content,
          sentimentScores: sentimentScores,
          detectedKeywords: keywords,
          ethicalConcepts: ethicalConcepts,
          timestamp: message.timestamp,
        ));
      }
    } catch (e) {
      debugPrint('Error analyzing conversation sentiments: $e');
    }
    
    return results;
  }

  Map<String, double> _calculateDomainImpactScores(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    if (humanSelections.isEmpty) {
      return {};
    }

    // In a real implementation, this would be based on domain-specific impact models
    // For now, we'll create simulated scores
    final Map<String, double> scores = {};
    final random = Random();
    
    humanSelections.forEach((domainId, option) {
      // Base score in the 50-90 range
      final double baseScore = 50.0 + (option.cost * 10); // Higher cost = higher potential impact
      
      // Adjust based on alignment with AI consensus
      int aiAgentsWithSameChoice = 0;
      
      aiSelections.forEach((agentId, selections) {
        if (selections.containsKey(domainId) && 
            selections[domainId]!.id == option.id) {
          aiAgentsWithSameChoice++;
        }
      });
      
      // Higher score if aligned with AI consensus
      final aiAlignmentBonus = (aiAgentsWithSameChoice / max(1, aiSelections.length)) * 20;
      
      // Calculate final score with some randomness
      final score = baseScore + aiAlignmentBonus + (random.nextDouble() * 10 - 5);
      
      scores[domainId] = max(0, min(100, score));
    });
    
    return scores;
  }

  List<String> _identifyEthicalTradeoffs(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
  ) {
    // In a real implementation, this would analyze policy choices for inherent tradeoffs
    // For now, we'll return some typical ethical tensions
    return [
      'Efficiency vs. Equity',
      'Individual Liberty vs. Collective Welfare',
      'Short-term Relief vs. Long-term Sustainability',
      'Innovation vs. Precaution',
      'Economic Growth vs. Environmental Protection',
      'Security vs. Privacy',
    ];
  }

  Map<String, List<String>> _generatePolicyRecommendations(
    Map<String, PolicyOption> humanSelections,
    Map<String, Map<String, PolicyOption>> aiSelections,
    Map<String, double> domainImpactScores,
  ) {
    if (humanSelections.isEmpty) {
      return {};
    }

    // In a real implementation, this would generate tailored recommendations
    // For now, we'll create generic recommendations based on domain
    final Map<String, List<String>> recommendations = {};
    
    humanSelections.forEach((domainId, option) {
      final List<String> domainRecommendations = [];
      final impactScore = domainImpactScores[domainId] ?? 50.0;
      
      if (domainId.contains('education')) {
        domainRecommendations.add('Consider increasing investment in teacher training programs to improve educational outcomes.');
        domainRecommendations.add('Expanding access to early childhood education could significantly improve long-term educational attainment.');
        
        if (impactScore < 60) {
          domainRecommendations.add('Your current education policy may benefit from additional resources to achieve better outcomes.');
        }
      } else if (domainId.contains('healthcare')) {
        domainRecommendations.add('Preventive care initiatives could reduce long-term healthcare costs while improving outcomes.');
        domainRecommendations.add('Consider policies that address healthcare access disparities across different communities.');
        
        if (impactScore < 60) {
          domainRecommendations.add('Your healthcare approach may need stronger implementation measures to achieve desired impact.');
        }
      } else if (domainId.contains('environment')) {
        domainRecommendations.add('Integrating environmental considerations across all policy domains could enhance sustainability.');
        domainRecommendations.add('Consider incentive structures that encourage private sector environmental innovation.');
        
        if (impactScore < 60) {
          domainRecommendations.add('Your environmental policy may benefit from more ambitious targets and implementation mechanisms.');
        }
      } else if (domainId.contains('economy')) {
        domainRecommendations.add('Consider how economic policies might be designed to benefit broader segments of the population.');
        domainRecommendations.add('Investments in workforce development could enhance economic resilience and adaptability.');
        
        if (impactScore < 60) {
          domainRecommendations.add('Your economic approach may benefit from additional measures to ensure balanced and inclusive growth.');
        }
      } else {
        domainRecommendations.add('Consider how this policy interacts with other domains to create synergistic effects.');
        domainRecommendations.add('Regular evaluation and adjustment of policy implementation could improve outcomes.');
        
        if (impactScore < 60) {
          domainRecommendations.add('This policy area may benefit from evidence-based adjustments to enhance impact.');
        }
      }
      
      recommendations[domainId] = domainRecommendations;
    });
    
    return recommendations;
  }

  Map<String, List<String>> _generateSentimentAnalysisInsights(
    List<MessageSentimentAnalysis> messageSentiments,
  ) {
    // In a real implementation, this would analyze sentiment patterns in the conversation
    // For now, we'll return generic insights
    return {
      'discussion_dynamics': [
        'The discussion showed significant engagement around environmental policies.',
        'There was notable hesitation when discussing economic tradeoffs.',
        'The conversation demonstrated a collaborative tone with minimal conflict.',
        'Key moments of consensus emerged around education and healthcare priorities.',
      ],
      'emotional_patterns': [
        'Discussions about equity showed higher emotional intensity.',
        'The conversation maintained a generally positive tone throughout.',
        'Discussions about budget constraints showed signs of concern and caution.',
        'Moments of policy alignment coincided with increased positive sentiment.',
      ],
      'ethical_considerations': [
        'The discussion frequently referenced fairness as a core value.',
        'Sustainability considerations appeared consistently across multiple policy domains.',
        'Tension between efficiency and inclusivity was evident in the dialogue.',
        'The group demonstrated shared concern for vulnerable populations.',
      ],
    };
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