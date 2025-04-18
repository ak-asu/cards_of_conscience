import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/agent_model.dart';
import '../models/chat_message.dart';
import 'emotion_model_service.dart';
import 'analytics_service.dart';

class ChatService with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final Map<String, List<ChatMessage>> _messagesByTopic = {};
  final String _messagesStorageKey = 'chat_messages';
  final AnalyticsService _analytics = AnalyticsService();
  final EmotionModelService _emotionService;
  final Uuid _uuid = const Uuid();
  String? _currentTopicId;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => 
      _currentTopicId != null && _messagesByTopic.containsKey(_currentTopicId!)
          ? List.unmodifiable(_messagesByTopic[_currentTopicId]!)
          : List.unmodifiable(_messages);
          
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatService({EmotionModelService? emotionService}) 
      : _emotionService = emotionService ?? EmotionModelService() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _loadMessages();
      
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize chat service: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getString(_messagesStorageKey);
      
      if (savedMessages != null) {
        final Map<String, dynamic> data = jsonDecode(savedMessages);
        
        // Handle messages not associated with a topic
        if (data.containsKey('general')) {
          final List<dynamic> generalMessages = data['general'];
          _messages.clear();
          _messages.addAll(generalMessages
              .map((m) => ChatMessage.fromJson(m))
              .toList());
        }
        
        // Handle messages by topic
        _messagesByTopic.clear();
        data.forEach((key, value) {
          if (key != 'general') {
            final List<dynamic> topicMessages = value;
            _messagesByTopic[key] = topicMessages
                .map((m) => ChatMessage.fromJson(m))
                .toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'general': _messages.map((m) => m.toJson()).toList(),
      };
      
      _messagesByTopic.forEach((topicId, messages) {
        data[topicId] = messages.map((m) => m.toJson()).toList();
      });
      
      await prefs.setString(_messagesStorageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save messages: $e');
    }
  }

  Future<void> setCurrentTopic(String topicId) async {
    _currentTopicId = topicId;
    
    if (!_messagesByTopic.containsKey(topicId)) {
      _messagesByTopic[topicId] = [];
    }
    
    notifyListeners();
  }

  Future<void> clearCurrentTopic() async {
    _currentTopicId = null;
    notifyListeners();
  }

  Future<ChatMessage> addUserMessage(String text) async {
    await _init();
    
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: 'user',
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
    );
    
    if (_currentTopicId != null) {
      if (!_messagesByTopic.containsKey(_currentTopicId!)) {
        _messagesByTopic[_currentTopicId!] = [];
      }
      _messagesByTopic[_currentTopicId!]!.add(message);
    } else {
      _messages.add(message);
    }
    
    // Log analytics
    await _analytics.logUserMessage(
      topicId: _currentTopicId ?? 'general',
      isVoiceMessage: false,
      characterCount: text.length,
    );
    
    await _saveMessages();
    notifyListeners();
    
    return message;
  }

  Future<ChatMessage> addAgentMessage(String text, Agent agent) async {
    await _init();
    
    // Apply emotional state to message if available
    String emotionalText = text;
    try {
      emotionalText = _emotionService.generateEmotionalResponse(
        agent.id, 
        text,
        _currentTopicId ?? 'general_conversation',
      );
    } catch (e) {
      debugPrint('Error applying emotion to message: $e');
    }
    
    final message = ChatMessage(
      senderId: agent.id,
      senderName: agent.name,
      content: emotionalText,
      timestamp: DateTime.now(),
    );
    
    if (_currentTopicId != null) {
      if (!_messagesByTopic.containsKey(_currentTopicId!)) {
        _messagesByTopic[_currentTopicId!] = [];
      }
      _messagesByTopic[_currentTopicId!]!.add(message);
    } else {
      _messages.add(message);
    }
    
    // Log analytics
    await _analytics.logAgentResponse(
      agentId: agent.id,
      topicId: _currentTopicId ?? 'general',
      messageType: 'text',
      characterCount: text.length,
    );
    
    await _saveMessages();
    notifyListeners();
    
    return message;
  }

  Future<ChatMessage> addSystemMessage(String text) async {
    await _init();
    
    final message = ChatMessage(
      senderId: 'system',
      senderName: 'System',
      content: text,
      timestamp: DateTime.now(),
    );
    
    if (_currentTopicId != null) {
      if (!_messagesByTopic.containsKey(_currentTopicId!)) {
        _messagesByTopic[_currentTopicId!] = [];
      }
      _messagesByTopic[_currentTopicId!]!.add(message);
    } else {
      _messages.add(message);
    }
    
    await _saveMessages();
    notifyListeners();
    
    return message;
  }

  Future<void> deleteMessage(String messageId) async {
    await _init();
    
    if (_currentTopicId != null && _messagesByTopic.containsKey(_currentTopicId!)) {
      _messagesByTopic[_currentTopicId!]!.removeWhere((m) => m.id == messageId);
    } else {
      _messages.removeWhere((m) => m.id == messageId);
    }
    
    await _saveMessages();
    notifyListeners();
  }

  Future<void> updateMessage(String messageId, String newText) async {
    await _init();
    
    if (_currentTopicId != null && _messagesByTopic.containsKey(_currentTopicId!)) {
      final index = _messagesByTopic[_currentTopicId!]!.indexWhere((m) => m.id == messageId);
      
      if (index >= 0) {
        final oldMessage = _messagesByTopic[_currentTopicId!]![index];
        _messagesByTopic[_currentTopicId!]![index] = oldMessage.copyWith(content: newText);
      }
    } else {
      final index = _messages.indexWhere((m) => m.id == messageId);
      
      if (index >= 0) {
        final oldMessage = _messages[index];
        _messages[index] = oldMessage.copyWith(content: newText);
      }
    }
    
    await _saveMessages();
    notifyListeners();
  }
}