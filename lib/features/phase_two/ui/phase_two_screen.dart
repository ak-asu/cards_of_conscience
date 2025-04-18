import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import '../../../common/custom_app_bar.dart';
import '../../../core/app_theme.dart';
import '../../../models/agent_model.dart' show Agent;
import '../../../models/game_logger.dart' show GameLogger;
import '../../../models/policy_models.dart' show PolicyDomain;
import '../../../providers/policy_selection_provider.dart';
import '../ai_enhancements/negotiation_provider.dart';
import '../group_comm/services/chat_service.dart';
import '../group_comm/text_chat/text_chat_interface.dart';
import '../group_comm/transcript_viewer/transcript_viewer.dart';

class PhaseTwoScreen extends StatefulWidget {
  const PhaseTwoScreen({super.key});

  @override
  State<PhaseTwoScreen> createState() => _PhaseTwoScreenState();
}

class _PhaseTwoScreenState extends State<PhaseTwoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasCompletedOnboarding = false;
  bool _isShowingTranscript = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logSelections();
      _checkOnboardingStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logSelections() async {
    final policySelectionProvider = Provider.of<PolicySelectionProvider>(context, listen: false);
    final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context, listen: false);
    
    if (!aiSelectionsProvider.isLoading) {
      final aiSelections = aiSelectionsProvider.aiSelections;
      await GameLogger.logGameSelections(
        humanSelections: policySelectionProvider.state.selections,
        aiSelections: aiSelections,
      );
    }
  }

  Future<void> _checkOnboardingStatus() async {
    // In a real implementation, this would check local storage to see if
    // the user has already completed the onboarding for Phase 2
    // For now, we'll just show it every time
    _showOnboarding();
  }

  void _showOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: IntroductionScreen(
            pages: [
              PageViewModel(
                title: 'Welcome to Group Discussion',
                body: "In this phase, you'll engage in real-time discussion with AI diplomats to find common ground on policies.",
                image: Center(
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 120,
                    color: AppTheme.primaryColor,
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
                ),
                decoration: const PageDecoration(
                  titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  bodyTextStyle: TextStyle(fontSize: 16),
                ),
              ),
              PageViewModel(
                title: 'Text Chat',
                body: 'Communicate with diplomats using text messages. Each diplomat has unique perspectives based on their profile.',
                image: Center(
                  child: const Icon(
                    Icons.chat, 
                    size: 80, 
                    color: Colors.blue
                  ).animate().fadeIn(duration: 400.ms).slideX(),
                ),
                decoration: const PageDecoration(
                  titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  bodyTextStyle: TextStyle(fontSize: 16),
                ),
              ),
              PageViewModel(
                title: 'View the Transcript',
                body: 'Toggle between the active chat and the full transcript to review the discussion history at any time.',
                image: Center(
                  child: const Icon(
                    Icons.article_outlined,
                    size: 100,
                    color: Colors.orange,
                  ).animate().fadeIn(duration: 400.ms),
                ),
                decoration: const PageDecoration(
                  titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  bodyTextStyle: TextStyle(fontSize: 16),
                ),
              ),
              PageViewModel(
                title: 'Negotiation Rounds',
                body: 'Diplomats go through claim, counterclaim, and rebuttal phases for each policy domain. Your input influences the discussion flow.',
                image: Center(
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.light_mode, size: 50, color: Colors.amber),
                          SizedBox(height: 8),
                          Text('Claim'),
                        ],
                      ),
                      Icon(Icons.arrow_forward, size: 30),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.compare_arrows, size: 50, color: Colors.blue),
                          SizedBox(height: 8),
                          Text('Counterclaim'),
                        ],
                      ),
                      Icon(Icons.arrow_forward, size: 30),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, size: 50, color: Colors.purple),
                          SizedBox(height: 8),
                          Text('Rebuttal'),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                ),
                decoration: const PageDecoration(
                  titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  bodyTextStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
            onDone: () {
              setState(() => _hasCompletedOnboarding = true);
              Navigator.of(context).pop();
            },
            showSkipButton: true,
            skip: const Text('Skip'),
            next: const Text('Next'),
            done: const Text('Begin Discussion', style: TextStyle(fontWeight: FontWeight.bold)),
            dotsDecorator: DotsDecorator(
              size: const Size.square(10.0),
              activeSize: const Size(20.0, 10.0),
              activeColor: AppTheme.primaryColor,
              spacing: const EdgeInsets.symmetric(horizontal: 3.0),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => EnhancedNegotiationProvider()),
      ],
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Group Discussion',
          additionalActions: [
            IconButton(
              icon: Icon(_isShowingTranscript ? Icons.chat : Icons.article_outlined),
              tooltip: _isShowingTranscript ? 'Return to Chat' : 'View Transcript',
              onPressed: () {
                setState(() {
                  _isShowingTranscript = !_isShowingTranscript;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Tutorial',
              onPressed: _showOnboarding,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildDiplomatBar(context),
              _buildNegotiationStatus(context),
              Expanded(
                child: _isShowingTranscript
                    ? const TranscriptViewer().animate().fadeIn(duration: 300.ms)
                    : const TextChatInterface().animate().fadeIn(duration: 300.ms),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).colorScheme.surface,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Phase 1'),
                  onPressed: () => context.go('/phase1'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Continue to Reflection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => context.go('/reflection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiplomatBar(BuildContext context) {
    final agentsProvider = Provider.of<AgentsProvider>(context);
    
    if (agentsProvider.isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (agentsProvider.error != null) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Failed to load diplomats')),
      );
    }
    
    final agents = agentsProvider.agents;
    final List<Agent> diplomats = agents.where((agent) => agent.id.startsWith('diplomat')).toList();
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: diplomats.length,
        itemBuilder: (context, index) {
          final diplomat = diplomats[index];
          return _buildDiplomatChip(context, diplomat);
        },
      ),
    );
  }

  Widget _buildDiplomatChip(BuildContext context, Agent diplomat) {
    final Color diplomatColor = _getDiplomatColor(diplomat.id);
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDiplomatDetails(context, diplomat),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: diplomatColor.withOpacity(0.2),
                  child: Icon(
                    _getDiplomatIcon(diplomat.id),
                    color: diplomatColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diplomat.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: diplomatColor,
                      ),
                    ),
                    Text(
                      diplomat.occupation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: const Duration(milliseconds: 1 * 100)); // agent index * 100
  }

  void _showDiplomatDetails(BuildContext context, Agent diplomat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _getDiplomatColor(diplomat.id).withOpacity(0.2),
                    child: Icon(
                      _getDiplomatIcon(diplomat.id),
                      color: _getDiplomatColor(diplomat.id),
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diplomat.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          diplomat.occupation,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Age: ${diplomat.age}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Education: ${diplomat.education}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Socioeconomic Status: ${diplomat.socioeconomicStatus}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Perspective',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                diplomat.perspective ?? 'No specific perspective',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Ideological Leanings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                diplomat.ideology.isNotEmpty ? diplomat.ideology : 'Balanced',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Risk Tolerance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                diplomat.riskTolerance ?? 'Moderate',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _getRiskToleranceColor(diplomat.riskTolerance),
                ),
              ),
              const SizedBox(height: 24),
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

  Widget _buildNegotiationStatus(BuildContext context) {
    final negotiationProvider = Provider.of<EnhancedNegotiationProvider>(context);
    
    if (negotiationProvider.isLoading) {
      return const LinearProgressIndicator();
    }
    
    if (!negotiationProvider.isNegotiating || negotiationProvider.currentTopicId == null) {
      return const SizedBox.shrink();
    }
    
    final currentTopic = negotiationProvider.currentTopic;
    if (currentTopic == null) return const SizedBox.shrink();
    
    // Get the domain for the current topic
    final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context);
    final domain = policyDomainsProvider.domains.firstWhere(
      (d) => d.id == currentTopic.domainId,
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown Domain', description: 'Unknown', options: []),
    );
    
    // Calculate negotiation stage
    final hasCounterclaims = currentTopic.messages.any((m) => m.stage == NegotiationStage.counterclaim);
    final hasRebuttals = currentTopic.messages.any((m) => m.stage == NegotiationStage.rebuttal);
    final hasConclusions = currentTopic.messages.any((m) => m.stage == NegotiationStage.conclusion);
    
    int currentStage = 1; // Initial claims
    if (hasConclusions) {
      currentStage = 4;
    } else if (hasRebuttals) {
      currentStage = 3;
    } else if (hasCounterclaims) {
      currentStage = 2;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.topic,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Topic: ${domain.name}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Topic'),
                onPressed: () {
                  final agentsProvider = Provider.of<AgentsProvider>(context, listen: false);
                  negotiationProvider.moveToNextTopic(agentsProvider.agents, policyDomainsProvider.domains);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discussion Stage:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: currentStage / 4,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _getNegotiationStageName(currentStage),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getNegotiationStageName(int stage) {
    switch (stage) {
      case 1: return 'Initial Claims';
      case 2: return 'Counterclaims';
      case 3: return 'Rebuttals';
      case 4: return 'Conclusions';
      default: return 'Discussion';
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
}