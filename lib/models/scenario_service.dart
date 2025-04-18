import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'scenario_models.dart';

class ScenarioService {
  static Scenario? _currentScenario;
  static List<Scenario>? _availableScenarios;
  
  static Scenario? get currentScenario => _currentScenario;
  static List<Scenario>? get availableScenarios => _availableScenarios;
  
  static Future<void> initialize() async {
    if (_availableScenarios == null) {
      await _loadScenariosFromJson();
    }
  }
  
  static Future<void> _loadScenariosFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/scenario_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _availableScenarios = [];
      
      for (var scenarioJson in jsonData) {
        final String crisisTypeStr = scenarioJson['crisisType'];
        final CrisisType crisisType = CrisisType.values.firstWhere(
          (e) => e.toString().split('.').last == crisisTypeStr,
          orElse: () => CrisisType.urbanRefugeeInflux,
        );
        
        final List<ScenarioEffect> effects = [];
        for (var effectJson in scenarioJson['effects']) {
          final String policyDomainId = effectJson['policyDomainId'];
          final Map<String, dynamic> policyEffectsJson = effectJson['policyEffects'];
          
          final Map<String, PolicyEffectModifier> policyEffects = {};
          policyEffectsJson.forEach((policyId, modifierJson) {
            policyEffects[policyId] = PolicyEffectModifier(
              costMultiplier: modifierJson['costMultiplier'] ?? 1.0,
              riskFactor: modifierJson['riskFactor'] ?? 1.0,
              rewardFactor: modifierJson['rewardFactor'] ?? 1.0,
              modifiedDescription: modifierJson['modifiedDescription'] ?? '',
            );
          });
          
          effects.add(ScenarioEffect(
            policyDomainId: policyDomainId,
            policyEffects: policyEffects,
          ));
        }        
        final Map<String, double> domainImpactModifiers = {};
        final domainImpactJson = scenarioJson['domainImpactModifiers'];
        if (domainImpactJson != null) {
          domainImpactJson.forEach((domain, modifier) {
            domainImpactModifiers[domain] = modifier.toDouble();
          });
        }        
        final scenario = Scenario(
          crisisType: crisisType,
          title: scenarioJson['title'],
          description: scenarioJson['description'],
          imagePath: scenarioJson['imagePath'],
          budgetModifier: scenarioJson['budgetModifier'] ?? 0,
          justiceIndexDifficulty: scenarioJson['justiceIndexDifficulty'] ?? 1.0,
          effects: effects,
          domainImpactModifiers: domainImpactModifiers,
        );        
        _availableScenarios!.add(scenario);
      }
    } catch (e) {
      print('Error loading scenarios from JSON: $e');
    }
  }
  
  static Future<Scenario> generateRandomScenario() async {
    await initialize();
    
    final Random random = Random();
    final availableScenarios = _availableScenarios ?? [];
    final Scenario scenario = availableScenarios[random.nextInt(availableScenarios.length)];
    
    _currentScenario = scenario;
    return _currentScenario!;
  }
  
  static Future<Scenario> selectScenario(CrisisType crisisType) async {
    await initialize();
    
    final availableScenarios = _availableScenarios ?? [];
    final Scenario scenario = availableScenarios.firstWhere(
      (s) => s.crisisType == crisisType,
      //orElse: () => _createScenarioByType(crisisType),
    );
    
    _currentScenario = scenario;
    return _currentScenario!;
  }
  
  static Future<Scenario> selectScenarioById(String id) async {
    await initialize();    
    final availableScenarios = _availableScenarios ?? [];
    final Scenario? scenario = availableScenarios.cast<Scenario?>().firstWhere(
      (s) => (s as Scenario).title.toLowerCase().contains(id.toLowerCase()),
      orElse: () => null,
    );    
    _currentScenario = scenario;
    return _currentScenario!;
  }
  
  static void resetScenario() {
    _currentScenario = null;
  }
  
  // static Scenario _createScenarioByType(CrisisType crisisType) {
  //   switch (crisisType) {
  //     case CrisisType.urbanRefugeeInflux:
  //       return _createUrbanRefugeeScenario();
  //     case CrisisType.borderInstability:
  //       return _createBorderInstabilityScenario();
  //     case CrisisType.economicCollapse:
  //       return _createEconomicCollapseScenario();
  //     case CrisisType.culturalConflict:
  //       return _createCulturalConflictScenario();
  //   }
  // }
}