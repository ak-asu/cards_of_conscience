import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common_widgets/custom_app_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../phase_two/group_comm/services/chat_service.dart';
import '../../impact_dashboard/controllers/impact_dashboard_controller.dart';
import '../../impact_dashboard/ui/impact_dashboard_screen.dart';
import '../models/enhanced_reflection_data.dart';
import '../providers/enhanced_reflection_provider.dart';

class EnhancedReflectionScreen extends StatelessWidget {
  const EnhancedReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EnhancedReflectionProvider(
        chatService: Provider.of<ChatService>(context, listen: false),
      ),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Advanced Reflection',
        ),
        body: Consumer<EnhancedReflectionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing policy decisions and dialogue...',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
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
                        'Error Loading Reflection Data',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go('/phase1'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text(
                          'Start New Game',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = provider.enhancedData;
            return _buildReflectionContent(context, data);
          },
        ),
      ),
    );
  }

  Widget _buildReflectionContent(BuildContext context, EnhancedReflectionData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJusticeIndexSummary(context, data),
          const SizedBox(height: 24),
          _buildEthicalTradeoffsSummary(context, data),
          const SizedBox(height: 24),
          _buildSentimentAnalysisSummary(context, data),
          const SizedBox(height: 24),
          _buildPolicyRecommendationsSummary(context, data),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToImpactDashboard(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text(
                'View Impact Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildJusticeIndexSummary(BuildContext context, EnhancedReflectionData data) {
    final justiceIndex = data.justiceIndex;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.balance_outlined,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Justice Index',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your decisions have earned an overall Justice Index score of ${justiceIndex.overallScore.round()}/100.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _getJusticeIndexDescription(justiceIndex.overallScore),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricPill('Inclusivity', justiceIndex.inclusivityScore, Colors.blue),
                _buildMetricPill('Equity', justiceIndex.equityScore, Colors.orange),
                _buildMetricPill('Sustainability', justiceIndex.sustainabilityScore, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEthicalTradeoffsSummary(BuildContext context, EnhancedReflectionData data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows,
                  color: Colors.deepPurple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Key Ethical Tensions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your policy choices involved these fundamental ethical tradeoffs:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...data.ethicalTradeoffs.take(3).map((tradeoff) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tradeoff,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data.ethicalTradeoffs.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${data.ethicalTradeoffs.length - 3} more tradeoffs',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentAnalysisSummary(BuildContext context, EnhancedReflectionData data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conversation Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI analysis of your discussion with diplomats revealed:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (data.sentimentAnalysisInsights.containsKey('discussion_dynamics'))
              ...data.sentimentAnalysisInsights['discussion_dynamics']!.take(2).map((insight) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.chat_outlined,
                        color: Colors.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(insight),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (data.sentimentAnalysisInsights.containsKey('emotional_patterns'))
              ...data.sentimentAnalysisInsights['emotional_patterns']!.take(1).map((insight) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.mood_outlined,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(insight),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyRecommendationsSummary(BuildContext context, EnhancedReflectionData data) {
    final recommendations = data.policyRecommendations;
    if (recommendations.isEmpty) return const SizedBox.shrink();
    
    // Get just one domain's recommendations for the summary screen
    final sampleDomain = recommendations.keys.first;
    final sampleRecommendations = recommendations[sampleDomain]!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Policy Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'For ${_formatDomainName(sampleDomain)}:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...sampleRecommendations.take(2).map((recommendation) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(recommendation),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommendations available for ${recommendations.length} policy domains.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, double score, Color color) {
    final scoreRounded = score.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$scoreRounded',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getJusticeIndexDescription(double score) {
    if (score >= 85) {
      return 'Your policy choices demonstrate exceptional attention to justice principles, balancing inclusivity, equity, and sustainability.';
    } else if (score >= 70) {
      return 'Your policies show strong alignment with justice principles, with good balance across multiple dimensions.';
    } else if (score >= 50) {
      return 'Your policy choices reflect moderate attention to justice concerns, with room for improvement in balancing various interests.';
    } else {
      return 'Your policies may benefit from greater consideration of justice principles, particularly in terms of inclusivity and long-term sustainability.';
    }
  }

  String _formatDomainName(String domainId) {
    final words = domainId.split('_');
    return words.map((word) => word.isNotEmpty 
      ? '${word[0].toUpperCase()}${word.substring(1)}' 
      : '').join(' ');
  }

  void _navigateToImpactDashboard(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ImpactDashboardController(chatService: chatService),
          child: const ImpactDashboardScreen(),
        ),
      ),
    );
  }
}