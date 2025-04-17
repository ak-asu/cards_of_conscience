import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../phase_one/models/agent_model.dart';
import '../../../phase_one/providers/policy_selection_provider.dart' show AgentsProvider;
import '../../ai_enhancements/emotion_model_service.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class TextChatInterface extends StatefulWidget {
  const TextChatInterface({super.key});

  @override
  State<TextChatInterface> createState() => _TextChatInterfaceState();
}

class _TextChatInterfaceState extends State<TextChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Auto-scroll to bottom when new messages come in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
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
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    await chatService.addUserMessage(text);
    _messageController.clear();
    _messageFocusNode.requestFocus();
    
    // Auto-scroll to bottom
    _scrollToBottom();
    
    // Trigger AI responses (in real implementation)
    // This would connect to the negotiation provider to trigger AI messages
    // based on the context of the discussion
  }
  
  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    return Column(
      children: [
        Expanded(
          child: _buildChatMessages(context, chatService),
        ),
        _buildInputArea(context),
      ],
    );
  }
  
  Widget _buildChatMessages(BuildContext context, ChatService chatService) {
    if (chatService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (chatService.error != null) {
      return Center(
        child: Text(
          'Error: ${chatService.error}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    
    final messages = chatService.messages;
    
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation with the AI diplomats',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Check if we need to scroll to bottom after new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (maxScroll - currentScroll < 200) {
          _scrollToBottom();
        }
      }
    });
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUserMessage = message.sender == 'user';
        
        // Group consecutive messages from the same sender
        final showAvatar = index == 0 || 
            messages[index - 1].sender != message.sender;
        
        return _buildMessageItem(
          context, 
          message,
          isUserMessage, 
          showAvatar,
        ).animate().fadeIn(
          duration: 300.ms,
          delay: (50 * index).ms,
        ).slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          delay: (50 * index).ms,
          curve: Curves.easeOutQuad,
        );
      },
    );
  }
  
  Widget _buildMessageItem(
    BuildContext context, 
    ChatMessage message, 
    bool isUserMessage, 
    bool showAvatar,
  ) {
    final emotionService = Provider.of<EmotionModelService>(context, listen: false);
    final agentsProvider = Provider.of<AgentsProvider>(context, listen: false);
    
    // Get agent info if it's not a user message
    Widget avatar;
    Color bubbleColor;
    Color textColor;
    
    if (isUserMessage) {
      avatar = const CircleAvatar(
        child: Icon(Icons.person),
      );
      bubbleColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else {
      // Find agent by ID
      final agent = agentsProvider.agents.firstWhere(
        (a) => a.id == message.sender,
        orElse: () => Agent(
          id: message.sender,
          name: 'Unknown Agent',
          age: 0,
          occupation: 'Unknown',
          education: 'Unknown',
          socioeconomicStatus: 'Unknown',
          ideology: 'Unknown',
        ),
      );
      
      // Get emotion state for visual cues
      final emotionState = emotionService.getAgentEmotionState(message.sender);
      final dominantEmotion = emotionState.getDominantEmotion();
      
      // Choose avatar icon based on agent
      IconData avatarIcon;
      Color avatarColor;
      
      switch (message.sender) {
        case 'diplomat1':
          avatarIcon = Icons.diversity_3;
          avatarColor = Colors.purple;
          break;
        case 'diplomat2':
          avatarIcon = Icons.balance;
          avatarColor = Colors.blue;
          break;
        case 'diplomat3':
          avatarIcon = Icons.lightbulb;
          avatarColor = Colors.orange;
          break;
        case 'diplomat4':
          avatarIcon = Icons.people;
          avatarColor = Colors.green;
          break;
        default:
          avatarIcon = Icons.person;
          avatarColor = Colors.grey;
      }
      
      // Add emotion to avatar if applicable
      if (dominantEmotion != 'neutral') {
        avatar = Stack(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Icon(avatarIcon, color: avatarColor),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEmotionIcon(dominantEmotion),
                  size: 12,
                  color: _getEmotionColor(dominantEmotion),
                ),
              ),
            ),
          ],
        );
      } else {
        avatar = CircleAvatar(
          backgroundColor: avatarColor.withOpacity(0.2),
          child: Icon(avatarIcon, color: avatarColor),
        );
      }
      
      bubbleColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isUserMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage && showAvatar) ...[
            avatar,
            const SizedBox(width: 8),
          ] else if (!isUserMessage) ...[
            const SizedBox(width: 36),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!isUserMessage && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                    child: Text(
                      agentsProvider.agents.firstWhere(
                        (a) => a.id == message.sender,
                        orElse: () => Agent(
                          id: message.sender,
                          name: 'Unknown',
                          age: 0,
                          occupation: 'Unknown',
                          education: 'Unknown',
                          socioeconomicStatus: 'Unknown',
                          ideology: 'Unknown',
                        ),
                      ).name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUserMessage && showAvatar) ...[
            const SizedBox(width: 8),
            avatar,
          ] else if (isUserMessage) ...[
            const SizedBox(width: 8),
            const SizedBox(width: 36),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (today == messageDate) {
      return 'Today at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (today.subtract(const Duration(days: 1)) == messageDate) {
      return 'Yesterday at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
  
  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happiness': return Icons.sentiment_very_satisfied;
      case 'anger': return Icons.sentiment_very_dissatisfied;
      case 'fear': return Icons.sentiment_dissatisfied;
      case 'surprise': return Icons.sentiment_neutral;
      case 'disgust': return Icons.sick;
      case 'sadness': return Icons.sentiment_dissatisfied;
      case 'trust': return Icons.thumb_up;
      case 'anticipation': return Icons.watch_later;
      default: return Icons.sentiment_neutral;
    }
  }
  
  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'happiness': return Colors.amber;
      case 'anger': return Colors.red;
      case 'fear': return Colors.purple;
      case 'surprise': return Colors.blue;
      case 'disgust': return Colors.green;
      case 'sadness': return Colors.indigo;
      case 'trust': return Colors.teal;
      case 'anticipation': return Colors.orange;
      default: return Colors.grey;
    }
  }
}