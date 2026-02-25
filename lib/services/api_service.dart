import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/provider_settings.dart';

/// Chat request model for API calls
class ChatRequest {
  final String model;
  final List<Map<String, String>> messages;
  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final bool stream;

  ChatRequest({
    required this.model,
    required this.messages,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.stream = true,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': stream,
    };
    if (temperature != null) json['temperature'] = temperature;
    if (topP != null) json['top_p'] = topP;
    if (maxTokens != null) json['max_tokens'] = maxTokens;
    return json;
  }
}

/// Chat response model for API responses
class ChatResponse {
  final String? content;
  final String? finishReason;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  ChatResponse({
    this.content,
    this.finishReason,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });
}

/// Callback interface for streaming responses
abstract class ChatCallback {
  void onStart();
  void onChunk(String chunk);
  void onComplete(ChatResponse response);
  void onError(String error);
}

/// OpenAI-compatible API service
class OpenAIService {
  final ProviderSettings settings;
  final Dio _dio;
  CancelToken? _cancelToken;

  OpenAIService(this.settings) : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 120),
    sendTimeout: const Duration(seconds: 60),
  ));

  /// Build the API URL
  String _buildApiUrl() {
    String apiHost = settings.apiHost ?? ProviderSettings.getDefaultHost(settings.provider);
    String apiPath = settings.apiPath ?? '/v1/chat/completions';
    
    // Ensure proper URL formatting
    if (!apiHost.startsWith('http://') && !apiHost.startsWith('https://')) {
      apiHost = 'https://$apiHost';
    }
    
    // Remove trailing slash from host
    if (apiHost.endsWith('/')) {
      apiHost = apiHost.substring(0, apiHost.length - 1);
    }
    
    // Ensure path starts with /
    if (!apiPath.startsWith('/')) {
      apiPath = '/$apiPath';
    }
    
    return '$apiHost$apiPath';
  }

  /// Send a chat completion request
  Future<void> chatCompletion(
    ChatRequest request,
    ChatCallback callback, {
    bool stream = true,
  }) async {
    if (!settings.isConfigured) {
      callback.onError('Provider not configured');
      return;
    }

    final url = _buildApiUrl();
    final headers = <String, String>{
      'Authorization': 'Bearer ${settings.apiKey}',
      'Content-Type': 'application/json',
    };

    // Add OpenRouter specific headers
    if (settings.provider.toLowerCase() == 'openrouter') {
      headers['HTTP-Referer'] = 'https://chatboxai.app';
      headers['X-Title'] = 'Chatbox AI';
    }

    final requestBody = ChatRequest(
      model: request.model,
      messages: request.messages,
      temperature: request.temperature,
      topP: request.topP,
      maxTokens: request.maxTokens,
      stream: stream,
    ).toJson();

    _cancelToken = CancelToken();
    callback.onStart();

    try {
      if (stream) {
        await _handleStreamingRequest(url, headers, requestBody, callback);
      } else {
        await _handleSyncRequest(url, headers, requestBody, callback);
      }
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        callback.onError('Network error: ${e.message}');
      }
    } catch (e) {
      callback.onError('Error: $e');
    }
  }

  /// Handle streaming request
  Future<void> _handleStreamingRequest(
    String url,
    Map<String, String> headers,
    Map<String, dynamic> body,
    ChatCallback callback,
  ) async {
    final response = await _dio.post(
      url,
      data: body,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
      cancelToken: _cancelToken,
    );

    final stream = response.data.stream;
    final buffer = StringBuffer();
    String fullContent = '';
    String? finishReason;
    int? promptTokens;
    int? completionTokens;
    int? totalTokens;

    await for (final chunk in stream) {
      final text = utf8.decode(chunk);
      buffer.write(text);

      // Process complete lines
      final lines = buffer.toString().split('\n');
      buffer.clear();

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        final data = line.substring(6);
        if (data == '[DONE]') continue;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;
          if (delta == null) continue;

          final content = delta['content'] as String?;
          if (content != null && content.isNotEmpty) {
            fullContent += content;
            callback.onChunk(content);
          }

          if (choice['finish_reason'] != null) {
            finishReason = choice['finish_reason'] as String;
          }

          // Check for usage info
          final usage = json['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            promptTokens = usage['prompt_tokens'] as int?;
            completionTokens = usage['completion_tokens'] as int?;
            totalTokens = usage['total_tokens'] as int?;
          }
        } catch (_) {
          // Ignore parsing errors for individual chunks
        }
      }

      // Keep the last incomplete line in buffer
      if (lines.isNotEmpty) {
        buffer.write(lines.last);
      }
    }

    callback.onComplete(ChatResponse(
      content: fullContent,
      finishReason: finishReason,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
    ));
  }

  /// Handle synchronous request
  Future<void> _handleSyncRequest(
    String url,
    Map<String, String> headers,
    Map<String, dynamic> body,
    ChatCallback callback,
  ) async {
    final response = await _dio.post(
      url,
      data: body,
      options: Options(headers: headers),
      cancelToken: _cancelToken,
    );

    final json = response.data as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    final usage = json['usage'] as Map<String, dynamic>?;

    if (choices == null || choices.isEmpty) {
      callback.onError('Invalid response: no choices');
      return;
    }

    final choice = choices.first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    final finishReason = choice['finish_reason'] as String?;

    if (content != null) {
      callback.onChunk(content);
    }

    callback.onComplete(ChatResponse(
      content: content,
      finishReason: finishReason,
      promptTokens: usage?['prompt_tokens'] as int?,
      completionTokens: usage?['completion_tokens'] as int?,
      totalTokens: usage?['total_tokens'] as int?,
    ));
  }

  /// Cancel the current request
  void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  /// Check if a request is in progress
  bool get isInProgress => _cancelToken != null && !_cancelToken!.isCancelled;
}
