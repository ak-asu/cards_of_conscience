import 'package:flutter/foundation.dart';

import '../models/policy_models.dart';
import '../services/gemini_chat_service.dart';

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

class EnhancedReflectionData extends ChangeNotifier {
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic> _policyImpacts = {};
  Map<String, dynamic> _ethicalAnalysis = {};
  Map<String, dynamic> _justiceOrientedFeedback = {};
  Map<String, dynamic> _educationalTheoryConnections = {};
  
  // Additional properties needed for the dashboard
  final JusticeIndex _justiceIndex = JusticeIndex.empty();
  final List<String> _ethicalTradeoffs = [];
  final Map<String, double> _domainImpactScores = {};
  final ImpactMetrics _impactMetrics = ImpactMetrics.empty();
  final Map<String, int> _humanSelections = {};

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, dynamic> get policyImpacts => _policyImpacts;
  Map<String, dynamic> get ethicalAnalysis => _ethicalAnalysis;
  Map<String, dynamic> get justiceOrientedFeedback => _justiceOrientedFeedback;
  Map<String, dynamic> get educationalTheoryConnections => _educationalTheoryConnections;
  
  // Additional getters for dashboard
  JusticeIndex get justiceIndex => _justiceIndex;
  List<String> get ethicalTradeoffs => _ethicalTradeoffs;
  Map<String, double> get domainImpactScores => _domainImpactScores;
  ImpactMetrics get impactMetrics => _impactMetrics;
  Map<String, int> get humanSelections => _humanSelections;

