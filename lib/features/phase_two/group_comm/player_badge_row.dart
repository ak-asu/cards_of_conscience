import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/agent_model.dart';
import '../../../models/policy_models.dart';
import 'policy_card_mini.dart';

class PlayerBadgeRow extends StatelessWidget {
  final List<Agent> agents;
  final Map<String, Map<String, int>> aiSelections;
  final Map<String, PolicyOption> userSelections;
  
  const PlayerBadgeRow({
    super.key,
    required this.agents,
    required this.aiSelections,
    required this.userSelections,
  });

  @override
  Widget build(BuildContext context) {
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: AI diplomats
          Expanded(
            child: Row(
              children: diplomats.map((diplomat) => 
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildAgentBadge(context, diplomat),
                ).animate().fadeIn(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: diplomats.indexOf(diplomat) * 100),
                ),
              ).toList(),
            ),
          ),
          
          // Right side: User
          _buildUserBadge(context),
        ],
      ),
    );
  }
  
  Widget _buildAgentBadge(BuildContext context, Agent agent) {
    final color = _getDiplomatColor(agent.id);
    
    return Tooltip(
      message: agent.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showAgentDetailsDialog(context, agent),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.2),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getDiplomatIcon(agent.id),
                  color: color,
                  size: 24,
                ),
              ),
              // Badge showing number of selected policies
              if (aiSelections.containsKey(agent.id))
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${aiSelections[agent.id]?.length ?? 0}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserBadge(BuildContext context) {
    return Tooltip(
      message: 'You',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showUserDetailsDialog(context),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade100,
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              if (userSelections.isNotEmpty)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${userSelections.length}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAgentDetailsDialog(BuildContext context, Agent agent) {
    // Filter selections for this agent
    final agentSelections = <PolicyOption>[];
    
    if (aiSelections.containsKey(agent.id)) {
      // Look up actual policy options based on domain and option index
      final Map<String, int> selections = aiSelections[agent.id]!;
      
      // We need to convert the domain -> index selections to actual PolicyOption objects
      // This would require access to the actual policy domain data
      // For now, we create placeholder policies
      selections.forEach((domainId, optionIndex) {
        agentSelections.add(PolicyOption(
          id: '$domainId-$optionIndex',
          domain: domainId,
          title: 'Option $optionIndex for ${_formatDomainName(domainId)}',
          description: 'Policy selected by diplomat',
          cost: 1 + (optionIndex % 3), // Mock cost between 1-3
          impacts: [],
        ));
      });
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _getDiplomatColor(agent.id).withOpacity(0.2),
                    child: Icon(
                      _getDiplomatIcon(agent.id),
                      color: _getDiplomatColor(agent.id),
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          agent.occupation,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Age: ${agent.age}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (agent.education.isNotEmpty) Text(
                          'Education: ${agent.education}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (agent.socioeconomicStatus.isNotEmpty) Text(
                          'Status: ${agent.socioeconomicStatus}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (agent.perspective != null && agent.perspective!.isNotEmpty) ...[
                Text(
                  'Perspective',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(agent.perspective!),
                const SizedBox(height: 16),
              ],
              if (agent.riskTolerance != null) ...[
                Text(
                  'Risk Tolerance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  agent.riskTolerance ?? 'Moderate',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _getRiskToleranceColor(agent.riskTolerance),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Selected Policies',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              agentSelections.isEmpty
                  ? const Text('No policies selected yet.')
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: agentSelections.map((policy) => 
                            SizedBox(
                              width: 160,
                              child: PolicyCardMini(
                                policy: policy,
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showUserDetailsDialog(BuildContext context) {
    final userPolicies = userSelections.values.toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Card Selector',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Your Selected Policies',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              userPolicies.isEmpty
                  ? const Text('No policies selected yet.')
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: userPolicies.map((policy) => 
                            SizedBox(
                              width: 160,
                              child: PolicyCardMini(
                                policy: policy,
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  
  String _formatDomainName(String domainId) {
    final words = domainId.split('_');
    return words.map((word) => word.isNotEmpty 
        ? '${word[0].toUpperCase()}${word.substring(1)}' 
        : '').join(' ');
  }
}