import 'dart:math';

import 'scenario_models.dart';

class ScenarioService {
  static Scenario? _currentScenario;
  
  static Scenario? get currentScenario => _currentScenario;
  
  static Future<Scenario> generateRandomScenario() async {
    final Random random = Random();
    final crisisValues = CrisisType.values;
    final CrisisType crisisType = crisisValues[random.nextInt(crisisValues.length)];
    
    _currentScenario = _createScenarioByType(crisisType);
    return _currentScenario!;
  }
  
  static Future<Scenario> selectScenario(CrisisType crisisType) async {
    _currentScenario = _createScenarioByType(crisisType);
    return _currentScenario!;
  }
  
  static void resetScenario() {
    _currentScenario = null;
  }
  
  static Scenario _createScenarioByType(CrisisType crisisType) {
    switch (crisisType) {
      case CrisisType.urbanRefugeeInflux:
        return _createUrbanRefugeeScenario();
      case CrisisType.borderInstability:
        return _createBorderInstabilityScenario();
      case CrisisType.economicCollapse:
        return _createEconomicCollapseScenario();
      case CrisisType.culturalConflict:
        return _createCulturalConflictScenario();
    }
  }
  
  static Scenario _createUrbanRefugeeScenario() {
    return Scenario(
      crisisType: CrisisType.urbanRefugeeInflux,
      title: 'Urban Refugee Crisis',
      description: 'A sudden influx of refugees from neighboring regions has led to overcrowding and strain on city resources. Housing shortages, healthcare demands, and cultural tensions are rising in urban centers. Political pressure is mounting from all sides as humanitarian concerns compete with resource limitations.',
      imagePath: 'assets/images/scenarios/urban_refugee.jpg',
      budgetModifier: -2, // Reduced budget due to emergency resource allocation
      justiceIndexDifficulty: 1.2, // Higher difficulty to achieve justice goals
      effects: [
        ScenarioEffect(
          policyDomainId: 'immigration',
          policyEffects: {
            'immigration_1': PolicyEffectModifier(
              costMultiplier: 1.5,
              riskFactor: 1.8,
              rewardFactor: 0.7,
              modifiedDescription: 'Heightened enforcement is more costly and risks humanitarian concerns',
            ),
            'immigration_2': PolicyEffectModifier(
              costMultiplier: 1.2,
              rewardFactor: 1.4,
              modifiedDescription: 'Reform now has greater potential impact but requires more resources',
            ),
            'immigration_3': PolicyEffectModifier(
              costMultiplier: 0.8,
              riskFactor: 1.2,
              rewardFactor: 1.6,
              modifiedDescription: 'Greater humanitarian benefits but political tensions may escalate',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'healthcare',
          policyEffects: {
            'healthcare_1': PolicyEffectModifier(
              costMultiplier: 1.2,
              riskFactor: 1.5,
              rewardFactor: 0.8,
              modifiedDescription: 'Insurance markets are strained by unexpected demand',
            ),
            'healthcare_3': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 0.9,
              rewardFactor: 1.3,
              modifiedDescription: 'Universal systems can better absorb sudden population increases',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'criminal_justice',
          policyEffects: {
            'criminal_justice_1': PolicyEffectModifier(
              costMultiplier: 1.3,
              riskFactor: 1.4,
              rewardFactor: 0.7,
              modifiedDescription: 'Increased policing costs due to population density and tensions',
            ),
            'criminal_justice_3': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 0.8,
              rewardFactor: 1.4,
              modifiedDescription: 'Community services approach more effective with diverse populations',
            ),
          },
        ),
      ],
      domainImpactModifiers: {
        'immigration': 1.5,
        'healthcare': 1.3,
        'education': 1.2,
        'criminal_justice': 1.3,
        'economy': 0.9,
        'defense': 0.8,
        'environment': 0.7,
      },
    );
  }
  
  static Scenario _createBorderInstabilityScenario() {
    return Scenario(
      crisisType: CrisisType.borderInstability,
      title: 'Border Region Instability',
      description: 'Ongoing conflicts in neighboring nations have created a volatile border situation. Security concerns are escalating alongside humanitarian needs as displaced populations seek safety. Military resources are stretched thin while border communities face economic disruption and safety concerns.',
      imagePath: 'assets/images/scenarios/border_instability.jpg',
      budgetModifier: -1, // Slightly reduced budget due to military deployments
      justiceIndexDifficulty: 1.3, // Higher difficulty to balance security and humanitarian concerns
      effects: [
        ScenarioEffect(
          policyDomainId: 'defense',
          policyEffects: {
            'defense_1': PolicyEffectModifier(
              costMultiplier: 1.5,
              riskFactor: 1.7,
              rewardFactor: 0.6,
              modifiedDescription: 'Focused strategy insufficient for widespread border challenges',
            ),
            'defense_2': PolicyEffectModifier(
              costMultiplier: 1.2,
              riskFactor: 0.9,
              rewardFactor: 1.3,
              modifiedDescription: 'Diplomatic solutions more effective during regional instability',
            ),
            'defense_3': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 0.7,
              rewardFactor: 1.5,
              modifiedDescription: 'Expanded capabilities better address multi-faceted threats',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'immigration',
          policyEffects: {
            'immigration_1': PolicyEffectModifier(
              costMultiplier: 1.4,
              riskFactor: 1.3,
              rewardFactor: 0.9,
              modifiedDescription: 'Border enforcement challenges escalate with regional instability',
            ),
            'immigration_2': PolicyEffectModifier(
              costMultiplier: 1.1,
              riskFactor: 0.8,
              rewardFactor: 1.4,
              modifiedDescription: 'Balanced approach more effective during complex crises',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'economy',
          policyEffects: {
            'economy_1': PolicyEffectModifier(
              costMultiplier: 1.3,
              riskFactor: 1.5,
              rewardFactor: 0.7,
              modifiedDescription: 'Deregulation risks exploitation during border instability',
            ),
            'economy_3': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 0.8,
              rewardFactor: 1.3,
              modifiedDescription: 'Infrastructure investments stabilize border economies',
            ),
          },
        ),
      ],
      domainImpactModifiers: {
        'defense': 1.6,
        'immigration': 1.5,
        'economy': 1.2,
        'criminal_justice': 1.3,
        'healthcare': 1.0,
        'education': 0.8,
        'environment': 0.7,
      },
    );
  }
  
  static Scenario _createEconomicCollapseScenario() {
    return Scenario(
      crisisType: CrisisType.economicCollapse,
      title: 'Economic System Failure',
      description: 'A massive financial crisis has triggered widespread economic instability. Unemployment is soaring, industries are failing, and public confidence in economic institutions is at an all-time low. The government faces difficult choices between austerity and stimulus as social safety nets are strained to breaking point.',
      imagePath: 'assets/images/scenarios/economic_collapse.jpg',
      budgetModifier: -3, // Significantly reduced budget due to revenue collapse
      justiceIndexDifficulty: 1.4, // Much harder to achieve justice during economic crisis
      effects: [
        ScenarioEffect(
          policyDomainId: 'economy',
          policyEffects: {
            'economy_1': PolicyEffectModifier(
              costMultiplier: 0.8,
              riskFactor: 1.9,
              rewardFactor: 1.8,
              modifiedDescription: 'Deregulation is cheaper but extremely risky during market failure',
            ),
            'economy_2': PolicyEffectModifier(
              costMultiplier: 1.2,
              riskFactor: 0.9,
              rewardFactor: 1.4,
              modifiedDescription: 'Targeted incentives more effective during sector-specific downturns',
            ),
            'economy_3': PolicyEffectModifier(
              costMultiplier: 1.5,
              riskFactor: 0.7,
              rewardFactor: 1.6,
              modifiedDescription: 'Infrastructure investments provide needed economic stimulus',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'healthcare',
          policyEffects: {
            'healthcare_1': PolicyEffectModifier(
              costMultiplier: 1.3,
              riskFactor: 1.8,
              rewardFactor: 0.6,
              modifiedDescription: 'Private insurance markets struggle during economic downturns',
            ),
            'healthcare_3': PolicyEffectModifier(
              costMultiplier: 1.4,
              riskFactor: 0.8,
              rewardFactor: 1.3,
              modifiedDescription: 'Universal system stabilizes healthcare access during crisis',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'education',
          policyEffects: {
            'education_1': PolicyEffectModifier(
              costMultiplier: 1.2,
              riskFactor: 1.6,
              rewardFactor: 0.7,
              modifiedDescription: 'School choice systems struggle with reduced funding',
            ),
            'education_3': PolicyEffectModifier(
              costMultiplier: 1.5,
              riskFactor: 0.9,
              rewardFactor: 1.4,
              modifiedDescription: 'Free education becomes crucial during economic hardship',
            ),
          },
        ),
      ],
      domainImpactModifiers: {
        'economy': 1.8,
        'healthcare': 1.4,
        'education': 1.3,
        'criminal_justice': 1.2,
        'immigration': 0.9,
        'defense': 0.7,
        'environment': 0.8,
      },
    );
  }
  
  static Scenario _createCulturalConflictScenario() {
    return Scenario(
      crisisType: CrisisType.culturalConflict,
      title: 'Cultural Identity Crisis',
      description: 'Rapid societal changes have triggered deep cultural divisions across the nation. Traditional values are clashing with progressive ideals, while demographic shifts fuel debates about national identity. Political discourse has become increasingly polarized, eroding trust in institutions and complicating policy decisions.',
      imagePath: 'assets/images/scenarios/cultural_conflict.jpg',
      budgetModifier: 0, // Budget unaffected, but political constraints increase
      justiceIndexDifficulty: 1.5, // Extremely difficult to achieve consensus on justice
      effects: [
        ScenarioEffect(
          policyDomainId: 'education',
          policyEffects: {
            'education_1': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 1.6,
              rewardFactor: 1.4,
              modifiedDescription: 'School choice becomes politically charged during cultural tensions',
            ),
            'education_2': PolicyEffectModifier(
              costMultiplier: 1.1,
              riskFactor: 0.8,
              rewardFactor: 1.5,
              modifiedDescription: 'Targeted investments can bridge cultural divides',
            ),
            'education_3': PolicyEffectModifier(
              costMultiplier: 1.3,
              riskFactor: 1.7,
              rewardFactor: 1.8,
              modifiedDescription: 'Universal education faces implementation challenges during cultural conflict',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'criminal_justice',
          policyEffects: {
            'criminal_justice_1': PolicyEffectModifier(
              costMultiplier: 1.1,
              riskFactor: 1.8,
              rewardFactor: 0.7,
              modifiedDescription: 'Tough on crime approaches exacerbate cultural divisions',
            ),
            'criminal_justice_2': PolicyEffectModifier(
              riskFactor: 0.7,
              rewardFactor: 1.5,
              modifiedDescription: 'Reform efforts can help bridge community divides',
            ),
          },
        ),
        ScenarioEffect(
          policyDomainId: 'immigration',
          policyEffects: {
            'immigration_1': PolicyEffectModifier(
              costMultiplier: 0.9,
              riskFactor: 1.7,
              rewardFactor: 0.6,
              modifiedDescription: 'Border security becomes highly politicized during identity conflicts',
            ),
            'immigration_3': PolicyEffectModifier(
              costMultiplier: 1.3,
              riskFactor: 1.6,
              rewardFactor: 1.7,
              modifiedDescription: 'Open borders policies face stronger resistance during cultural tensions',
            ),
          },
        ),
      ],
      domainImpactModifiers: {
        'education': 1.7,
        'criminal_justice': 1.5,
        'immigration': 1.6,
        'healthcare': 1.2,
        'economy': 0.9,
        'environment': 1.1,
        'defense': 0.8,
      },
    );
  }
}