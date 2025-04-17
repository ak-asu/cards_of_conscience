import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/scenario_models.dart';

class ScenarioIntroScreen extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onContinue;

  const ScenarioIntroScreen({
    super.key,
    required this.scenario,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScenarioHeader(context),
                    const SizedBox(height: 40),
                    _buildScenarioDetails(context),
                    const SizedBox(height: 40),
                    _buildGameplayEffects(context),
                    const SizedBox(height: 40),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'CRISIS SCENARIO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade300,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          scenario.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioDetails(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getScenarioIcon(scenario.crisisType),
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Situation Briefing',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              scenario.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildMostAffectedDomains(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMostAffectedDomains(BuildContext context) {
    // Get the most affected domains (those with highest modifiers)
    final sortedDomains = scenario.domainImpactModifiers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topThreeDomains = sortedDomains.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Affected Policy Areas:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topThreeDomains.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getColorForDomain(entry.key).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getColorForDomain(entry.key),
                ),
              ),
              child: Text(
                _formatDomainName(entry.key),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getColorForDomain(entry.key),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameplayEffects(BuildContext context) {
    return Card(
      elevation: 8,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Crisis Effects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEffectItem(
              context,
              Icons.account_balance_wallet,
              'Budget Modifier',
              'Your starting budget is adjusted by ${scenario.budgetModifier} units due to this crisis.',
              scenario.budgetModifier < 0 ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 12),
            _buildEffectItem(
              context,
              Icons.balance,
              'Justice Index',
              'The difficulty to achieve justice objectives is ${(scenario.justiceIndexDifficulty * 100 - 100).round()}% higher in this scenario.',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildEffectItem(
              context,
              Icons.content_paste,
              'Policy Cards',
              'Some policy costs and effects have been modified based on the crisis context.',
              AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            'Begin Crisis Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Option to select a different scenario
            // This could be implemented in a future version
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Feature Coming Soon'),
                content: const Text('Scenario selection will be available in a future update.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Choose a Different Scenario'),
        ),
      ],
    );
  }

  IconData _getScenarioIcon(CrisisType crisisType) {
    switch (crisisType) {
      case CrisisType.urbanRefugeeInflux:
        return Icons.location_city;
      case CrisisType.borderInstability:
        return Icons.security;
      case CrisisType.economicCollapse:
        return Icons.trending_down;
      case CrisisType.culturalConflict:
        return Icons.people;
    }
  }

  Color _getColorForDomain(String domainId) {
    switch (domainId) {
      case 'economy':
        return Colors.green;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.blue;
      case 'environment':
        return Colors.teal;
      case 'immigration':
        return Colors.orange;
      case 'criminal_justice':
        return Colors.purple;
      case 'defense':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDomainName(String domainId) {
    // Convert domain_id to Domain Id format
    final words = domainId.split('_');
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}