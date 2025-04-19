import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../../models/agent_model.dart';
import '../../../models/policy_models.dart';
import '../../../providers/enhanced_negotiation_provider.dart';
import '../../../providers/policy_selection_provider.dart';
import '../../../services/gemini_chat_service.dart';

class TranscriptViewer extends StatefulWidget {
  const TranscriptViewer({super.key});

  @override
  State<TranscriptViewer> createState() => _TranscriptViewerState();
}

class _TranscriptViewerState extends State<TranscriptViewer> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final negotiationProvider = Provider.of<EnhancedNegotiationProvider>(context);
    final topic = negotiationProvider.currentTopic;
    final agentsProvider = Provider.of<AgentsProvider>(context);
    final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context);
    
    // Show loading indicator when provider is explicitly loading
    if (negotiationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Only try to initialize if not already initialized and not already loading
    if (topic == null) {
      if (!negotiationProvider.isLoading && 
          !negotiationProvider.isNegotiating && 
          !policyDomainsProvider.isLoading && 
          policyDomainsProvider.domains.isNotEmpty) {
        // Schedule domain initialization after the frame is built to avoid rebuilding during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final firstDomain = policyDomainsProvider.domains.first;
          negotiationProvider.switchToDomain(firstDomain);
        });
      }
      
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }
    
    // Get the current domain
    final domain = policyDomainsProvider.domains.firstWhere(
      (d) => d.id == topic.domainId,
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown Domain', description: 'Unknown', options: []),
    );
    
    // Filter messages by stage for organized transcript
    final Map<NegotiationStage, List<dynamic>> messagesByStage = {};
    
    for (var stage in NegotiationStage.values) {
      messagesByStage[stage] = topic.messages
          .where((message) => message.stage == stage)
          .toList();
    }
    
    // Get sentiment analyses
    final sentimentAnalyses = negotiationProvider.messageSentiments.values.toList();
    
    // Generate transcript content
    final String markdownContent = _generateMarkdownTranscript(
      topic, 
      messagesByStage, 
      domain,
      agentsProvider.agents,
      sentimentAnalyses,
    );
    
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTranscriptHeader(context, domain),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discussion Transcript',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  MarkdownBody(
                    data: markdownContent,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      blockquote: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                        backgroundColor: Colors.grey[200],
                        fontSize: 14,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Color(0xFFE0E0E0),
                      ),
                      tableHead: const TextStyle(fontWeight: FontWeight.w600),
                      tableBody: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSentimentAnalysisCard(context, sentimentAnalyses),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildTranscriptHeader(BuildContext context, PolicyDomain domain) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 24),
              const SizedBox(width: 8),
              Text(
                'Full Discussion Transcript',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Policy Domain: ${domain.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            domain.description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'This transcript shows the complete negotiation process, including all statements from each phase of the discussion.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _generateMarkdownTranscript(
    NegotiationTopic topic,
    Map<NegotiationStage, List<dynamic>> messagesByStage,
    PolicyDomain domain,
    List<Agent> agents,
    List<SentimentAnalysis> sentimentAnalyses,
  ) {
    final buffer = StringBuffer();
    
    // Domain Information
    buffer.writeln('## Policy Domain: ${domain.name}');
    buffer.writeln();
    buffer.writeln('> ${domain.description}');
    buffer.writeln();
    
    // Agent Positions
    buffer.writeln('### Participants & Initial Positions');
    buffer.writeln();
    buffer.writeln('| Diplomat | Position | Selection |');
    buffer.writeln('|----------|----------|-----------|');
    
    topic.agentPositions.forEach((agentId, selection) {
      final agent = agents.firstWhere(
        (a) => a.id == agentId,
        orElse: () => Agent(
          id: agentId, 
          name: agentId == 'user' ? 'You' : 'Unknown',
          occupation: 'Unknown',
          age: 0,
          education: 'Unknown',
          socioeconomicStatus: 'Unknown',
          ideology: 'Unknown',
        ),
      );
      
      final optionNumber = int.tryParse(selection) ?? 1;
      final selectedOption = optionNumber <= domain.options.length && optionNumber > 0
          ? domain.options[optionNumber - 1]
          : null;
      
      buffer.writeln('| ${agent.name} | ${selectedOption?.title ?? 'Unknown'} | Option $optionNumber |');
    });
    buffer.writeln();
    
    // Messages by Stage
    final stages = [
      NegotiationStage.claim,
      NegotiationStage.counterclaim,
      NegotiationStage.rebuttal,
      NegotiationStage.conclusion,
    ];
    
    final stageNames = {
      NegotiationStage.claim: 'Initial Claims',
      NegotiationStage.counterclaim: 'Counterclaims',
      NegotiationStage.rebuttal: 'Rebuttals',
      NegotiationStage.conclusion: 'Conclusions',
    };
    
    for (final stage in stages) {
      final messages = messagesByStage[stage] ?? [];
      
      if (messages.isNotEmpty) {
        buffer.writeln('## ${stageNames[stage] ?? stage.toString().split('.').last}');
        buffer.writeln();
        
        for (final message in messages) {
          final agent = agents.firstWhere(
            (a) => a.id == message.senderId,
            orElse: () => Agent(
              id: message.senderId, 
              name: message.senderName,
              occupation: 'Unknown',
              age: 0,
              education: 'Unknown',
              socioeconomicStatus: 'Unknown',
              ideology: 'Unknown',
            ),
          );
          
          final formattedTime = _formatTimestamp(message.timestamp);
          
          buffer.writeln('### ${message.senderName} (${agent.occupation}) - $formattedTime');
          buffer.writeln();
          buffer.writeln(message.text);
          buffer.writeln();
          
          // Find sentiment analysis for this message if available
          if (sentimentAnalyses.isNotEmpty && messages.indexOf(message) < sentimentAnalyses.length) {
            // This is a simplification - in reality we'd match the sentiment to the specific message
            final sentimentIdx = messages.indexOf(message) % sentimentAnalyses.length;
            final sentiment = sentimentAnalyses[sentimentIdx];
            
            buffer.writeln('**Sentiment Analysis:**');
            buffer.writeln('- Tone: ${_formatTone(sentiment.discussionTone)}');
            buffer.writeln('- Justice Orientation: ${_getTopJusticeOrientation(sentiment.justiceScores)}');
            buffer.writeln();
          }
        }
      }
    }
    
    return buffer.toString();
  }
  
  Widget _buildSentimentAnalysisCard(BuildContext context, List<SentimentAnalysis> sentiments) {
    if (sentiments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Aggregate sentiment data
    final Map<DiscussionTone, int> toneCount = {};
    final Map<JusticeOrientation, double> justiceSum = {};
    final int totalMessages = sentiments.length;
    
    for (final sentiment in sentiments) {
      // Count tones
      toneCount[sentiment.discussionTone] = (toneCount[sentiment.discussionTone] ?? 0) + 1;
      
      // Sum justice scores
      sentiment.justiceScores.forEach((orientation, score) {
        justiceSum[orientation] = (justiceSum[orientation] ?? 0) + score;
      });
    }
    
    // Calculate averages and dominant values
    final Map<JusticeOrientation, double> averageJusticeScores = {};
    justiceSum.forEach((orientation, sum) {
      averageJusticeScores[orientation] = sum / totalMessages;
    });
    
    // Find dominant tone
    DiscussionTone? discussionTone;
    int maxCount = 0;
    toneCount.forEach((tone, count) {
      if (count > maxCount) {
        maxCount = count;
        discussionTone = tone;
      }
    });
    
    // Get highest justice orientation
    final topJustice = _getTopJusticeOrientation(averageJusticeScores);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discussion Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: Colors.purple),
              title: const Text('Dominant Tone'),
              subtitle: Text(_formatTone(discussionTone ?? DiscussionTone.informative)),
            ),
            ListTile(
              leading: const Icon(Icons.balance, color: Colors.blue),
              title: const Text('Strongest Justice Orientation'),
              subtitle: Text(topJustice),
            ),
            const SizedBox(height: 8),
            const Text(
              'Justice Score Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: averageJusticeScores[JusticeOrientation.equity] ?? 0.5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
              minHeight: 8,
            ),
            const Text('Equity', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: averageJusticeScores[JusticeOrientation.inclusion] ?? 0.5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 8,
            ),
            const Text('Inclusion', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: averageJusticeScores[JusticeOrientation.recognition] ?? 0.5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.purple,
              minHeight: 8,
            ),
            const Text('Recognition', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: averageJusticeScores[JusticeOrientation.procedural] ?? 0.5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
              minHeight: 8,
            ),
            const Text('Procedural', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: averageJusticeScores[JusticeOrientation.distributive] ?? 0.5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.red,
              minHeight: 8,
            ),
            const Text('Distributive', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatTone(DiscussionTone tone) {
    switch (tone) {
      case DiscussionTone.collaborative:
        return 'Collaborative';
      case DiscussionTone.confrontational:
        return 'Confrontational';
      case DiscussionTone.inquisitive:
        return 'Inquisitive';
      case DiscussionTone.persuasive:
        return 'Persuasive';
      case DiscussionTone.informative:
        return 'Informative';
      default:
        return 'Neutral';
    }
  }
  
  String _getTopJusticeOrientation(Map<JusticeOrientation, double> scores) {
    if (scores.isEmpty) return 'None';
    
    JusticeOrientation topOrientation = JusticeOrientation.equity;
    double maxScore = 0;
    
    scores.forEach((orientation, score) {
      if (score > maxScore) {
        maxScore = score;
        topOrientation = orientation;
      }
    });
    
    switch (topOrientation) {
      case JusticeOrientation.equity:
        return 'Equity (Fair distribution of resources)';
      case JusticeOrientation.inclusion:
        return 'Inclusion (Representation and participation)';
      case JusticeOrientation.recognition:
        return 'Recognition (Acknowledging identity and difference)';
      case JusticeOrientation.procedural:
        return 'Procedural (Fair processes and decision-making)';
      case JusticeOrientation.distributive:
        return 'Distributive (Allocation of benefits and burdens)';
      default:
        return 'Balanced';
    }
  }
}