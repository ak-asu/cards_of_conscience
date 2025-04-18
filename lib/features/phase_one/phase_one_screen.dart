import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../common/budget_indicator.dart';
import '../../common/custom_app_bar.dart';
import '../../common/policy_domain_group.dart';
import '../../core/snackbar_service.dart';
import '../../models/game_logger.dart';
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
  bool _showedTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showedTutorial) {
        _startTutorial();
      }
    });
  }

  void _startTutorial() {
    setState(() {
      _showedTutorial = true;
    });
    
    ShowCaseWidget.of(context).startShowCase([
      _budgetShowcaseKey,
      _domainShowcaseKey,
      _navigationShowcaseKey,
    ]);
  }

  void _handlePolicySelection(PolicyOption option) {
    final policySelectionProvider = Provider.of<PolicySelectionProvider>(context, listen: false);
    final policySelectionState = policySelectionProvider.state;
    final currentCost = policySelectionState.currentBudget;
    final existingCost = policySelectionState.selections[option.domain]?.cost ?? 0;
    final newCost = currentCost - existingCost + option.cost;
    
    if (newCost <= policySelectionState.maxBudget) {
      policySelectionProvider.selectPolicy(option);
      
      if (policySelectionState.selections.length < 7 && 
          policySelectionState.selections[option.domain] == null) {
        SnackBarService.showSuccessSnackBar(
          context, 
          'Selected "${option.title}" for ${option.cost} budget units'
        );
      }
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
                  'Select one policy option from each of the 7 domains while staying within your 14-unit budget.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Showcase(
                  key: _budgetShowcaseKey,
                  description: 'Monitor your budget here. You have a total of 14 units to allocate across all policy domains.',
                  child: BudgetIndicator(
                    currentBudget: policySelectionState.currentBudget,
                    maxBudget: policySelectionState.maxBudget,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: domains.length,
                itemBuilder: (context, index) {
                  final domain = domains[index];
                  return index == 0
                      ? Showcase(
                          key: _domainShowcaseKey,
                          description: 'Each policy domain has three options with different costs (1-3 units). Select one option per domain.',
                          child: PolicyDomainGroup(
                            domain: domain,
                            selectedPolicies: policySelectionState.selections,
                            onSelectPolicy: _canSelectPolicy(policySelectionState, domain.id)
                                ? _handlePolicySelection
                                : (option) {
                                    if (policySelectionState.remainingBudget < 1) {
                                      SnackBarService.showErrorSnackBar(
                                        context, 
                                        'Budget limit reached. Deselect something else first.'
                                      );
                                    }
                                  },
                            isDisabled: !_canSelectPolicy(policySelectionState, domain.id),
                          ),
                        )
                      : PolicyDomainGroup(
                          domain: domain,
                          selectedPolicies: policySelectionState.selections,
                          onSelectPolicy: _canSelectPolicy(policySelectionState, domain.id)
                              ? _handlePolicySelection
                              : (option) {
                                  if (policySelectionState.remainingBudget < 1) {
                                    SnackBarService.showErrorSnackBar(
                                      context, 
                                      'Budget limit reached. Deselect something else first.'
                                    );
                                  }
                                },
                          isDisabled: !_canSelectPolicy(policySelectionState, domain.id),
                        );
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
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
              description: 'You can proceed to the next phase only when you have selected one policy from each domain and stayed within your 14-unit budget.',
              child: ElevatedButton(
                onPressed: policySelectionState.isComplete
                    ? () {
                        // Log the game data before proceeding
                        final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context, listen: false);
                        if (!aiSelectionsProvider.isLoading) {
                          GameLogger.logGameSelections(
                            humanSelections: policySelectionState.selections,
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
      ),
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
}