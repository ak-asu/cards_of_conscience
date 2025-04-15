import 'package:flutter/foundation.dart';

import '../models/agent_model.dart';
import '../models/agent_service.dart';
import '../models/data_service.dart';
import '../models/policy_models.dart';

class PolicySelectionState {
  final Map<String, PolicyOption> selections;
  final int maxBudget;

  PolicySelectionState({
    Map<String, PolicyOption>? selections,
    this.maxBudget = 14,
  }) : selections = selections ?? {};

  int get currentBudget {
    int total = 0;
    for (var option in selections.values) {
      total += option.cost;
    }
    return total;
  }

  int get remainingBudget => maxBudget - currentBudget;

  bool get isComplete {
    return selections.length == 7 && currentBudget <= maxBudget;
  }

  PolicySelectionState copyWith({
    Map<String, PolicyOption>? selections,
    int? maxBudget,
  }) {
    return PolicySelectionState(
      selections: selections ?? Map.from(this.selections),
      maxBudget: maxBudget ?? this.maxBudget,
    );
  }

  PolicySelectionState addOrUpdateSelection(PolicyOption option) {
    final newSelections = Map<String, PolicyOption>.from(selections);
    newSelections[option.domain] = option;
    return copyWith(selections: newSelections);
  }

  PolicySelectionState removeSelection(String domain) {
    final newSelections = Map<String, PolicyOption>.from(selections);
    newSelections.remove(domain);
    return copyWith(selections: newSelections);
  }
}

class PolicyDomainsProvider with ChangeNotifier {
  List<PolicyDomain> _domains = [];
  bool _isLoading = true;
  String? _error;

  List<PolicyDomain> get domains => _domains;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PolicyDomainsProvider() {
    loadPolicyDomains();
  }

  Future<void> loadPolicyDomains() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _domains = await DataService.loadPolicyData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load policy domains: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}

class AgentsProvider with ChangeNotifier {
  List<Agent> _agents = [];
  bool _isLoading = true;
  String? _error;

  List<Agent> get agents => _agents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AgentsProvider() {
    loadAgents();
  }

  Future<void> loadAgents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _agents = await DataService.loadAgentData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load agents: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}

class PolicySelectionProvider with ChangeNotifier {
  PolicySelectionState _state = PolicySelectionState();
  
  PolicySelectionState get state => _state;
  
  void selectPolicy(PolicyOption option) {
    final currentCost = _state.currentBudget;
    final newCost = currentCost - (_state.selections[option.domain]?.cost ?? 0) + option.cost;
    
    if (newCost <= _state.maxBudget) {
      _state = _state.addOrUpdateSelection(option);
      notifyListeners();
    }
  }

  void removePolicy(String domain) {
    _state = _state.removeSelection(domain);
    notifyListeners();
  }

  void resetSelections() {
    _state = PolicySelectionState();
    notifyListeners();
  }
}

class AISelectionsProvider with ChangeNotifier {
  final PolicyDomainsProvider _policyDomainsProvider;
  final AgentsProvider _agentsProvider;
  
  List<Agent> _aiAgentsWithSelections = [];
  Map<String, Map<String, PolicyOption>> _aiSelections = {};
  bool _isLoading = true;
  String? _error;
  
  AISelectionsProvider(this._policyDomainsProvider, this._agentsProvider) {
    generateSelections();
  }
  
  List<Agent> get aiAgentsWithSelections => _aiAgentsWithSelections;
  Map<String, Map<String, PolicyOption>> get aiSelections => _aiSelections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> generateSelections() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Wait until both policy domains and agents are loaded
      if (_policyDomainsProvider.isLoading || _agentsProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        return generateSelections();
      }
      
      if (_policyDomainsProvider.error != null || _agentsProvider.error != null) {
        _error = _policyDomainsProvider.error ?? _agentsProvider.error;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final domains = _policyDomainsProvider.domains;
      final agents = _agentsProvider.agents;
      
      _aiAgentsWithSelections = AgentService.generateRandomSelections(agents, domains, 14);
      
      _aiSelections = {};
      for (var agent in _aiAgentsWithSelections) {
        _aiSelections[agent.id] = agent.selections;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to generate AI selections: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}