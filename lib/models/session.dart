import 'package:uuid/uuid.dart';

/// Session model representing a chat session
class Session {
  final String id;
  String name;
  final String provider;
  final String model;
  final String? systemPrompt;
  final double temperature;
  final double topP;
  final int maxContext;
  final int maxTokens;
  final bool streaming;
  bool isStarred;
  final DateTime createdAt;
  DateTime updatedAt;

  Session({
    String? id,
    required this.name,
    required this.provider,
    required this.model,
    this.systemPrompt,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.maxContext = 20,
    this.maxTokens = 4096,
    this.streaming = true,
    this.isStarred = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      name: map['name'] as String,
      provider: map['provider'] as String,
      model: map['model'] as String,
      systemPrompt: map['system_prompt'] as String?,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (map['top_p'] as num?)?.toDouble() ?? 1.0,
      maxContext: map['max_context'] as int? ?? 20,
      maxTokens: map['max_tokens'] as int? ?? 4096,
      streaming: (map['streaming'] as int?) == 1,
      isStarred: (map['is_starred'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'model': model,
      'system_prompt': systemPrompt,
      'temperature': temperature,
      'top_p': topP,
      'max_context': maxContext,
      'max_tokens': maxTokens,
      'streaming': streaming ? 1 : 0,
      'is_starred': isStarred ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Session copyWith({
    String? id,
    String? name,
    String? provider,
    String? model,
    String? systemPrompt,
    double? temperature,
    double? topP,
    int? maxContext,
    int? maxTokens,
    bool? streaming,
    bool? isStarred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxContext: maxContext ?? this.maxContext,
      maxTokens: maxTokens ?? this.maxTokens,
      streaming: streaming ?? this.streaming,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
