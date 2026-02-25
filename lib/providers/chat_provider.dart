import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/message.dart';
import '../models/provider_settings.dart';
import 'database_service.dart';

/// Chat provider for managing chat state
class ChatProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Session> _sessions = [];
  List<ProviderSettings> _providers = [];
  Session? _currentSession;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Session> get sessions => _sessions;
  List<ProviderSettings> get providers => _providers;
  List<ProviderSettings> get configuredProviders =>
      _providers.where((p) => p.isConfigured).toList();
  Session? get currentSession => _currentSession;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all sessions from database
  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _db.getAllSessions();
      _error = null;
    } catch (e) {
      _error = 'Failed to load sessions: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load all providers from database
  Future<void> loadProviders() async {
    try {
      _providers = await _db.getAllProviderSettings();
      
      // Initialize default providers if none exist
      if (_providers.isEmpty) {
        await _initializeDefaultProviders();
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load providers: $e';
      notifyListeners();
    }
  }

  /// Initialize default providers
  Future<void> _initializeDefaultProviders() async {
    final defaultProviders = [
      ProviderSettings(
        provider: 'openai',
        displayName: 'OpenAI',
        models: ProviderSettings.getDefaultModels('openai'),
      ),
      ProviderSettings(
        provider: 'anthropic',
        displayName: 'Anthropic',
        models: ProviderSettings.getDefaultModels('anthropic'),
      ),
      ProviderSettings(
        provider: 'openrouter',
        displayName: 'OpenRouter',
        models: ProviderSettings.getDefaultModels('openrouter'),
      ),
      ProviderSettings(
        provider: 'gemini',
        displayName: 'Google Gemini',
        models: ProviderSettings.getDefaultModels('gemini'),
      ),
    ];

    for (final provider in defaultProviders) {
      await _db.insertProviderSettings(provider);
    }

    _providers = await _db.getAllProviderSettings();
  }

  /// Create a new session
  Future<Session?> createSession({
    String? name,
    required String provider,
    required String model,
    String? systemPrompt,
    double temperature = 0.7,
    double topP = 1.0,
    int maxContext = 20,
    int maxTokens = 4096,
    bool streaming = true,
  }) async {
    try {
      final session = Session(
        name: name ?? 'New Chat',
        provider: provider,
        model: model,
        systemPrompt: systemPrompt,
        temperature: temperature,
        topP: topP,
        maxContext: maxContext,
        maxTokens: maxTokens,
        streaming: streaming,
      );

      await _db.insertSession(session);
      _sessions.insert(0, session);
      notifyListeners();
      return session;
    } catch (e) {
      _error = 'Failed to create session: $e';
      notifyListeners();
      return null;
    }
  }

  /// Select a session and load its messages
  Future<void> selectSession(Session session) async {
    _currentSession = session;
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _db.getMessagesForSession(session.id);
      _error = null;
    } catch (e) {
      _error = 'Failed to load messages: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear current session selection
  void clearCurrentSession() {
    _currentSession = null;
    _messages = [];
    notifyListeners();
  }

  /// Update session
  Future<void> updateSession(Session session) async {
    try {
      await _db.updateSession(session);
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
        if (_currentSession?.id == session.id) {
          _currentSession = session;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update session: $e';
      notifyListeners();
    }
  }

  /// Delete a session
  Future<void> deleteSession(Session session) async {
    try {
      await _db.deleteSession(session.id);
      _sessions.removeWhere((s) => s.id == session.id);
      if (_currentSession?.id == session.id) {
        _currentSession = null;
        _messages = [];
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete session: $e';
      notifyListeners();
    }
  }

  /// Toggle session starred status
  Future<void> toggleStarred(Session session) async {
    final updated = session.copyWith(isStarred: !session.isStarred);
    await updateSession(updated);
  }

  /// Rename session
  Future<void> renameSession(Session session, String newName) async {
    final updated = session.copyWith(name: newName);
    await updateSession(updated);
  }

  /// Add a message to the current session
  Future<Message?> addMessage({
    required String role,
    required String content,
    String? aiProvider,
    String? model,
  }) async {
    if (_currentSession == null) return null;

    try {
      final message = Message(
        sessionId: _currentSession!.id,
        role: role,
        content: content,
        aiProvider: aiProvider,
        model: model,
      );

      await _db.insertMessage(message);
      _messages.add(message);
      notifyListeners();
      return message;
    } catch (e) {
      _error = 'Failed to add message: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a message
  Future<void> updateMessage(Message message) async {
    try {
      await _db.updateMessage(message);
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update message: $e';
      notifyListeners();
    }
  }

  /// Delete a message
  Future<void> deleteMessage(Message message) async {
    try {
      await _db.deleteMessage(message.id);
      _messages.removeWhere((m) => m.id == message.id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete message: $e';
      notifyListeners();
    }
  }

  /// Update provider settings
  Future<void> updateProviderSettings(ProviderSettings settings) async {
    try {
      await _db.updateProviderSettings(settings);
      final index = _providers.indexWhere((p) => p.id == settings.id);
      if (index != -1) {
        _providers[index] = settings;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update provider: $e';
      notifyListeners();
    }
  }

  /// Get provider by name
  ProviderSettings? getProvider(String providerName) {
    try {
      return _providers.firstWhere((p) => p.provider == providerName);
    } catch (_) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
