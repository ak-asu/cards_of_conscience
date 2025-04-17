import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../reflective_feedback/models/enhanced_reflection_data.dart';
import '../charts/impact_charts.dart';
import '../controllers/impact_dashboard_controller.dart';

class ImpactDashboardScreen extends StatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ImpactDashboardController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (controller.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error Loading Impact Data',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text(
                        'Return to Reflection',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Impact Dashboard'),
            centerTitle: true,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.white),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.pie_chart),
                  text: 'Justice Index',
                ),
                Tab(
                  icon: Icon(Icons.bar_chart),
                  text: 'Outcomes',
                ),
                Tab(
                  icon: Icon(Icons.timeline),
                  text: 'Long-Term',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildJusticeIndexTab(controller.enhancedData),
              _buildOutcomesTab(controller.enhancedData),
              _buildLongTermTab(controller.enhancedData),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildJusticeIndexTab(EnhancedReflectionData data) {
    final justiceIndex = data.justiceIndex;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Justice Index Score',
            'Measures how well your policies align with justice principles',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreIndicator(
                        'Overall',
                        justiceIndex.overallScore,
                        AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  JusticeIndexRadarChart(justiceIndex: justiceIndex),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreIndicator(
                        'Inclusivity',
                        justiceIndex.inclusivityScore,
                        Colors.blue,
                      ),
                      _buildScoreIndicator(
                        'Equity',
                        justiceIndex.equityScore,
                        Colors.orange,
                      ),
                      _buildScoreIndicator(
                        'Sustainability',
                        justiceIndex.sustainabilityScore,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Ethical Tradeoffs',
            'Key ethical tensions in your policy choices',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: data.ethicalTradeoffs.map((tradeoff) => 
                  _buildTradeoffItem(tradeoff)
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Domain Impact Scores',
            'Overall impact of your selected policies by domain',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: data.domainImpactScores.entries.map((entry) =>
                  _buildDomainImpactItem(
                    _formatDomainName(entry.key),
                    entry.value,
                  )
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildOutcomesTab(EnhancedReflectionData data) {
    final impactMetrics = data.impactMetrics;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Immediate Policy Outcomes',
            'Short-term effects of your policy decisions',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImpactBarChart(
                metrics: impactMetrics.immediateOutcomes,
                title: 'Key Outcomes',
                barColor: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Social Impact Metrics',
            'Effects on social equity and community welfare',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImpactBarChart(
                metrics: impactMetrics.socialMetrics,
                title: 'Social Metrics',
                barColor: Colors.purple,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Policy Comparisons',
            'How your choices compare to alternative approaches',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ComparativeBarChart(
                comparativeData: _getComparativeData(data),
                categoryNames: const ['Your Choice', 'Average AI', 'Ideal'],
                barColors: const [Colors.blue, Colors.orange, Colors.green],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildLongTermTab(EnhancedReflectionData data) {
    final impactMetrics = data.impactMetrics;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Long-Term Impact Projections',
            'Projected effects over time (5-10 years)',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TimeSeriesLineChart(
                timeSeriesData: _getTimeSeriesData(data),
                title: 'Policy Impact Over Time',
                lineColors: const [Colors.blue, Colors.green, Colors.orange, Colors.purple],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Long-Term Domain Outcomes',
            'Specific long-term effects by policy domain',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImpactBarChart(
                metrics: impactMetrics.longTermImpacts,
                title: 'Long-Term Impacts',
                barColor: Colors.teal,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Sustainability Analysis',
            'How well your policies maintain benefits over time',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _getSustainabilityAnalysis(data).map((item) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item),
                        ),
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoreIndicator(
    String label,
    double score,
    Color color,
  ) {
    Color textColor;
    String evaluation;
    
    if (score >= 75) {
      textColor = Colors.green.shade700;
      evaluation = 'Excellent';
    } else if (score >= 60) {
      textColor = Colors.blue.shade700;
      evaluation = 'Good';
    } else if (score >= 40) {
      textColor = Colors.orange.shade700;
      evaluation = 'Fair';
    } else {
      textColor = Colors.red.shade700;
      evaluation = 'Poor';
    }
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '${score.round()}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          evaluation,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTradeoffItem(String tradeoff) {
    final parts = tradeoff.split(' vs. ');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                parts[0],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                parts.length > 1 ? parts[1] : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDomainImpactItem(String domain, double impact) {
    Color color;
    
    if (impact >= 75) {
      color = Colors.green.shade700;
    } else if (impact >= 60) {
      color = Colors.blue.shade700;
    } else if (impact >= 40) {
      color = Colors.orange.shade700;
    } else {
      color = Colors.red.shade700;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              domain,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: impact / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: color,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${impact.round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getImpactDescription(impact),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getImpactDescription(double impact) {
    if (impact >= 75) {
      return 'Highly impactful policy choice';
    } else if (impact >= 60) {
      return 'Significant positive impact';
    } else if (impact >= 40) {
      return 'Moderate impact';
    } else {
      return 'Limited impact';
    }
  }
  
  String _formatDomainName(String domainId) {
    // Convert domain_id format to Domain Id format
    final words = domainId.split('_');
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
  
  Map<String, List<double>> _getComparativeData(EnhancedReflectionData data) {
    // In a real implementation, this would calculate comparative data
    // Here we'll create simulated data for demonstration
    final Map<String, List<double>> result = {};
    
    // Simulated comparison data: [Your Choice, Avg AI, Ideal]
    data.humanSelections.forEach((domainId, policyOption) {
      final domainName = domainId.split('_').first;
      
      // Generate simulated values based on the user's choice
      final userValue = data.domainImpactScores[domainId] ?? 60.0;
      
      // AI average is somewhat similar but different
      final aiAverage = (userValue * 0.9) + (75 * 0.1); // Blend user value with 75%
      
      // Ideal is higher
      final ideal = userValue * 1.15;
      
      result[domainName] = [
        userValue,
        aiAverage,
        ideal > 100 ? 100 : ideal,
      ];
    });
    
    return result;
  }
  
  Map<String, Map<int, double>> _getTimeSeriesData(EnhancedReflectionData data) {
    // In a real implementation, this would calculate time-series projections
    // Here we'll create simulated data for visualization
    final Map<String, Map<int, double>> result = {};
    
    // Create time series data for a few key metrics
    result['Literacy'] = {
      1: 45.0,
      2: 52.0,
      3: 59.0,
      4: 64.0,
      5: 68.0,
    };
    
    result['Health'] = {
      1: 40.0,
      2: 48.0,
      3: 55.0,
      4: 63.0,
      5: 70.0,
    };
    
    result['Economy'] = {
      1: 35.0,
      2: 42.0,
      3: 51.0,
      4: 59.0,
      5: 65.0,
    };
    
    result['Environment'] = {
      1: 30.0,
      2: 38.0,
      3: 45.0,
      4: 54.0,
      5: 62.0,
    };
    
    return result;
  }
  
  List<String> _getSustainabilityAnalysis(EnhancedReflectionData data) {
    // In a real implementation, these would be calculated from policy choices
    return [
      'Your healthcare policies show strong sustainability, maintaining benefits for at least 8-10 years without significant additional investment.',
      'Educational initiatives will require incremental funding increases of approximately 5% every 3 years to maintain effectiveness.',
      'Environmental policies demonstrate excellent long-term value, with benefits potentially increasing over time as ecosystem restoration progresses.',
      'Economic policies may face sustainability challenges in years 4-5, potentially requiring policy adjustments to maintain positive trajectories.',
    ];
  }
}