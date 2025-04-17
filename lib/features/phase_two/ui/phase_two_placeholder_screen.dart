import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../phase_one/models/agent_model.dart';
import '../../phase_one/models/game_logger.dart';
import '../../phase_one/providers/policy_selection_provider.dart';

class PhaseTwoPlaceholderScreen extends StatefulWidget {
  const PhaseTwoPlaceholderScreen({super.key});

  @override
  State<PhaseTwoPlaceholderScreen> createState() => _PhaseTwoPlaceholderScreenState();
}

class _PhaseTwoPlaceholderScreenState extends State<PhaseTwoPlaceholderScreen> {
  bool _hasLoggedSelections = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logSelections();
    });
  }

  Future<void> _logSelections() async {
    if (!_hasLoggedSelections) {
      final policySelectionProvider = Provider.of<PolicySelectionProvider>(context, listen: false);
      final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context, listen: false);
      
      if (!aiSelectionsProvider.isLoading) {
        final aiSelections = aiSelectionsProvider.aiSelections;
        await GameLogger.logGameSelections(
          humanSelections: policySelectionProvider.state.selections,
          aiSelections: aiSelections,
        );
        
        setState(() {
          _hasLoggedSelections = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context);
    final agentsProvider = Provider.of<AgentsProvider>(context);
    
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cards of Conscience'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Phase 2: Group Discussion',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature will be implemented in the next version.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your selections have been saved, and AI diplomats have made their choices.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                _buildSelectionInfo(context, aiSelectionsProvider),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => context.go('/reflection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Continue to Reflection Phase',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/phase1'),
                  child: const Text('Return to Phase 1'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectionInfo(BuildContext context, AISelectionsProvider aiSelectionsProvider) {
    if (aiSelectionsProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (aiSelectionsProvider.error != null) {
      return Text('Error: ${aiSelectionsProvider.error}');
    }
    
    final aiSelections = aiSelectionsProvider.aiSelections;
    
    return Column(
      children: [
        Text(
          'Your AI counterparts have made ${aiSelections.length} policy sets.',
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        if (_hasLoggedSelections)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Game data has been logged successfully.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 24),
        _buildDiplomatsList(context),
      ],
    );
  }
  
  Widget _buildDiplomatsList(BuildContext context) {
    final agentsProvider = Provider.of<AgentsProvider>(context);
    
    if (agentsProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (agentsProvider.error != null) {
      return Text('Failed to load diplomats: ${agentsProvider.error}');
    }
    
    final agents = agentsProvider.agents;
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    if (diplomats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meet Your AI Diplomats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...diplomats.map((diplomat) => _buildDiplomatTile(diplomat)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiplomatTile(Agent diplomat) {
    final IconData iconData = _getDiplomatIcon(diplomat.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _getDiplomatColor(diplomat.id).withOpacity(0.2),
            child: Icon(iconData, color: _getDiplomatColor(diplomat.id)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diplomat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  diplomat.occupation,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  diplomat.perspective ?? 'Unknown perspective',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Risk tolerance: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      diplomat.riskTolerance ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRiskToleranceColor(diplomat.riskTolerance),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getDiplomatIcon(String diplomatId) {
    switch (diplomatId) {
      case 'diplomat1':
        return Icons.diversity_3;
      case 'diplomat2':
        return Icons.balance;
      case 'diplomat3':
        return Icons.lightbulb;
      case 'diplomat4':
        return Icons.people;
      default:
        return Icons.person;
    }
  }
  
  Color _getDiplomatColor(String diplomatId) {
    switch (diplomatId) {
      case 'diplomat1':
        return Colors.purple;
      case 'diplomat2':
        return Colors.blue;
      case 'diplomat3':
        return Colors.orange;
      case 'diplomat4':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  Color _getRiskToleranceColor(String? riskTolerance) {
    if (riskTolerance == null) return Colors.grey;
    
    if (riskTolerance.toLowerCase().contains('high')) {
      return Colors.red;
    } else if (riskTolerance.toLowerCase().contains('moderate')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}