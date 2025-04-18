import 'dart:convert';
import 'package:flutter/services.dart';
import 'agent_model.dart';
import 'policy_models.dart';
import 'scenario_service.dart';

class DataService {
  static Future<List<PolicyDomain>> loadPolicyData() async {
    try {
      // Load policy domains from JSON file
      final List<PolicyDomain> domains = await _loadPolicyDomainsFromJson();
      
      // Check if there's an active scenario
      final currentScenario = ScenarioService.currentScenario;
      if (currentScenario != null) {
        // Apply scenario modifications to the domains
        return currentScenario.getModifiedDomains(domains);
      }
      
      return domains;
    } catch (e) {
      print('Error loading policy data: $e');
      return [];
    }
  }

  static Future<List<PolicyDomain>> _loadPolicyDomainsFromJson() async {
    final String jsonString = await rootBundle.loadString('assets/data/policy_data.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((domain) => PolicyDomain.fromJson(domain)).toList();
  }

  static Future<List<Agent>> loadAgentData() async {
    try {
      // Load agent data from JSON file
      final String jsonString = await rootBundle.loadString('assets/data/agent_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((agent) => Agent.fromJson(agent)).toList();
    } catch (e) {
      print('Error loading agent data: $e');
      return [];
    }
  }
}