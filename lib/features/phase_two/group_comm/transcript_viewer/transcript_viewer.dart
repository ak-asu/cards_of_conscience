import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

class TranscriptViewer extends StatefulWidget {
  const TranscriptViewer({super.key});

  @override
  State<TranscriptViewer> createState() => _TranscriptViewerState();
}

class _TranscriptViewerState extends State<TranscriptViewer> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedFilter;
  List<String> _senders = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSendersList();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _updateSendersList() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final messages = chatService.messages;
    
    final Set<String> senders = messages.map((m) => m.sender).toSet();
    setState(() {
      _senders = senders.toList();
    });
  }
  
  List<ChatMessage> _getFilteredMessages() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final messages = chatService.messages;
    
    if (_selectedFilter == null) {
      return messages;
    } else {
      return messages.where((m) => m.sender == _selectedFilter).toList();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
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
    
    // Update senders list when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSendersList();
    });
    
    final messages = _getFilteredMessages();
    
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No transcript available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedFilter != null)
              Text(
                'Try removing the filter to see all messages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              )
            else
              Text(
                'Start a conversation to build a transcript',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        if (_senders.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Filter by: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._senders.map((sender) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_getSenderName(sender)),
                      selected: _selectedFilter == sender,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = sender;
                        });
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildTranscriptEntry(context, message, index)
                .animate().fadeIn(
                  duration: 300.ms,
                  delay: (30 * index).ms,
                );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTranscriptEntry(BuildContext context, ChatMessage message, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getSenderName(message.sender),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.text),
          ],
        ),
      ),
    );
  }
  
  String _getSenderName(String senderId) {
    switch (senderId) {
      case 'user': return 'You';
      case 'system': return 'System';
      case 'diplomat1': return 'Progressive Diplomat';
      case 'diplomat2': return 'Pragmatic Diplomat';
      case 'diplomat3': return 'Technocratic Diplomat';
      case 'diplomat4': return 'Traditional Diplomat';
      default: return senderId;
    }
  }
}