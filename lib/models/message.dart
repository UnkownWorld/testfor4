import 'package:uuid/uuid.dart';

/// Message model representing a chat message
class Message {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? aiProvider;
  final String? model;
  final bool generating;
  final String? error;
  final int? errorCode;
  final String? reasoningContent;
  final int? tokenCount;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final DateTime timestamp;
  final DateTime updatedAt;
  final String? finishReason;

  Message({
    String? id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.aiProvider,
    this.model,
    this.generating = false,
    this.error,
    this.errorCode,
    this.reasoningContent,
    this.tokenCount,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    DateTime? timestamp,
    DateTime? updatedAt,
    this.finishReason,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Message roles
  static const String roleSystem = 'system';
  static const String roleUser = 'user';
  static const String roleAssistant = 'assistant';
  static const String roleTool = 'tool';

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String? ?? '',
      aiProvider: map['ai_provider'] as String?,
      model: map['model'] as String?,
      generating: (map['generating'] as int?) == 1,
      error: map['error'] as String?,
      errorCode: map['error_code'] as int?,
      reasoningContent: map['reasoning_content'] as String?,
      tokenCount: map['token_count'] as int?,
      inputTokens: map['input_tokens'] as int?,
      outputTokens: map['output_tokens'] as int?,
      totalTokens: map['total_tokens'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      finishReason: map['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'ai_provider': aiProvider,
      'model': model,
      'generating': generating ? 1 : 0,
      'error': error,
      'error_code': errorCode,
      'reasoning_content': reasoningContent,
      'token_count': tokenCount,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'total_tokens': totalTokens,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'finish_reason': finishReason,
    };
  }

  bool get isUser => role == roleUser;
  bool get isAssistant => role == roleAssistant;
  bool get isSystem => role == roleSystem;
  bool get hasError => error != null && error!.isNotEmpty;

  String get contentPreview {
    if (content.isEmpty) return '';
    if (content.length > 100) return '${content.substring(0, 100)}...';
    return content;
  }

  Message copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? content,
    String? aiProvider,
    String? model,
    bool? generating,
    String? error,
    int? errorCode,
    String? reasoningContent,
    int? tokenCount,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? finishReason,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      aiProvider: aiProvider ?? this.aiProvider,
      model: model ?? this.model,
      generating: generating ?? this.generating,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      tokenCount: tokenCount ?? this.tokenCount,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      finishReason: finishReason ?? this.finishReason,
    );
  }
}
