import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'agent_model.dart' show Agent;

enum MessageType {
  text,
  system,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isFromUser;
  final String? stage;
  final String? topic;

  // Add getters for backward compatibility
  String get sender => senderId;
  String get text => content;

  ChatMessage({
    String? id,
    required this.senderId,
    required this.senderName,
    required this.content,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.isFromUser = false,
    this.stage,
    this.topic,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isFromUser,
    String? stage,
    String? topic,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isFromUser: isFromUser ?? this.isFromUser,
      stage: stage ?? this.stage,
      topic: topic ?? this.topic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isFromUser': isFromUser,
      'stage': stage,
      'topic': topic,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      isFromUser: json['isFromUser'] ?? false,
      stage: json['stage'],
      topic: json['topic'],
    );
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }

  static ChatMessage createSystemMessage(String content) {
    return ChatMessage(
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
    );
  }

  static ChatMessage createAgentMessage(Agent agent, String content) {
    return ChatMessage(
      senderId: agent.id,
      senderName: agent.name,
      content: content,
    );
  }

  static ChatMessage createUserMessage(String content) {
    return ChatMessage(
      senderId: 'user',
      senderName: 'You',
      content: content,
      isFromUser: true,
    );
  }
}