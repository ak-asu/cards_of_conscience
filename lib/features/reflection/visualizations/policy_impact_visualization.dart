import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/enhanced_reflection_data.dart';
import '../../../core/app_theme.dart';

class PolicyImpactVisualization extends StatelessWidget {
  const PolicyImpactVisualization({super.key});

  @override
  Widget build(BuildContext context) {
    final reflectionData = Provider.of<EnhancedReflectionData>(context);
    
    if (reflectionData.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (reflectionData.error.isNotEmpty) {
      return Center(
        child: Text(
          'Error loading policy impact data: ${reflectionData.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    
    final policyImpacts = reflectionData.policyImpacts;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Policy Impact Projections',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTimeframeImpacts(
              context,
              'Short-Term Impacts',
              policyImpacts['shortTermImpacts'] as List? ?? [],
              Colors.blue,
              Colors.blue.shade100,
              Icons.access_time,
              '0-1 Years',
            ),
            const SizedBox(height: 24),
            _buildTimeframeImpacts(
              context,
              'Medium-Term Impacts',
              policyImpacts['mediumTermImpacts'] as List? ?? [],
              Colors.green,
              Colors.green.shade100,
              Icons.calendar_today,
              '1-3 Years',
            ),
            const SizedBox(height: 24),
            _buildTimeframeImpacts(
              context,
              'Long-Term Impacts',
              policyImpacts['longTermImpacts'] as List? ?? [],
              Colors.purple,
              Colors.purple.shade100,
              Icons.trending_up,
              '3+ Years',
            ),
            const SizedBox(height: 32),
            _buildStakeholderImpacts(context, policyImpacts),
            const SizedBox(height: 32),
            _buildSustainabilityAssessment(context, policyImpacts),
            const SizedBox(height: 24),
            _buildTradeoffAnalysis(context, reflectionData.ethicalAnalysis),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeframeImpacts(
    BuildContext context,
    String title,
    List impacts,
    Color color,
    Color backgroundColor,
    IconData icon,
    String timeframe,
  ) {
    if (impacts.isEmpty) {
      return Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No $title data available'),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      timeframe,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...impacts.asMap().entries.map((entry) {
              final index = entry.key;
              final impact = entry.value;
              
              final domain = impact['domain'] as String? ?? 'Unknown Domain';
              final description = impact['description'] as String? ?? 'No description available';
              final magnitude = impact['magnitude'] as double? ?? 0.5;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Impact: '),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: magnitude,
                            backgroundColor: Colors.grey.shade300,
                            color: color,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(magnitude * 100).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: const Duration(milliseconds: 500),
                  );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStakeholderImpacts(BuildContext context, Map<String, dynamic> policyImpacts) {
    final stakeholderImpacts = policyImpacts['stakeholderImpacts'] as Map<String, dynamic>? ?? {};
    
    if (stakeholderImpacts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No stakeholder impact data available'),
        ),
      );
    }
    
    final stakeholders = {
      'refugees': {
        'icon': Icons.group,
        'color': Colors.orange,
        'title': 'Refugees',
      },
      'hostCommunity': {
        'icon': Icons.home,
        'color': Colors.teal,
        'title': 'Host Community',
      },
      'educators': {
        'icon': Icons.school,
        'color': Colors.indigo,
        'title': 'Educators',
      },
      'government': {
        'icon': Icons.account_balance,
        'color': Colors.brown,
        'title': 'Government',
      },
    };
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.people_alt,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Stakeholder Impacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...stakeholders.entries.map((entry) {
              final stakeholderId = entry.key;
              final stakeholderData = entry.value;
              final impacts = stakeholderImpacts[stakeholderId] as List? ?? [];
              
              if (impacts.isEmpty) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stakeholderData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (stakeholderData['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          stakeholderData['icon'] as IconData,
                          color: stakeholderData['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stakeholderData['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: stakeholderData['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...impacts.map((impact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            color: (stakeholderData['color'] as Color),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(impact.toString()),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: stakeholders.keys.toList().indexOf(stakeholderId) * 200),
                    duration: const Duration(milliseconds: 500),
                  );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSustainabilityAssessment(BuildContext context, Map<String, dynamic> policyImpacts) {
    final sustainabilityAssessment = policyImpacts['sustainabilityAssessment'] as Map<String, dynamic>? ?? {};
    
    if (sustainabilityAssessment.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No sustainability assessment data available'),
        ),
      );
    }
    
    final financial = sustainabilityAssessment['financial'] as double? ?? 0.5;
    final institutional = sustainabilityAssessment['institutional'] as double? ?? 0.5;
    final social = sustainabilityAssessment['social'] as double? ?? 0.5;
    final description = sustainabilityAssessment['description'] as String? ?? 'No sustainability description available';
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Sustainability Assessment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.5,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 5,
                  titlePositionPercentageOffset: 0.2,
                  dataSets: [
                    RadarDataSet(
                      fillColor: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      entryRadius: 3,
                      dataEntries: [
                        RadarEntry(value: financial * 10),
                        RadarEntry(value: institutional * 10),
                        RadarEntry(value: social * 10),
                      ],
                    ),
                  ],
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titleTextStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
                  gridBorderData: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return RadarChartTitle(text: 'Financial\nSustainability', angle: angle);
                      case 1:
                        return RadarChartTitle(text: 'Institutional\nSustainability', angle: angle);
                      case 2:
                        return RadarChartTitle(text: 'Social\nSustainability', angle: angle);
                      default:
                        return RadarChartTitle(text: '', angle: angle);
                    }
                  },
                ),
              ),
            ).animate().scale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 16),
            _buildSustainabilityLegend(financial, institutional, social),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSustainabilityLegend(double financial, double institutional, double social) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Financial', financial, Colors.green),
        _buildLegendItem('Institutional', institutional, Colors.green),
        _buildLegendItem('Social', social, Colors.green),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 800));
  }
  
  Widget _buildLegendItem(String label, double value, Color color) {
    final formattedValue = (value * 100).toInt();
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$formattedValue%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTradeoffAnalysis(BuildContext context, Map<String, dynamic> ethicalAnalysis) {
    final tradeoffs = ethicalAnalysis['ethicalTradeoffs'] as List? ?? [];
    
    if (tradeoffs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No ethical tradeoff data available'),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.balance,
                  color: Colors.deepPurple,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Ethical Tradeoffs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your policy choices involve balancing different values and priorities. Here are the key ethical tradeoffs:',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            ...tradeoffs.asMap().entries.map((entry) {
              final index = entry.key;
              final tradeoff = entry.value as Map<String, dynamic>;
              
              final description = tradeoff['description'] as String? ?? 'No description available';
              final impactedGroups = tradeoff['impactedGroups'] as List? ?? [];
              final justiceImplications = tradeoff['justiceImplications'] as String? ?? 'No justice implications available';
              final alternativeApproach = tradeoff['alternativeApproach'] as String? ?? 'No alternative approach suggested';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepPurple.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tradeoff ${index + 1}: $description',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (impactedGroups.isNotEmpty) ...[
                      const Text(
                        'Impacted Groups:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: impactedGroups.map((group) => Chip(
                          label: Text(group.toString()),
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                          side: BorderSide(
                            color: Colors.deepPurple.withOpacity(0.3),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Justice Implications:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(justiceImplications),
                    const SizedBox(height: 12),
                    const Text(
                      'Alternative Approach:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(alternativeApproach),
                  ],
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 200 * index),
                    duration: const Duration(milliseconds: 500),
                  );
            }),
          ],
        ),
      ),
    );
  }
}