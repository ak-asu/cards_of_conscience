import 'package:flutter/foundation.dart';

import '../../../models/enhanced_reflection_data.dart';
import '../../../providers/enhanced_reflection_provider.dart';
import '../../../services/chat_service.dart';

class ImpactDashboardController with ChangeNotifier {
  EnhancedReflectionData _enhancedData = EnhancedReflectionData();
  bool _isLoading = true;
  String? _error;
  
  EnhancedReflectionData get enhancedData => _enhancedData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final ChatService _chatService;
  
  ImpactDashboardController({required ChatService chatService})
      : _chatService = chatService {
    _init();
  }
  
  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load enhanced reflection data
      final dataProvider = EnhancedReflectionProvider(chatService: _chatService);
      
      if (dataProvider.error != null) {
        _error = dataProvider.error;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _enhancedData = dataProvider.enhancedData;
      
      // Prepare the data for visualization
      _processImpactData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load impact dashboard data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _processImpactData() {
    // This method would process the data for visualization
    // In a real implementation, it might:
    // 1. Create additional derived metrics
    // 2. Prepare time-series data for projections
    // 3. Calculate comparative data against benchmarks
    // 4. Generate recommendations based on findings
    
    // For now, we'll use the data as-is since our sample data already includes
    // what we need for the visualizations
  }
  
  void refreshData() {
    _init();
  }
  
  void selectTimeFrame(String timeFrame) {
    // This would adjust the data based on the selected time frame
    // e.g., 'Short-term', 'Medium-term', 'Long-term'
    
    // For demo purposes, we're not implementing the full functionality
    notifyListeners();
  }
  
  void toggleDataSeries(String seriesName, bool isVisible) {
    // This would toggle visibility of data series in charts
    // For demo purposes, we're not implementing the full functionality
    notifyListeners();
  }
  
  double getOverallImpactScore() {
    // Calculate an overall impact score across all domains
    double totalScore = 0;
    int count = 0;
    
    // Extract impact scores from policyImpacts if available
    final impacts = _enhancedData.policyImpacts;
    if (impacts.isNotEmpty) {
      impacts.forEach((domain, impact) {
        if (impact is Map<String, dynamic> && impact.containsKey('score')) {
          totalScore += (impact['score'] as num).toDouble();
          count++;
        } else if (impact is List && impact.isNotEmpty) {
          // Try to extract a score from the first item if it's a list
          final firstImpact = impact.first;
          if (firstImpact is Map<String, dynamic> && firstImpact.containsKey('score')) {
            totalScore += (firstImpact['score'] as num).toDouble();
            count++;
          }
        }
      });
    }
    
    return count > 0 ? totalScore / count : 0;
  }
  
  List<Map<String, dynamic>> getPolicyRecommendationDetails() {
    // Generate detailed recommendations based on the data
    final List<Map<String, dynamic>> recommendations = [];
    
    // Extract recommendations from justiceOrientedFeedback
    final recommendationList = _enhancedData.justiceOrientedFeedback['recommendations'] as List<dynamic>? ?? [];
    
    // Map each recommendation to our desired format
    for (var i = 0; i < recommendationList.length; i++) {
      final recommendation = recommendationList[i].toString();
      final domainId = _inferDomainFromRecommendation(recommendation);
      
      recommendations.add({
        'domainId': domainId,
        'domain': _formatDomainName(domainId),
        'recommendation': recommendation,
        'priority': _calculateRecommendationPriority(domainId, i),
      });
    }
    
    // Sort by priority (high to low)
    recommendations.sort((a, b) => b['priority'].compareTo(a['priority']));
    
    return recommendations;
  }
  
  String _inferDomainFromRecommendation(String recommendation) {
    // Infer domain from recommendation text
    // This is a simple implementation - in a real app you'd have more sophisticated logic
    final keywords = {
      'education': 'education_policy',
      'community': 'community_engagement',
      'policy': 'policy_governance',
      'metrics': 'impact_measurement',
      'implementation': 'implementation_strategy',
      'equity': 'equity_focus',
      'assessment': 'assessment_methodology',
      'resource': 'resource_allocation',
    };
    
    for (final entry in keywords.entries) {
      if (recommendation.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'general_recommendation';
  }
  
  String _formatDomainName(String domainId) {
    // Convert domain_id format to Domain Id format
    final words = domainId.split('_');
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
  
  int _calculateRecommendationPriority(String domainId, int index) {
    // Determine priority based on the domain and index in the list
    // Earlier items in the recommendation list get higher priority
    if (index < 2) {
      return 3; // High priority
    } else if (index < 4) {
      return 2; // Medium priority
    } else {
      return 1; // Low priority
    }
  }
}