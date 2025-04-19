import 'dart:convert';
import 'package:cards_of_conscience/services/settings_service.dart';
import 'package:cards_of_conscience/utils/api_error_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_model.dart';
import '../models/chat_message.dart';
import '../models/policy_models.dart';
import '../providers/enhanced_negotiation_provider.dart';

enum DiscussionTone {
  collaborative,
  confrontational,
  informative,
  persuasive,
  inquisitive,
}

enum JusticeOrientation {
  equity,
  inclusion,
  recognition,
  procedural,
  distributive,
}

class SentimentAnalysis {
  final List<String> keyThemes;
  final List<String> concernsRaised;
  final Map<JusticeOrientation, double> justiceScores;
  final DiscussionTone discussionTone;
  final double positivity;
  final double antagonism;

  SentimentAnalysis({
    required this.keyThemes,
    required this.concernsRaised,
    required this.justiceScores,
    this.discussionTone = DiscussionTone.collaborative,
    this.positivity = 0.5,
    this.antagonism = 0.0,
  });

  factory SentimentAnalysis.empty() {
    return SentimentAnalysis(
      keyThemes: [],
      concernsRaised: [],
      justiceScores: {
        JusticeOrientation.equity: 0.5,
        JusticeOrientation.inclusion: 0.5,
        JusticeOrientation.recognition: 0.5,
        JusticeOrientation.procedural: 0.5,
        JusticeOrientation.distributive: 0.5,
      },
    );
  }
}

class GeminiChatService with ApiErrorHandler {
  Gemini? _gemini;
  bool _isInitialized = false;
  final String _apiKeySecureKey = 'gemini_api_key_secure';

  // Initialize Gemini if not already initialized
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      final apiKey = await getStoredApiKey();

