import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../common/budget_indicator.dart';
import '../../common/custom_app_bar.dart';
import '../../common/policy_domain_group.dart';
import '../../core/snackbar_service.dart';
import '../../utils/game_logger.dart';
import '../../models/policy_models.dart';
import '../../providers/policy_selection_provider.dart';

class PhaseOneScreen extends StatefulWidget {
  const PhaseOneScreen({super.key});

  @override
  State<PhaseOneScreen> createState() => _PhaseOneScreenState();
}

class _PhaseOneScreenState extends State<PhaseOneScreen> {
  final GlobalKey _budgetShowcaseKey = GlobalKey();
  final GlobalKey _domainShowcaseKey = GlobalKey();
  final GlobalKey _navigationShowcaseKey = GlobalKey();
  final GlobalKey _tabBarShowcaseKey = GlobalKey();
  bool _showedTutorial = false;
  int _selectedDomainIndex = 0;
  final Map<int, double> _scrollPositions = {};
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showedTutorial) {
        _startTutorial();
      }
    });
  }

  @override
  void dispose() {
    _scrollControllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _startTutorial() {
    setState(() {
      _showedTutorial = true;
    });
    
    ShowCaseWidget.of(context).startShowCase([
      _budgetShowcaseKey,
      _domainShowcaseKey,
      _tabBarShowcaseKey,
      _navigationShowcaseKey,
    ]);
  }

  ScrollController _getScrollController(int index) {
    if (!_scrollControllers.containsKey(index)) {
      _scrollControllers[index] = ScrollController(
        initialScrollOffset: _scrollPositions[index] ?? 0,
      );
      
      _scrollControllers[index]!.addListener(() {
        _scrollPositions[index] = _scrollControllers[index]!.offset;
      });
    }
    return _scrollControllers[index]!;
  }

  void _handlePolicySelection(PolicyOption option) {
    final policySelectionProvider = Provider.of<PolicySelectionProvider>(context, listen: false);
    final policySelectionState = policySelectionProvider.state;
    final currentCost = policySelectionState.currentBudget;
    final existingCost = policySelectionState.selections[option.domain]?.cost ?? 0;
    final newCost = currentCost - existingCost + option.cost;
    
    if (newCost <= policySelectionState.maxBudget) {
      policySelectionProvider.selectPolicy(option);
    } else {
      SnackBarService.showErrorSnackBar(
        context, 
        'Not enough budget to select this option. You need to deselect something else first.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cards of Conscience',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _startTutorial,
          ),
        ],
      ),
      body: ShowCaseWidget(
        builder: _buildBody,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context);
    final policySelectionProvider = Provider.of<PolicySelectionProvider>(context);
    final policySelectionState = policySelectionProvider.state;

    if (policyDomainsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (policyDomainsProvider.error != null) {
      return Center(child: Text('Error: ${policyDomainsProvider.error}'));
    }

    final domains = policyDomainsProvider.domains;
    
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phase 1: Individual Decision Making',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select policy options from different domains while staying within your 14-unit budget.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Showcase(
                  key: _budgetShowcaseKey,
                  description: 'Monitor your budget here. You have a total of 14 units to allocate across policy domains.',
                  child: BudgetIndicator(
                    currentBudget: policySelectionState.currentBudget,
                    maxBudget: policySelectionState.maxBudget,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: domains.isEmpty 
              ? const Center(child: Text('No policy domains available'))
              : _buildDomainView(domains, policySelectionState),
          ),
          _buildBottomBar(domains, policySelectionState),
        ],
      ),
    );
  }

  Widget _buildDomainView(List<PolicyDomain> domains, PolicySelectionState state) {
    if (_selectedDomainIndex >= domains.length) {
      _selectedDomainIndex = 0;
    }
    
    final domain = domains[_selectedDomainIndex];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Showcase(
        key: _domainShowcaseKey,
        description: 'Each policy domain has options with different costs (1-3 units). Select options that align with your priorities.',
        child: SingleChildScrollView(
          controller: _getScrollController(_selectedDomainIndex),
          child: PolicyDomainGroup(
            domain: domain,
            selectedPolicies: state.selections,
            onSelectPolicy: _canSelectPolicy(state, domain.id)
                ? _handlePolicySelection
                : (option) {
                    if (state.remainingBudget < 1) {
                      SnackBarService.showErrorSnackBar(
                        context, 
                        'Budget limit reached. Deselect something else first.'
                      );
                    }
                  },
            isDisabled: !_canSelectPolicy(state, domain.id),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<PolicyDomain> domains, PolicySelectionState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Showcase(
          key: _tabBarShowcaseKey,
          description: 'Navigate between policy domains using these tabs. Selected domains are highlighted.',
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(domains.length, (index) {
                  final domain = domains[index];
                  final isSelected = _selectedDomainIndex == index;
                  final hasSelection = state.selections.containsKey(domain.id);
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDomainIndex = index;
                      });
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Icon(
                                _getIconForDomain(domain.id),
                                color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : hasSelection 
                                    ? _getColorForDomain(domain.id) 
                                    : Colors.grey,
                                size: 28,
                              ),
                              if (hasSelection)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getShortDomainName(domain.id),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).primaryColor : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Showcase(
            key: _navigationShowcaseKey,
            description: 'You can proceed to the next phase once you have selected at least one policy.',
            child: ElevatedButton(
              onPressed: state.selections.isNotEmpty
                  ? () {
                      // Log the game data before proceeding
                      final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context, listen: false);
                      if (!aiSelectionsProvider.isLoading) {
                        GameLogger.logGameSelections(
                          humanSelections: state.selections,
                          aiSelections: aiSelectionsProvider.aiSelections,
                        );
                      }
                      context.go('/phase2');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Proceed to Group Discussion',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canSelectPolicy(PolicySelectionState state, String domainId) {
    if (state.selections.containsKey(domainId)) {
      return true;
    }
    
    if (state.remainingBudget < 1) {
      return false;
    }
    
    return true;
  }
  
  IconData _getIconForDomain(String domainId) {
    switch (domainId) {
      case 'economy':
        return Icons.attach_money;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'environment':
        return Icons.eco;
      case 'immigration':
        return Icons.public;
      case 'criminal_justice':
        return Icons.balance;
      case 'defense':
        return Icons.security;
      default:
        return Icons.policy;
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
  
  String _getShortDomainName(String domainId) {
    switch (domainId) {
      case 'criminal_justice':
        return 'Justice';
      case 'environment':
        return 'Environ';
      case 'immigration':
        return 'Immigr';
      default:
        // Format the domain ID (convert snake_case to Title Case)
        final words = domainId.split('_');
        return words.first[0].toUpperCase() + words.first.substring(1);
    }
  }
}