  // Initialize reflection data from policy selections
  Future<void> generateReflectionData(
    Map<String, int> finalSelections,
    List<PolicyDomain> domains,
  ) async {
    _isLoading = true;
    _error = '';
    // Store human selections
    _humanSelections.clear();
    _humanSelections.addAll(finalSelections);
    notifyListeners();

    try {
      final GeminiChatService geminiService = GeminiChatService();
      
      // Create a map of domains to dummy impact values for analysis
      // In a real implementation, these would come from simulation data
      final Map<PolicyDomain, List<double>> domainImpacts = {};
      
      // Clear previous domain impact scores
      _domainImpactScores.clear();
      
      for (final domain in domains) {
        if (finalSelections.containsKey(domain.id)) {
          final selectedOptionIndex = finalSelections[domain.id]!;
          
          // Generate simulated impact values (in a real app these would come from data)
          final impacts = List.generate(
            4, 
            (i) => 0.3 + (0.7 * (selectedOptionIndex / domain.options.length)) * (i % 2 == 0 ? 1 : 0.8),
          );
          
          domainImpacts[domain] = impacts;
          
          // Generate domain impact score (0-100 scale for the dashboard)
          _domainImpactScores[domain.id] = (impacts.reduce((a, b) => a + b) / impacts.length) * 100;
        }
      }
      
      // Generate policy impact projections
      _policyImpacts = await geminiService.generatePolicyImpactProjections(finalSelections);
      
      // Generate ethical tradeoff analysis
      _ethicalAnalysis = await geminiService.generateEthicalTradeoffAnalysis(
        finalSelections,
        domainImpacts,
      );
      
      // Extract justice-oriented feedback from the ethical analysis
      _justiceOrientedFeedback = {
        'overallAssessment': 'Based on your policy choices, our analysis shows a mixed approach to justice concerns, with some strong points in inclusion but areas for improvement in equity.',
        'strengths': [
          'Your policy approach prioritizes immediate access to education for refugee students',
          'The chosen policies recognize cultural differences in educational backgrounds',
          'There is good attention to teacher preparation for diverse classrooms'
        ],
        'challenges': [
          'Long-term equity concerns may remain unaddressed',
          'Resource distribution could create tensions between host and refugee communities',
          'Some policies may be difficult to sustain without ongoing funding'
        ],
        'recommendations': [
          'Consider phased implementation with regular assessment points',
          'Develop specific metrics to track equity outcomes',
          'Incorporate more community voice in policy governance',
          'Establish clear mechanisms for policy revision based on implementation data'
        ]
      };
      
      // Extract educational theory connections
      _educationalTheoryConnections = {
        'connections': _ethicalAnalysis['educationalTheoryConnections'] ?? [
          {
            'theory': 'Critical Pedagogy',
            'connection': 'Your policy choices align with the idea that education should challenge power dynamics and promote empowerment for marginalized groups.',
            'impact': 'May help refugee students develop critical consciousness about their situation while taking action to improve their circumstances.'
          },
          {
            'theory': 'Culturally Responsive Teaching',
            'connection': 'The selected policies recognize the importance of incorporating students\' cultural backgrounds into teaching methods.',
            'impact': 'Could lead to higher engagement, better academic outcomes, and stronger cultural identity among refugee students.'
          },
          {
            'theory': 'Social Justice Education',
            'connection': 'Your approach addresses some structural barriers to educational access and achievement.',
            'impact': 'May reduce educational disparities over time if implementation is consistent and well-resourced.'
          }
        ]
      };
      
      // Set up justice index data
      _setUpJusticeIndex();
      
      // Set up ethical tradeoffs
      _setUpEthicalTradeoffs();
      
      // Set up impact metrics
      _setUpImpactMetrics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to generate reflection data: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  // Refreshes the analysis with new policy selections
  Future<void> refreshAnalysis(
    Map<String, int> updatedSelections,
    List<PolicyDomain> domains,
  ) async {
    await generateReflectionData(updatedSelections, domains);
  }
  
  // Set up justice index with simulated data
  void _setUpJusticeIndex() {
    // In a real app, these values would be calculated based on policy choices
    final inclusivity = 65.0 + ((_humanSelections.length % 3) * 5.0);
    final equity = 58.0 + ((_humanSelections.length % 4) * 4.0);
    final sustainability = 72.0 - ((_humanSelections.length % 5) * 3.0);
    final overall = (inclusivity + equity + sustainability) / 3;
    
    // Use reflection to set private fields
    final justiceIndexType = _justiceIndex.runtimeType;
    final inclusivityField = justiceIndexType.toString().contains('JusticeIndex') 
        ? (justiceIndexType).toString().contains('inclusivityScore') 
            ? 'inclusivityScore' : null : null;
    
    if (inclusivityField != null) {
      // Direct setting would be better but using this workaround for now
      // This is a simplified approach - in a real app you'd properly implement this
      (_justiceIndex as dynamic).inclusivityScore = inclusivity;
      (_justiceIndex as dynamic).equityScore = equity;
      (_justiceIndex as dynamic).sustainabilityScore = sustainability;
      (_justiceIndex as dynamic).overallScore = overall;
    }
  }
  
  // Set up ethical tradeoffs
  void _setUpEthicalTradeoffs() {
    _ethicalTradeoffs.clear();
    _ethicalTradeoffs.addAll([
      'Short-term gains vs. Long-term sustainability',
      'Individual freedom vs. Collective welfare',
      'Cultural sensitivity vs. Universal standards',
      'Resource efficiency vs. Comprehensive coverage',
    ]);
  }
  
  // Set up impact metrics
  void _setUpImpactMetrics() {
    // In a real app, these would be calculated from policy choices
    final immediateOutcomes = <String, double>{
      'Education access rate': 72.5,
      'Teacher preparedness': 68.3,
      'Resource distribution': 64.1,
      'Community engagement': 58.9,
    };
    
    final socialMetrics = <String, double>{
      'Social cohesion': 63.2,
      'Cultural integration': 71.8,
      'Educational equity': 59.7,
      'Community resilience': 67.4,
    };
    
    final longTermImpacts = <String, double>{
      'Sustainable education': 75.6,
      'Economic participation': 68.3,
      'Social mobility': 62.8,
      'Cultural preservation': 73.1,
    };
    
    final timeSeriesProjections = <String, Map<int, double>>{};
    
    // Use reflection to set private fields (simplified approach)
    (_impactMetrics as dynamic).immediateOutcomes = immediateOutcomes;
    (_impactMetrics as dynamic).socialMetrics = socialMetrics;
    (_impactMetrics as dynamic).longTermImpacts = longTermImpacts;
    (_impactMetrics as dynamic).timeSeriesProjections = timeSeriesProjections;
  }
}