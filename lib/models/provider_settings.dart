import 'package:uuid/uuid.dart';

/// ProviderSettings model representing AI provider configuration
class ProviderSettings {
  final String id;
  final String provider;
  final String displayName;
  final String? apiKey;
  final String? apiHost;
  final String? apiPath;
  final String apiMode;
  final List<String> models;
  final bool isDefault;
  final bool isEnabled;
  final DateTime createdAt;
  DateTime updatedAt;

  ProviderSettings({
    String? id,
    required this.provider,
    required this.displayName,
    this.apiKey,
    this.apiHost,
    this.apiPath,
    this.apiMode = 'openai',
    List<String>? models,
    this.isDefault = false,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        models = models ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  /// Get default host for a provider
  static String getDefaultHost(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'https://api.openai.com';
      case 'anthropic':
        return 'https://api.anthropic.com';
      case 'openrouter':
        return 'https://openrouter.ai/api';
      case 'gemini':
        return 'https://generativelanguage.googleapis.com';
      default:
        return '';
    }
  }

  /// Get default models for a provider
  static List<String> getDefaultModels(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-4-turbo',
          'gpt-4',
          'gpt-3.5-turbo',
        ];
      case 'anthropic':
        return [
          'claude-3-5-sonnet-20241022',
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307',
        ];
      case 'openrouter':
        return [
          'openai/gpt-4o',
          'anthropic/claude-3.5-sonnet',
          'google/gemini-pro-1.5',
          'meta-llama/llama-3.1-70b-instruct',
        ];
      case 'gemini':
        return [
          'gemini-1.5-pro',
          'gemini-1.5-flash',
          'gemini-pro',
        ];
      default:
        return [];
    }
  }

  factory ProviderSettings.fromMap(Map<String, dynamic> map) {
    return ProviderSettings(
      id: map['id'] as String,
      provider: map['provider'] as String,
      displayName: map['display_name'] as String,
      apiKey: map['api_key'] as String?,
      apiHost: map['api_host'] as String?,
      apiPath: map['api_path'] as String?,
      apiMode: map['api_mode'] as String? ?? 'openai',
      models: map['models'] != null
          ? (map['models'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      isDefault: (map['is_default'] as int?) == 1,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider,
      'display_name': displayName,
      'api_key': apiKey,
      'api_host': apiHost,
      'api_path': apiPath,
      'api_mode': apiMode,
      'models': models.join(','),
      'is_default': isDefault ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  ProviderSettings copyWith({
    String? id,
    String? provider,
    String? displayName,
    String? apiKey,
    String? apiHost,
    String? apiPath,
    String? apiMode,
    List<String>? models,
    bool? isDefault,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderSettings(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      displayName: displayName ?? this.displayName,
      apiKey: apiKey ?? this.apiKey,
      apiHost: apiHost ?? this.apiHost,
      apiPath: apiPath ?? this.apiPath,
      apiMode: apiMode ?? this.apiMode,
      models: models ?? this.models,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
