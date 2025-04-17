import 'agent_model.dart';
import 'policy_models.dart';
import 'scenario_service.dart';

class DataService {
  static Future<List<PolicyDomain>> loadPolicyData() async {
    try {
      // Load base domains
      final baseDomains = _getMockPolicyDomains();
      
      // Check if there's an active scenario
      final currentScenario = ScenarioService.currentScenario;
      if (currentScenario != null) {
        // Apply scenario modifications to the domains
        return currentScenario.getModifiedDomains(baseDomains);
      }
      
      return baseDomains;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Agent>> loadAgentData() async {
    try {
      // Load from assets or use mock data for development
      return _getMockAgents();
    } catch (e) {
      return [];
    }
  }

  // Mock data for development and testing
  static List<PolicyDomain> _getMockPolicyDomains() {
    final List<PolicyDomain> domains = [];

    // Economy Domain
    domains.add(PolicyDomain(
      id: 'economy',
      name: 'Economy',
      description: 'Policies concerning economic growth, taxes, and regulations',
      options: [
        PolicyOption(
          id: 'economy_1',
          title: 'Market Deregulation',
          description: 'Reduce business regulations and cut corporate taxes',
          cost: 1,
          domain: 'economy',
        ),
        PolicyOption(
          id: 'economy_2',
          title: 'Balanced Approach',
          description: 'Maintain current tax levels with targeted incentives for growth sectors',
          cost: 2,
          domain: 'economy',
        ),
        PolicyOption(
          id: 'economy_3',
          title: 'Progressive Taxation',
          description: 'Increase taxes on high earners to fund social programs and infrastructure',
          cost: 3,
          domain: 'economy',
        ),
      ],
    ));

    // Healthcare Domain
    domains.add(PolicyDomain(
      id: 'healthcare',
      name: 'Healthcare',
      description: 'Policies on healthcare access, insurance, and costs',
      options: [
        PolicyOption(
          id: 'healthcare_1',
          title: 'Private Insurance Focus',
          description: 'Reduce regulations on insurance companies to increase competition',
          cost: 1,
          domain: 'healthcare',
        ),
        PolicyOption(
          id: 'healthcare_2',
          title: 'Public-Private Partnership',
          description: 'Expand existing programs while maintaining private insurance options',
          cost: 2,
          domain: 'healthcare',
        ),
        PolicyOption(
          id: 'healthcare_3',
          title: 'Universal Healthcare',
          description: 'Implement a single-payer system covering all citizens',
          cost: 3,
          domain: 'healthcare',
        ),
      ],
    ));

    // Education Domain
    domains.add(PolicyDomain(
      id: 'education',
      name: 'Education',
      description: 'Policies on schools, universities, and educational standards',
      options: [
        PolicyOption(
          id: 'education_1',
          title: 'School Choice',
          description: 'Implement vouchers and expand charter schools',
          cost: 1,
          domain: 'education',
        ),
        PolicyOption(
          id: 'education_2',
          title: 'Targeted Investments',
          description: 'Increase funding for underperforming schools and teacher training',
          cost: 2,
          domain: 'education',
        ),
        PolicyOption(
          id: 'education_3',
          title: 'Education For All',
          description: 'Fully fund public education and make college tuition-free',
          cost: 3,
          domain: 'education',
        ),
      ],
    ));

    // Environment Domain
    domains.add(PolicyDomain(
      id: 'environment',
      name: 'Environment',
      description: 'Policies on climate change, conservation, and energy',
      options: [
        PolicyOption(
          id: 'environment_1',
          title: 'Market Solutions',
          description: 'Incentivize businesses to adopt cleaner technologies without mandates',
          cost: 1,
          domain: 'environment',
        ),
        PolicyOption(
          id: 'environment_2',
          title: 'Balanced Approach',
          description: 'Implement moderate regulations with realistic timelines',
          cost: 2,
          domain: 'environment',
        ),
        PolicyOption(
          id: 'environment_3',
          title: 'Green New Deal',
          description: 'Overhaul energy infrastructure with strict emissions targets',
          cost: 3,
          domain: 'environment',
        ),
      ],
    ));

    // Immigration Domain
    domains.add(PolicyDomain(
      id: 'immigration',
      name: 'Immigration',
      description: 'Policies on borders, citizenship, and immigrant rights',
      options: [
        PolicyOption(
          id: 'immigration_1',
          title: 'Border Security',
          description: 'Strengthen borders and prioritize enforcement of existing laws',
          cost: 1,
          domain: 'immigration',
        ),
        PolicyOption(
          id: 'immigration_2',
          title: 'Comprehensive Reform',
          description: 'Create a path to legal status while improving border security',
          cost: 2,
          domain: 'immigration',
        ),
        PolicyOption(
          id: 'immigration_3',
          title: 'Open Borders',
          description: 'Streamline immigration process and expand refugee programs',
          cost: 3,
          domain: 'immigration',
        ),
      ],
    ));

    // Criminal Justice Domain
    domains.add(PolicyDomain(
      id: 'criminal_justice',
      name: 'Criminal Justice',
      description: 'Policies on law enforcement, prisons, and sentencing',
      options: [
        PolicyOption(
          id: 'criminal_justice_1',
          title: 'Tough on Crime',
          description: 'Increase policing resources and maintain mandatory minimums',
          cost: 1,
          domain: 'criminal_justice',
        ),
        PolicyOption(
          id: 'criminal_justice_2',
          title: 'Smart Reform',
          description: 'Focus on rehabilitation while maintaining public safety',
          cost: 2,
          domain: 'criminal_justice',
        ),
        PolicyOption(
          id: 'criminal_justice_3',
          title: 'Justice Overhaul',
          description: 'End mass incarceration and reallocate funds to community services',
          cost: 3,
          domain: 'criminal_justice',
        ),
      ],
    ));

    // Defense Domain
    domains.add(PolicyDomain(
      id: 'defense',
      name: 'National Defense',
      description: 'Policies on military, security, and international relations',
      options: [
        PolicyOption(
          id: 'defense_1',
          title: 'Strategic Focus',
          description: 'Maintain a leaner military focused on essential threats',
          cost: 1,
          domain: 'defense',
        ),
        PolicyOption(
          id: 'defense_2',
          title: 'Balanced Approach',
          description: 'Modernize forces while engaging in diplomatic solutions',
          cost: 2,
          domain: 'defense',
        ),
        PolicyOption(
          id: 'defense_3',
          title: 'Global Leadership',
          description: 'Expand military capabilities to maintain dominance worldwide',
          cost: 3,
          domain: 'defense',
        ),
      ],
    ));

    return domains;
  }

  static List<Agent> _getMockAgents() {
    return [
      Agent(
        id: 'agent1',
        name: 'Eleanor Garcia',
        age: 67,
        education: 'PhD in Sociology',
        occupation: 'Retired Professor',
        socioeconomicStatus: 'Upper-middle class',
        ideology: 'progressive',
      ),
      Agent(
        id: 'agent2',
        name: 'James Wilson',
        age: 42,
        education: 'MBA',
        occupation: 'Small Business Owner',
        socioeconomicStatus: 'Middle class',
        ideology: 'moderate conservative',
      ),
      Agent(
        id: 'agent3',
        name: 'Tanya Robinson',
        age: 29,
        education: 'Bachelor in Computer Science',
        occupation: 'Software Engineer',
        socioeconomicStatus: 'Upper-middle class',
        ideology: 'libertarian',
      ),
      Agent(
        id: 'agent4',
        name: 'Robert Miller',
        age: 55,
        education: 'High School Diploma',
        occupation: 'Construction Worker',
        socioeconomicStatus: 'Working class',
        ideology: 'traditional conservative',
      ),
    ];
  }
}