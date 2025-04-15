import 'dart:math';
import '../models/agent_model.dart';
import '../models/policy_models.dart';

class AgentService {
  static Map<String, String> generateJustifications(
      Agent agent, Map<String, PolicyOption> selections, List<PolicyDomain> domains) {
    final Map<String, String> justifications = {};

    for (final entry in selections.entries) {
      final domainId = entry.key;
      final option = entry.value;
      
      final domain = domains.firstWhere((d) => d.id == domainId);
      final justification = agent.generateJustification(domain.name, option);
      
      justifications[domainId] = justification;
    }

    return justifications;
  }

  static List<Agent> generateRandomSelections(
      List<Agent> agents, List<PolicyDomain> domains, int maxBudget) {
    final Random random = Random();
    final List<Agent> updatedAgents = [];

    for (final agent in agents) {
      final Map<String, PolicyOption> selections = {};
      final List<PolicyDomain> shuffledDomains = List.from(domains)..shuffle(random);
      int budgetUsed = 0;

      for (final domain in shuffledDomains) {
        if (selections.length >= domains.length || budgetUsed >= maxBudget) {
          break;
        }

        final availableOptions = domain.options
            .where((option) => option.cost + budgetUsed <= maxBudget)
            .toList();

        if (availableOptions.isEmpty) continue;

        // Apply diplomat-specific policy preferences if this is a diplomat agent
        if (agent.id.startsWith('diplomat')) {
          final selectedOption = _getDiplomatPolicyPreference(agent, availableOptions, random);
          selections[domain.id] = selectedOption;
          budgetUsed += selectedOption.cost;
          continue;
        }

        // Original logic for standard agents
        if (agent.ideology.contains('conservative') && random.nextDouble() > 0.7) {
          final sortedOptions = availableOptions..sort((a, b) => a.cost.compareTo(b.cost));
          if (sortedOptions.isNotEmpty) {
            final lowerCostOption = sortedOptions.first;
            selections[domain.id] = lowerCostOption;
            budgetUsed += lowerCostOption.cost;
            continue;
          }
        } else if (agent.ideology.contains('progressive') && random.nextDouble() > 0.7) {
          final sortedOptions = availableOptions..sort((a, b) => b.cost.compareTo(a.cost));
          if (sortedOptions.isNotEmpty) {
            final higherCostOption = sortedOptions.first;
            selections[domain.id] = higherCostOption;
            budgetUsed += higherCostOption.cost;
            continue;
          }
        }

        final selectedOption = availableOptions[random.nextInt(availableOptions.length)];
        selections[domain.id] = selectedOption;
        budgetUsed += selectedOption.cost;
      }

      final justifications = generateJustifications(agent, selections, domains);

      final updatedAgent = Agent(
        id: agent.id,
        name: agent.name,
        age: agent.age,
        education: agent.education,
        occupation: agent.occupation,
        socioeconomicStatus: agent.socioeconomicStatus,
        ideology: agent.ideology,
        perspective: agent.perspective,
        policyFocus: agent.policyFocus,
        dialogueStyle: agent.dialogueStyle,
        riskTolerance: agent.riskTolerance,
        selections: selections,
        justifications: justifications,
      );

      updatedAgents.add(updatedAgent);
    }

    return updatedAgents;
  }
  
  static PolicyOption _getDiplomatPolicyPreference(Agent diplomat, List<PolicyOption> availableOptions, Random random) {
    if (availableOptions.isEmpty) {
      throw Exception('No available options to choose from');
    }
    
    // Sort options by cost for easier selection
    final List<PolicyOption> sortedOptions = List.from(availableOptions);
    sortedOptions.sort((a, b) => a.cost.compareTo(b.cost));
    
    // Get low, medium, and high cost options if available
    final lowCostOptions = sortedOptions.where((option) => option.cost == 1).toList();
    final mediumCostOptions = sortedOptions.where((option) => option.cost == 2).toList();
    final highCostOptions = sortedOptions.where((option) => option.cost == 3).toList();
    
    switch (diplomat.id) {
      case 'diplomat1': // Progressive Humanitarian - prefers high cost, equity-focused options
        // 70% chance for high cost, 20% for medium, 10% for low
        final rand = random.nextDouble();
        if (rand < 0.7 && highCostOptions.isNotEmpty) {
          return highCostOptions[random.nextInt(highCostOptions.length)];
        } else if (rand < 0.9 && mediumCostOptions.isNotEmpty) {
          return mediumCostOptions[random.nextInt(mediumCostOptions.length)];
        } else if (lowCostOptions.isNotEmpty) {
          return lowCostOptions[random.nextInt(lowCostOptions.length)];
        }
        break;
        
      case 'diplomat2': // Pragmatic Realist - prefers balanced, medium cost options
        // 60% chance for medium cost, 20% for low, 20% for high
        final rand = random.nextDouble();
        if (rand < 0.6 && mediumCostOptions.isNotEmpty) {
          return mediumCostOptions[random.nextInt(mediumCostOptions.length)];
        } else if (rand < 0.8 && lowCostOptions.isNotEmpty) {
          return lowCostOptions[random.nextInt(lowCostOptions.length)];
        } else if (highCostOptions.isNotEmpty) {
          return highCostOptions[random.nextInt(highCostOptions.length)];
        }
        break;
        
      case 'diplomat3': // Neoliberal Innovator - varied, but with higher chance for high-tech solutions
        // 40% for high, 40% for medium, 20% for low - representing openness to disruptive approaches
        final rand = random.nextDouble();
        if (rand < 0.4 && highCostOptions.isNotEmpty) {
          return highCostOptions[random.nextInt(highCostOptions.length)];
        } else if (rand < 0.8 && mediumCostOptions.isNotEmpty) {
          return mediumCostOptions[random.nextInt(mediumCostOptions.length)];
        } else if (lowCostOptions.isNotEmpty) {
          return lowCostOptions[random.nextInt(lowCostOptions.length)];
        }
        break;
        
      case 'diplomat4': // Community-Centered Traditionalist - prefers lower to medium cost, cautious
        // 50% for medium, 40% for low, 10% for high - representing cautious approach
        final rand = random.nextDouble();
        if (rand < 0.5 && mediumCostOptions.isNotEmpty) {
          return mediumCostOptions[random.nextInt(mediumCostOptions.length)];
        } else if (rand < 0.9 && lowCostOptions.isNotEmpty) {
          return lowCostOptions[random.nextInt(lowCostOptions.length)];
        } else if (highCostOptions.isNotEmpty) {
          return highCostOptions[random.nextInt(highCostOptions.length)];
        }
        break;
    }
    
    // Fallback: return a random option if no specific selection made
    return availableOptions[random.nextInt(availableOptions.length)];
  }
}