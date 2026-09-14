import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant }

@immutable
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  /// True while waiting for the AI to respond (shown as typing indicator)
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_user',
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.loading() => ChatMessage(
        id: 'loading',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
      );

  /// Convert to Gemini API "contents" format
  Map<String, dynamic> toGeminiJson() => {
        'role': role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': content},
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChatMessage && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
