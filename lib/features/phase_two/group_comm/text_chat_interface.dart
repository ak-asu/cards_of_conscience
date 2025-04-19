import 'package:cards_of_conscience/providers/enhanced_negotiation_provider.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../common/player_badge_row.dart';
import '../../../models/agent_model.dart';
import '../../../models/chat_message.dart';
import '../../../models/policy_models.dart';
import '../../../providers/policy_selection_provider.dart';

class TextChatInterface extends StatefulWidget {
  const TextChatInterface({super.key});

  @override
  State<TextChatInterface> createState() => _TextChatInterfaceState();
}

class _TextChatInterfaceState extends State<TextChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final negotiationProvider = Provider.of<EnhancedNegotiationProvider>(context);
    final currentTopic = negotiationProvider.currentTopic;
    final agentsProvider = Provider.of<AgentsProvider>(context);
    final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context);
    final policySelectionProvider = Provider.of<PolicySelectionProvider>(context);
    final aiSelectionsProvider = Provider.of<AISelectionsProvider>(context);
    
    // Show loading indicator when the provider is explicitly loading
    if (negotiationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Only try to initialize if not already initialized and not already loading
    if (currentTopic == null) {
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
      (d) => d.id == currentTopic.domainId,
      orElse: () => PolicyDomain(id: 'unknown', name: 'Unknown Domain', description: 'Unknown', options: []),
    );

    // Auto-scroll when messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          child: Row(
            children: [
              Icon(
                Icons.forum_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Discussion: ${domain.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _buildStageChip(context, currentTopic.stage),
            ],
          ),
        ),
        
        // Player badges row
        PlayerBadgeRow(
          agents: agentsProvider.agents,
          aiSelections: aiSelectionsProvider.aiSelections,
          userSelections: policySelectionProvider.state.selections,
        ),
        
        // Chat messages
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: currentTopic.messages.length,
              itemBuilder: (context, index) {
                final negotiationMessage = currentTopic.messages[index];
                final agent = agentsProvider.agents.firstWhere(
                  (a) => a.id == negotiationMessage.agentId,
                  orElse: () => Agent(
                    id: negotiationMessage.agentId,
                    name: 'Unknown',
                    occupation: 'Unknown',
                    age: 0,
                    education: 'Unknown',
                    socioeconomicStatus: 'Unknown',
                    ideology: '',
                  ),
                );
                
                // Convert negotiation message to chat message
                final chatMessage = ChatMessage(
                  senderId: negotiationMessage.agentId,
                  senderName: agent.name,
                  content: negotiationMessage.message,
                  timestamp: negotiationMessage.timestamp,
                );
                
                return _buildMessageBubble(context, chatMessage, agentsProvider);
              },
            ),
          ),
        ),
        
        // Input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Share your perspective...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _isComposing ? (_) => _handleSubmitted() : null,
                ),
              ),
              const SizedBox(width: 8),
              _isProcessing
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: _isComposing
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onPressed: _isComposing ? _handleSubmitted : null,
                  ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Advance to next stage',
                onPressed: () {
                  final negotiationProvider = Provider.of<EnhancedNegotiationProvider>(context, listen: false);
                  final agentsProvider = Provider.of<AgentsProvider>(context, listen: false);
                  final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context, listen: false);
                  
                  setState(() {
                    _isProcessing = true;
                  });
                  
                  negotiationProvider.forceAdvanceStage(
                    // agentsProvider.agents,
                    // policyDomainsProvider.domains,
                  ).then((_) {
                    setState(() {
                      _isProcessing = false;
                    });
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, AgentsProvider agentsProvider) {
    final isUser = message.senderId == 'user';
    
    final agent = isUser 
        ? null
        : agentsProvider.agents.firstWhere(
            (a) => a.id == message.senderId,
            orElse: () => Agent(
              id: message.senderId,
              name: message.senderName,
              occupation: 'Unknown',
              age: 0,
              education: 'Unknown',
              socioeconomicStatus: 'Unknown',
              ideology: '',
            ),
          );
    
    final color = isUser
        ? Theme.of(context).colorScheme.primary
        : _getDiplomatColor(message.senderId);
    
    final avatarWidget = CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(
        isUser ? Icons.person : _getDiplomatIcon(message.senderId),
        color: color,
        size: 18,
      ),
    );
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: isUser
          ? _buildUserMessage(context, message, avatarWidget)
          : _buildAgentMessage(context, message, avatarWidget, agent),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildUserMessage(BuildContext context, ChatMessage message, Widget avatar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BubbleSpecialThree(
            text: message.text,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: avatar,
        ),
      ],
    );
  }
  
  Widget _buildAgentMessage(BuildContext context, ChatMessage message, Widget avatar, Agent? agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 52.0, bottom: 4.0),
          child: Text(
            message.senderName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getDiplomatColor(message.senderId),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: avatar,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BubbleSpecialThree(
                text: message.text,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                isSender: false,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (agent != null && agent.ideology.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 52.0, top: 4.0),
            child: Text(
              agent.ideology,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStageChip(BuildContext context, NegotiationStage stage) {
    final String label;
    final Color color;
    
    switch (stage) {
      case NegotiationStage.claim:
        label = 'Initial Claims';
        color = Colors.blue;
        break;
      case NegotiationStage.counterclaim:
        label = 'Counterclaims';
        color = Colors.orange;
        break;
      case NegotiationStage.rebuttal:
        label = 'Rebuttals';
        color = Colors.purple;
        break;
      case NegotiationStage.conclusion:
        label = 'Conclusion';
        color = Colors.green;
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
    );
  }

  void _handleSubmitted() {
    if (!_isComposing) return;
    
    final negotiationProvider = Provider.of<EnhancedNegotiationProvider>(context, listen: false);
    final agentsProvider = Provider.of<AgentsProvider>(context, listen: false);
    final policyDomainsProvider = Provider.of<PolicyDomainsProvider>(context, listen: false);
    
    final message = _messageController.text.trim();
    
    setState(() {
      _isComposing = false;
      _isProcessing = true;
      _messageController.clear();
    });
    
    negotiationProvider.addUserMessage(
      message,
      // agentsProvider.agents,
      // policyDomainsProvider.domains,
    ).then((_) {
      setState(() {
        _isProcessing = false;
      });
    });
  }

  Color _getDiplomatColor(String diplomatId) {
    switch (diplomatId) {
      case 'diplomat1':
        return Colors.purple;
      case 'diplomat2':
        return Colors.blue;
      case 'diplomat3':
        return Colors.orange;
      case 'diplomat4':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getDiplomatIcon(String diplomatId) {
    switch (diplomatId) {
      case 'diplomat1':
        return Icons.diversity_3;
      case 'diplomat2':
        return Icons.balance;
      case 'diplomat3':
        return Icons.lightbulb;
      case 'diplomat4':
        return Icons.people;
      default:
        return Icons.person;
    }
  }
}