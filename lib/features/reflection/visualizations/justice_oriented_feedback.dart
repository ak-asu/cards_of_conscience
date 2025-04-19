import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../models/enhanced_reflection_data.dart';

class JusticeOrientedFeedback extends StatelessWidget {
  const JusticeOrientedFeedback({super.key});

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
          'Error loading justice feedback: ${reflectionData.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final justiceFeedback = reflectionData.justiceOrientedFeedback;
    final educationalTheory = reflectionData.educationalTheoryConnections;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Justice-Oriented Reflection',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildJusticeFeedbackCard(context, justiceFeedback),
            const SizedBox(height: 32),
            _buildEducationalTheorySection(context, educationalTheory),
            const SizedBox(height: 32),
            _buildJusticeFrameworksCard(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJusticeFeedbackCard(BuildContext context, Map<String, dynamic> justiceFeedback) {
    final overallAssessment = justiceFeedback['overallAssessment'] as String? ??
        'No justice assessment available.';
    final strengths = justiceFeedback['strengths'] as List? ?? [];
    final challenges = justiceFeedback['challenges'] as List? ?? [];
    final recommendations = justiceFeedback['recommendations'] as List? ?? [];
    
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.balance,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Justice Assessment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              overallAssessment,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 300), duration: const Duration(milliseconds: 500)),
            const SizedBox(height: 24),
            
            _buildJusticeFeedbackSection(
              context,
              'Strengths',
              strengths,
              Icons.check_circle_outline,
              Colors.green,
              300,
            ),
            const SizedBox(height: 16),
            
            _buildJusticeFeedbackSection(
              context,
              'Challenges',
              challenges,
              Icons.warning_amber_outlined,
              Colors.orange,
              600,
            ),
            const SizedBox(height: 16),
            
            _buildJusticeFeedbackSection(
              context,
              'Recommendations',
              recommendations,
              Icons.lightbulb_outline,
              Colors.purple,
              900,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJusticeFeedbackSection(
    BuildContext context,
    String title,
    List items,
    IconData icon,
    Color color,
    int delayMillis,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No $title available',
            style: const TextStyle(fontStyle: FontStyle.italic),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(items[index].toString()),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: delayMillis + (index * 100)),
                    duration: const Duration(milliseconds: 500),
                  );
            },
          ),
      ],
    );
  }

  Widget _buildEducationalTheorySection(BuildContext context, Map<String, dynamic> educationalTheory) {
    final connections = educationalTheory['connections'] as List? ?? [];
    
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
                  Icons.school,
                  color: Colors.indigo,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Educational Theory Connections',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your policy choices can be analyzed through various educational theory lenses to understand their implications:',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            if (connections.isEmpty)
              const Text(
                'No educational theory connections available',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  final theory = connections[index];
                  final theoryName = theory['theory'] ?? 'Unknown Theory';
                  final connection = theory['connection'] ?? 'No connection specified';
                  final impact = theory['impact'] ?? 'Unknown impact';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo,
                            ),
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Connection:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(connection),
                          const SizedBox(height: 12),
                          const Text(
                            'Potential Impact:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(impact),
                          const SizedBox(height: 16),
                          _buildTheoryResourceLink(context, theoryName),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 300 + (index * 200)),
                        duration: const Duration(milliseconds: 500),
                      );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTheoryResourceLink(BuildContext context, String theoryName) {
    final bool hasResource = _getTheoryResourceUrl(theoryName).isNotEmpty;
    
    return hasResource
        ? OutlinedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Learn More'),
            onPressed: () {
              // In a real implementation, this would open a URL or detailed explanation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Resource for $theoryName would open here'),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
  
  String _getTheoryResourceUrl(String theoryName) {
    final Map<String, String> theoryResources = {
      'Critical Pedagogy': 'https://example.com/critical-pedagogy',
      'Social Justice Education': 'https://example.com/social-justice-education',
      'Culturally Responsive Teaching': 'https://example.com/culturally-responsive',
      'Transformative Learning': 'https://example.com/transformative-learning',
    };
    
    return theoryResources[theoryName] ?? '';
  }
  
  Widget _buildJusticeFrameworksCard(BuildContext context) {
    final List<Map<String, dynamic>> justiceFrameworks = [
      {
        'name': 'Redistributive Justice',
        'description': 'Focuses on the fair distribution of resources, opportunities, and burdens in society.',
        'icon': Icons.equalizer,
        'color': Colors.green,
      },
      {
        'name': 'Recognition Justice',
        'description': 'Addresses the need to recognize and respect cultural differences and identities.',
        'icon': Icons.visibility,
        'color': Colors.purple,
      },
      {
        'name': 'Procedural Justice',
        'description': 'Ensures fair and transparent decision-making processes that involve all affected parties.',
        'icon': Icons.account_balance,
        'color': Colors.blue,
      },
      {
        'name': 'Restorative Justice',
        'description': 'Repairs harm caused by injustice through reconciliation and community involvement.',
        'icon': Icons.healing,
        'color': Colors.orange,
      },
    ];
    
    return Card(
      elevation: 3,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: Colors.deepPurple,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Justice Frameworks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Understanding different justice frameworks can help you evaluate your policy decisions from multiple perspectives:',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: justiceFrameworks.length,
              itemBuilder: (context, index) {
                final framework = justiceFrameworks[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: framework['color'].withOpacity(0.2),
                    child: Icon(
                      framework['icon'],
                      color: framework['color'],
                    ),
                  ),
                  title: Text(
                    framework['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(framework['description']),
                  contentPadding: EdgeInsets.zero,
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 300 + (index * 200)),
                      duration: const Duration(milliseconds: 500),
                    );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reflect on which justice frameworks guided your policy choices, and which ones might have been overlooked.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
                  delay: const Duration(milliseconds: 1200),
                  duration: const Duration(milliseconds: 500),
                ),
          ],
        ),
      ),
    );
  }
}