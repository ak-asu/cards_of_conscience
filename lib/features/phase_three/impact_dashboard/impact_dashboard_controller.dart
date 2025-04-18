import 'package:flutter/foundation.dart';

import '../../../models/enhanced_reflection_data.dart';
import '../../../services/chat_service.dart';

class ImpactDashboardController with ChangeNotifier {
  EnhancedReflectionData _enhancedData = EnhancedReflectionData.empty();
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
      final dataProvider = EnhancedReflectionDataProvider(chatService: _chatService);
      await dataProvider.loadEnhancedReflectionData();
      
      if (dataProvider.error != null) {
        _error = dataProvider.error;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _enhancedData = dataProvider.reflectionData;
      
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
    
    _enhancedData.domainImpactScores.forEach((domain, score) {
      totalScore += score;
      count++;
    });
    
    return count > 0 ? totalScore / count : 0;
  }
  
  List<Map<String, dynamic>> getPolicyRecommendationDetails() {
    // Generate detailed recommendations based on the data
    final List<Map<String, dynamic>> recommendations = [];
    
    _enhancedData.policyRecommendations.forEach((domainId, domainRecommendations) {
      for (var recommendation in domainRecommendations) {
        recommendations.add({
          'domainId': domainId,
          'domain': _formatDomainName(domainId),
          'recommendation': recommendation,
          'priority': _calculateRecommendationPriority(domainId),
        });
      }
    });
    
    // Sort by priority (high to low)
    recommendations.sort((a, b) => b['priority'].compareTo(a['priority']));
    
    return recommendations;
  }
  
  String _formatDomainName(String domainId) {
    // Convert domain_id format to Domain Id format
    final words = domainId.split('_');
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
  
  int _calculateRecommendationPriority(String domainId) {
    // Determine priority based on impact scores and justice index
    // Higher priority for domains with lower impact or justice scores
    final domainScore = _enhancedData.domainImpactScores[domainId] ?? 50;
    
    if (domainScore < 40) {
      return 3; // High priority
    } else if (domainScore < 60) {
      return 2; // Medium priority
    } else {
      return 1; // Low priority
    }
  }
}