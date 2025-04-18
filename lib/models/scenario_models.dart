import 'policy_models.dart';

enum CrisisType {
  urbanRefugeeInflux,
  borderInstability,
  economicCollapse,
  culturalConflict,
}

class ScenarioEffect {
  final String policyDomainId;
  final Map<String, PolicyEffectModifier> policyEffects;
  
  ScenarioEffect({
    required this.policyDomainId,
    required this.policyEffects,
  });
}

class PolicyEffectModifier {
  final double costMultiplier;
  final double riskFactor;
  final double rewardFactor;
  final String modifiedDescription;
  
  PolicyEffectModifier({
    this.costMultiplier = 1.0,
    this.riskFactor = 1.0,
    this.rewardFactor = 1.0,
    required this.modifiedDescription,
  });
}

class Scenario {
  final CrisisType crisisType;
  final String title;
  final String description;
  final String imagePath;
  final int budgetModifier;
  final double justiceIndexDifficulty;
  final List<ScenarioEffect> effects;
  final Map<String, double> domainImpactModifiers;
  
  Scenario({
    required this.crisisType,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.budgetModifier,
    required this.justiceIndexDifficulty,
    required this.effects,
    required this.domainImpactModifiers,
  });
  
  int getModifiedBudget(int baseBudget) {
    return baseBudget + budgetModifier;
  }
  
  PolicyOption getModifiedPolicy(PolicyOption option) {
    // Find effects for this policy's domain
    final domainEffect = effects.firstWhere(
      (effect) => effect.policyDomainId == option.domain,
      orElse: () => ScenarioEffect(policyDomainId: option.domain, policyEffects: {}),
    );
    
    // Check if there's a specific effect for this policy
    if (domainEffect.policyEffects.containsKey(option.id)) {
      final modifier = domainEffect.policyEffects[option.id]!;
      
      // Apply cost modifier (rounded to nearest int)
      final modifiedCost = (option.cost * modifier.costMultiplier).round();
      
      // Create modified policy with new description and cost
      return PolicyOption(
        id: option.id,
        title: option.title,
        description: '${option.description}\n\n[Scenario Impact: ${modifier.modifiedDescription}]',
        cost: modifiedCost,
        domain: option.domain,
      );
    }
    
    // Return original if no specific effect
    return option;
  }
  
  List<PolicyDomain> getModifiedDomains(List<PolicyDomain> originalDomains) {
    return originalDomains.map((domain) {
      final modifiedOptions = domain.options.map((option) => getModifiedPolicy(option)).toList();
      
      return PolicyDomain(
        id: domain.id, 
        name: domain.name, 
        description: domain.description,
        options: modifiedOptions,
      );
    }).toList();
  }
  
  double getModifiedJusticeScore(double originalScore, String domainId) {
    final modifier = domainImpactModifiers[domainId] ?? 1.0;
    return originalScore * modifier;
  }
}