      // Initialize Gemini with the API key
      Gemini.init(apiKey: apiKey, enableDebugging: true);
      _gemini = Gemini.instance;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      rethrow;
    }
  }

  Future<String> getStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    // Try to get key from secure storage first
    final secureKey = prefs.getString(_apiKeySecureKey);
    if (secureKey != null && secureKey.isNotEmpty) {
      return secureKey;
    }
    throw Exception('No secure key found');
  }

  // Check if API key exists
  Future<bool> hasApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = prefs.getString(_apiKeySecureKey);
      return secureKey != null && secureKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update the API key
  Future<void> updateApiKey(String newApiKey) async {
    try {
      // Store the API key first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeySecureKey, newApiKey);

      // Then initialize Gemini with it
      Gemini.init(apiKey: newApiKey, enableDebugging: true);
      _gemini = Gemini.instance;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error updating Gemini API key: $e');
      rethrow;
    }
  }

  // Generate a response for an agent in a negotiation
  Future<String> generateResponse({
    required Agent agent,
    required List<ChatMessage> conversationHistory,
    required PolicyDomain domain,
    required NegotiationStage stage,
    required int agentSelection,
  }) async {
    await _ensureInitialized();

    return handleApiCall<String>(() async {
      // Get user preferred discussion tone from settings
      final settings = await SettingsService.getSettings();
      final preferredTone = settings.discussionTone;
      
      // Map stage to prompt instructions
      final stageInstructions = _getStageInstructions(stage);

      // Format conversation history for the prompt
      final formattedHistory = conversationHistory
          .map((msg) => '${msg.senderName}: ${msg.text}')
          .join('\n\n');

      // Get tone-specific instruction
      final toneInstruction = _getToneInstruction(preferredTone);

      // Build prompt with agent personality, domain, stage, and preferred tone
      final prompt = '''
You are ${agent.name}, a diplomat with the following attributes:
- Education: ${agent.education}
- Occupation: ${agent.occupation}
- Socioeconomic Status: ${agent.socioeconomicStatus}
- Ideology: ${agent.ideology}
- Perspective: ${agent.perspective ?? 'Balanced'}
- Policy Focus: ${agent.policyFocus ?? 'General policy concerns'}
- Dialogue Style: ${agent.dialogueStyle ?? 'Professional'}

You're discussing policy options for the domain of "${domain.name}": ${domain.description}

The policy options are:
${domain.options.asMap().entries.map((e) => '${e.key + 1}. ${e.value.description}').join('\n')}

You prefer option #$agentSelection: ${domain.options[agentSelection - 1].description}

Current negotiation stage: ${stage.name}
Instructions for this stage: $stageInstructions

Discussion tone preference: $toneInstruction

Previous conversation:
$formattedHistory

Respond based on your character and policy preference. Keep your response concise (2-3 paragraphs maximum) while maintaining your personality and values and adhering to the requested discussion tone.
''';

      final content = [
        Content(role: 'user', parts: [Part.text(prompt)])
      ];

      final response = await _gemini!.chat(content);

      if (response == null || response.output == null) {
        return "I apologize, but I'm having trouble formulating a response at the moment. Perhaps we can continue the discussion when I've had more time to consider the policy implications.";
      }

      return response.output!.trim();
    }, 
    "I apologize, but I'm experiencing some technical difficulties. Let's continue our discussion shortly.",
    logMessage: 'Error generating agent response');
  }

  // Helper method to get tone instruction based on discussion tone
  String _getToneInstruction(DiscussionTone tone) {
    switch (tone) {
      case DiscussionTone.collaborative:
        return 'Be collaborative and seek common ground. Focus on building consensus and finding shared values.';
      case DiscussionTone.confrontational:
        return 'Be challenging and direct. Strongly defend your position and point out flaws in opposing perspectives.';
      case DiscussionTone.informative:
        return 'Be informative and educational. Share facts, research, and evidence to support your position.';
      case DiscussionTone.persuasive:
        return 'Be persuasive and compelling. Use rhetorical techniques to convince others of your position.';
      case DiscussionTone.inquisitive:
        return 'Be inquisitive and curious. Ask thought-provoking questions and explore different angles.';
    }
  }

  // Analyze sentiment of a message
  Future<SentimentAnalysis> analyzeSentiment(String text) async {
    await _ensureInitialized();

    return handleApiCall<SentimentAnalysis>(() async {
      final prompt = '''
Analyze the following message for sentiment and content:

MESSAGE:
"""
$text
"""

Please provide a JSON response with the following structure:
{
  "discussionTone": "collaborative"|"confrontational"|"empathetic"|"pragmatic"|"informative",
  "positivity": (float between 0 and 1 indicating how positive the message is),
  "antagonism": (float between 0 and 1 indicating how antagonistic/confrontational the message is),
  "keyThemes": [list of 2-4 key themes from the message],
  "concernsRaised": [list of specific concerns or issues raised],
  "justiceScores": {
    "equity": (float between 0 and 1 indicating focus on fairness and equal outcomes),
    "inclusion": (float between 0 and 1 indicating focus on including diverse perspectives),
    "recognition": (float between 0 and 1 indicating respect for different identities and experiences),
    "procedural": (float between 0 and 1 indicating fairness in process and decision-making),
    "distributive": (float between 0 and 1 indicating fair allocation of resources)
  }
}

Provide only the JSON with no additional text.
''';

      final content = [
        Content(role: 'user', parts: [Part.text(prompt)])
      ];

      final response = await _gemini!.chat(content);

      if (response == null || response.output == null) {
        return SentimentAnalysis.empty();
      }

      // Extract and parse JSON from response
      String jsonStr = response.output!.trim();

      // Check if response is wrapped in code blocks and extract just the JSON
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      // Parse JSON response
      final Map<String, dynamic> data = Map<String, dynamic>.from(await const JsonDecoder().convert(jsonStr));

      // Parse discussion tone
      final String toneStr = data['discussionTone'] as String? ?? 'collaborative';
      final DiscussionTone discussionTone = _parseDiscussionTone(toneStr);
      
      final positivity = data['positivity'] as double? ?? 0.5;
      final antagonism = data['antagonism'] as double? ?? 0.0;

      final keyThemesList = data['keyThemes'] as List<dynamic>? ?? [];
      final keyThemes = keyThemesList.map((e) => e.toString()).toList();

      final concernsList = data['concernsRaised'] as List<dynamic>? ?? [];
      final concernsRaised = concernsList.map((e) => e.toString()).toList();

      final justiceData = data['justiceScores'] as Map<String, dynamic>? ?? {};
      final justiceScores = {
        JusticeOrientation.equity: justiceData['equity'] as double? ?? 0.5,
        JusticeOrientation.inclusion: justiceData['inclusion'] as double? ?? 0.5,
        JusticeOrientation.recognition: justiceData['recognition'] as double? ?? 0.5,
        JusticeOrientation.procedural: justiceData['procedural'] as double? ?? 0.5,
        JusticeOrientation.distributive: justiceData['distributive'] as double? ?? 0.5,
      };

      return SentimentAnalysis(
        discussionTone: discussionTone,
        positivity: positivity,
        antagonism: antagonism,
        keyThemes: keyThemes,
        concernsRaised: concernsRaised,
        justiceScores: justiceScores,
      );
    }, 
    SentimentAnalysis.empty(),
    logMessage: 'Error analyzing sentiment');
  }
  
  // Helper method to parse discussion tone from string
  DiscussionTone _parseDiscussionTone(String toneStr) {
    switch (toneStr.toLowerCase()) {
      case 'confrontational':
        return DiscussionTone.confrontational;
      case 'empathetic':
        return DiscussionTone.inquisitive;
      case 'inquisitive':
        return DiscussionTone.persuasive;
      case 'persuasive':
        return DiscussionTone.informative;
      case 'collaborative':
      default:
        return DiscussionTone.collaborative;
    }
  }

  // Generate policy impact projections
  Future<Map<String, dynamic>> generatePolicyImpactProjections(Map<String, int> finalSelections) async {
    await _ensureInitialized();

    return handleApiCall<Map<String, dynamic>>(() async {
      final prompt = '''
Given the following policy selections, generate a detailed impact analysis that projects outcomes in educational settings for refugee populations.

Policy Selections:
${finalSelections.entries.map((e) => '- Domain ${e.key}: Option ${e.value}').join('\n')}

Please provide a JSON response with the following structure:
{
  "shortTermImpacts": [
    {"domain": "string", "description": "string", "magnitude": float}
  ],
  "mediumTermImpacts": [
    {"domain": "string", "description": "string", "magnitude": float}
  ],
  "longTermImpacts": [
    {"domain": "string", "description": "string", "magnitude": float}
  ],
  "stakeholderImpacts": {
    "refugees": ["string"],
    "hostCommunity": ["string"],
    "educators": ["string"],
    "government": ["string"]
  },
  "sustainabilityAssessment": {
    "financial": float,
    "institutional": float,
    "social": float,
    "description": "string"
  }
}

For each impact, provide a realistic projection based on educational policy research. Magnitude should be a float between 0 and 1, where 0 is no impact and 1 is maximum impact.

Provide only the JSON with no additional text.
''';

      final content = [
        Content(role: 'user', parts: [Part.text(prompt)])
      ];

      final response = await _gemini!.chat(content);

      if (response == null || response.output == null) {
        return _getDefaultPolicyImpactData();
      }

      // Extract and parse JSON from response
      String jsonStr = response.output!.trim();

      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      final Map<String, dynamic> data = await const JsonDecoder().convert(jsonStr);
      return data;
    }, 
    _getDefaultPolicyImpactData(),
    logMessage: 'Error generating policy impact projections');
  }

  // Generate ethical tradeoff analysis
  Future<Map<String, dynamic>> generateEthicalTradeoffAnalysis(
    Map<String, int> finalSelections,
    Map<PolicyDomain, List<double>> domainImpacts,
  ) async {
    await _ensureInitialized();

    return handleApiCall<Map<String, dynamic>>(() async {
      // Format domain impacts for the prompt
      final impactsText = domainImpacts.entries.map((entry) {
        final domain = entry.key.name;
        final impacts = entry.value.map((v) => v.toStringAsFixed(2)).join(', ');
        return '- $domain: [$impacts]';
      }).join('\n');

      final prompt = '''
Based on the following policy selections and simulated impact values, analyze the ethical tradeoffs involved in these educational policy decisions for refugee students.

Policy Selections:
${finalSelections.entries.map((e) => '- Domain ${e.key}: Option ${e.value}').join('\n')}

Simulated Impact Values:
$impactsText

Please provide a JSON response with the following structure:
{
  "ethicalTradeoffs": [
    {
      "description": "string describing the tradeoff",
      "impactedGroups": ["string"],
      "justiceImplications": "string analyzing justice implications",
      "alternativeApproach": "string suggesting alternatives"
    }
  ],
  "justiceAnalysis": {
    "equity": float,
    "inclusion": float,
    "recognition": float,
    "overall": "string"
  },
  "valueTensions": [
    {"value1": "string", "value2": "string", "description": "string"}
  ],
  "educationalTheoryConnections": [
    {"theory": "string", "connection": "string", "impact": "string"}
  ]
}

For each ethical tradeoff, consider the competing values, groups affected differently, and justice implications. Highlight connections to educational theories when relevant.

Provide only the JSON with no additional text.
''';

      final content = [
        Content(role: 'user', parts: [Part.text(prompt)])
      ];

      final response = await _gemini!.chat(content);

      if (response == null || response.output == null) {
        return _getDefaultEthicalAnalysisData();
      }

      // Extract and parse JSON from response
      String jsonStr = response.output!.trim();

      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      final Map<String, dynamic> data = await const JsonDecoder().convert(jsonStr);
      return data;
    }, 
    _getDefaultEthicalAnalysisData(),
    logMessage: 'Error generating ethical tradeoff analysis');
  }

  // Private helper methods

  // Get instructions based on negotiation stage
  String _getStageInstructions(NegotiationStage stage) {
    switch (stage) {
      case NegotiationStage.claim:
        return 'Present your initial position on the policy option you prefer. Explain your rationale based on your values and expertise. Be clear and confident in your claim.';
      case NegotiationStage.counterclaim:
        return 'Respond to the other diplomats\' initial positions. Present counter-arguments that challenge aspects of their claims while reaffirming your position.';
      case NegotiationStage.rebuttal:
        return 'Address the critiques of your position and defend your stance. Show why your preferred policy is still the best choice despite the criticisms.';
      case NegotiationStage.conclusion:
        return 'Work toward a conclusion by acknowledging merits in other positions and suggesting possible compromises or integrations of ideas, while still advocating for key elements of your preferred policy.';
    }
  }

  // Default policy impact data in case of API error
  Map<String, dynamic> _getDefaultPolicyImpactData() {
    return {
      'shortTermImpacts': [
        {
          'domain': 'Educational Access',
          'description': 'Immediate increase in refugee student enrollment rates in local schools',
          'magnitude': 0.7
        },
        {
          'domain': 'Resource Allocation',
          'description': 'Initial strain on classroom resources and teaching staff',
          'magnitude': 0.6
        }
      ],
      'mediumTermImpacts': [
        {
          'domain': 'Academic Achievement',
          'description': 'Gradual improvement in literacy and numeracy outcomes for refugee students',
          'magnitude': 0.5
        },
        {
          'domain': 'Social Integration',
          'description': 'Developing relationships between refugee and host community students',
          'magnitude': 0.4
        }
      ],
      'longTermImpacts': [
        {
          'domain': 'Economic Opportunity',
          'description': 'Enhanced economic mobility for refugee community through educational attainment',
          'magnitude': 0.6
        },
        {
          'domain': 'Community Cohesion',
          'description': 'Strengthened intercultural understanding and reduced social tensions',
          'magnitude': 0.5
        }
      ],
      'stakeholderImpacts': {
        'refugees': [
          'Increased access to quality education',
          'Cultural adaptation challenges in new educational settings',
          'Opportunity for social mobility through education'
        ],
        'hostCommunity': [
          'Exposure to diverse perspectives in classrooms',
          'Initial concerns about resource distribution',
          'Long-term enrichment of community through diversity'
        ],
        'educators': [
          'Need for professional development in culturally responsive teaching',
          'Increased classroom diversity and teaching challenges',
          'Opportunities for innovative teaching approaches'
        ],
        'government': [
          'Initial investment requirements in educational infrastructure',
          'Long-term human capital development benefits',
          'Improved social cohesion reducing future social service costs'
        ]
      },
      'sustainabilityAssessment': {
        'financial': 0.6,
        'institutional': 0.7,
        'social': 0.8,
        'description': 'The policy approach shows good social sustainability due to community-based elements, but financial sustainability requires attention to ensure long-term funding mechanisms are in place.'
      }
    };
  }

  // Default ethical analysis data in case of API error
  Map<String, dynamic> _getDefaultEthicalAnalysisData() {
    return {
      'ethicalTradeoffs': [
        {
          'description': 'Prioritizing immediate access vs. long-term quality',
          'impactedGroups': ['Refugee children', 'Teachers', 'Host community students'],
          'justiceImplications': 'Focuses on procedural justice by providing immediate access but may compromise distributive justice if quality suffers across the system',
          'alternativeApproach': 'Phased implementation with quality benchmarks and regular assessment points'
        },
        {
          'description': 'Cultural integration vs. cultural preservation',
          'impactedGroups': ['Refugee families', 'Host community'],
          'justiceImplications': 'Tension between recognition justice (honoring cultural identities) and inclusion within mainstream educational systems',
          'alternativeApproach': 'Culturally responsive curriculum that both integrates and preserves cultural knowledge'
        }
      ],
      'justiceAnalysis': {
        'equity': 0.6,
        'inclusion': 0.7,
        'recognition': 0.5,
        'overall': 'The policy selections show stronger commitment to inclusion than to recognition justice, with moderate attention to equity concerns.'
      },
      'valueTensions': [
        {
          'value1': 'Efficiency',
          'value2': 'Cultural sensitivity',
          'description': 'Quick deployment of standardized educational interventions may conflict with the need for culturally tailored approaches'
        },
        {
          'value1': 'Individual advancement',
          'value2': 'Community cohesion',
          'description': 'Focus on individual academic achievement may undervalue community-building and social belonging'
        }
      ],
      'educationalTheoryConnections': [
        {
          'theory': 'Critical Pedagogy',
          'connection': 'The policy approach acknowledges power dynamics in educational access but could go further in addressing systemic inequities',
          'impact': 'Partial empowerment of refugee students with room for more transformative approaches'
        },
        {
          'theory': 'Culturally Responsive Teaching',
          'connection': 'Elements of cultural responsiveness appear in the selected policies but implementation will determine effectiveness',
          'impact': 'Potential for improving educational outcomes if teachers receive proper training and support'
        }
      ]
    };
  }
}