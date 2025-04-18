import 'policy_models.dart';

class Agent {
  final String id;
  final String name;
  final int age;
  final String education;
  final String occupation;
  final String socioeconomicStatus;
  final String ideology;
  final String? perspective;
  final String? policyFocus;
  final String? dialogueStyle;
  final String? riskTolerance;
  final Map<String, PolicyOption> selections;
  final Map<String, String> justifications;

  Agent({
    required this.id,
    required this.name,
    required this.age,
    required this.education,
    required this.occupation,
    required this.socioeconomicStatus,
    required this.ideology,
    this.perspective,
    this.policyFocus,
    this.dialogueStyle,
    this.riskTolerance,
    this.selections = const {},
    this.justifications = const {},
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    final Map<String, PolicyOption> selections = {};
    final Map<String, String> justifications = {};

    if (json.containsKey('selections')) {
      final selectionsMap = json['selections'] as Map<String, dynamic>;
      selectionsMap.forEach((domainId, optionJson) {
        selections[domainId] = PolicyOption.fromJson(optionJson);
      });
    }

    if (json.containsKey('justifications')) {
      final justificationsMap = json['justifications'] as Map<String, dynamic>;
      justificationsMap.forEach((domainId, justification) {
        justifications[domainId] = justification as String;
      });
    }

    return Agent(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      education: json['education'],
      occupation: json['occupation'],
      socioeconomicStatus: json['socioeconomicStatus'],
      ideology: json['ideology'],
      perspective: json['perspective'],
      policyFocus: json['policyFocus'],
      dialogueStyle: json['dialogueStyle'],
      riskTolerance: json['riskTolerance'],
      selections: selections,
      justifications: justifications,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> selectionsJson = {};
    final Map<String, dynamic> justificationsJson = {};

    selections.forEach((domainId, option) {
      selectionsJson[domainId] = option.toJson();
    });

    justifications.forEach((domainId, justification) {
      justificationsJson[domainId] = justification;
    });

    return {
      'id': id,
      'name': name,
      'age': age,
      'education': education,
      'occupation': occupation,
      'socioeconomicStatus': socioeconomicStatus,
      'ideology': ideology,
      'perspective': perspective,
      'policyFocus': policyFocus,
      'dialogueStyle': dialogueStyle,
      'riskTolerance': riskTolerance,
      'selections': selectionsJson,
      'justifications': justificationsJson,
    };
  }

  String generateJustification(String domainName, PolicyOption option) {
    // Check if this is a diplomat agent with specific perspective
    if (perspective != null) {
      return _generateDiplomatJustification(domainName, option);
    }
    
    // Original justification logic for standard agents
    String justification;
    
    if (ideology.contains('conservative')) {
      if (option.cost == 1) {
        justification = 'As a $ideology, I believe this minimal intervention approach is fiscally responsible and preserves individual freedoms in $domainName.';
      } else if (option.cost == 2) {
        justification = 'This balanced approach to $domainName provides necessary oversight while maintaining economic efficiency.';
      } else {
        justification = 'Despite the cost, I believe strong investment in $domainName is necessary for long-term stability and security.';
      }
    } else if (ideology.contains('progressive')) {
      if (option.cost == 1) {
        justification = 'While I typically support more comprehensive solutions, this approach to $domainName is a pragmatic first step given our budget constraints.';
      } else if (option.cost == 2) {
        justification = 'This moderate investment in $domainName strikes a balance between fiscal responsibility and social needs.';
      } else {
        justification = 'As a $ideology, I believe robust investment in $domainName is essential for creating a more equitable society.';
      }
    } else {
      if (option.cost == 1) {
        justification = 'This limited approach to $domainName is cost-effective while still addressing essential needs.';
      } else if (option.cost == 2) {
        justification = 'A moderate investment in $domainName provides good value while remaining within reasonable budget constraints.';
      } else {
        justification = 'The substantial benefits of this comprehensive approach to $domainName justify the higher cost.';
      }
    }
    
    return justification;
  }
  
  String _generateDiplomatJustification(String domainName, PolicyOption option) {
    switch (id) {
      case 'diplomat1': // Progressive Humanitarian
        if (option.cost == 1) {
          return 'While this approach to $domainName is limited in scope, it establishes a foundation that we can build upon for greater equity and justice. I acknowledge its constraints but see it as a stepping stone toward more comprehensive reforms.';
        } else if (option.cost == 2) {
          return 'This policy represents meaningful progress in $domainName, balancing immediate needs with our moral obligation to create equitable systems. It directly addresses injustices while remaining feasible.';
        } else {
          return 'This robust investment in $domainName is essential for creating a truly just and equitable society. The transformative potential justifies the resources required—we cannot afford not to make this commitment to vulnerable communities.';
        }
        
      case 'diplomat2': // Pragmatic Realist
        if (option.cost == 1) {
          return 'This approach to $domainName maximizes efficiency while minimizing costs. The data shows we can achieve targeted outcomes without overextending our resources, making this a prudent choice in our current context.';
        } else if (option.cost == 2) {
          return 'Our analysis indicates this balanced policy in $domainName offers the optimal combination of impact and sustainability. It achieves measurable benefits within reasonable fiscal constraints while leaving room for future adjustments.';
        } else {
          return 'While higher in cost, our assessments show this comprehensive approach to $domainName delivers sufficient returns to justify the investment. The outcomes data and trade-off analysis support this as a calculated, strategic decision.';
        }
        
      case 'diplomat3': // Neoliberal Innovator
        if (option.cost == 1) {
          return 'This streamlined approach to $domainName leverages technological efficiencies that amplify impact beyond what traditional metrics might suggest. The scalability potential and innovation factor make this a high-value selection despite its modest cost.';
        } else if (option.cost == 2) {
          return 'Our data modeling projects that this policy in $domainName will drive significant performance improvements through its integration of innovative methodologies. The metrics indicate strong potential for systematic optimization.';
        } else {
          return 'The comprehensive data analytics behind this $domainName policy reveal transformative potential through its disruptive approach. The initial investment unlocks substantial growth metrics and creates scalable infrastructure for future innovations.';
        }
        
      case 'diplomat4': // Community-Centered Traditionalist
        if (option.cost == 1) {
          return 'This modest approach to $domainName respects community traditions while acknowledging resource limitations. It builds on existing social structures and local knowledge, ensuring cultural sensitivity without imposing external values.';
        } else if (option.cost == 2) {
          return 'Community feedback strongly supports this balanced policy in $domainName. It thoughtfully integrates local practices and values while introducing carefully vetted improvements that respect established social cohesion.';
        } else {
          return 'This comprehensive policy in $domainName represents a substantial but necessary investment in preserving and strengthening community bonds. It honors local wisdom while addressing pressing needs identified by community stakeholders themselves.';
        }
        
      default:
        return generateJustification(domainName, option);
    }
  }
}