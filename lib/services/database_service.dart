import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../models/message.dart';
import '../models/provider_settings.dart';

/// Database service for managing local data
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'chatbox.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider TEXT NOT NULL,
        model TEXT NOT NULL,
        system_prompt TEXT,
        temperature REAL DEFAULT 0.7,
        top_p REAL DEFAULT 1.0,
        max_context INTEGER DEFAULT 20,
        max_tokens INTEGER DEFAULT 4096,
        streaming INTEGER DEFAULT 1,
        is_starred INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT,
        ai_provider TEXT,
        model TEXT,
        generating INTEGER DEFAULT 0,
        error TEXT,
        error_code INTEGER,
        reasoning_content TEXT,
        token_count INTEGER,
        input_tokens INTEGER,
        output_tokens INTEGER,
        total_tokens INTEGER,
        timestamp INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        finish_reason TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create provider_settings table
    await db.execute('''
      CREATE TABLE provider_settings (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        api_key TEXT,
        api_host TEXT,
        api_path TEXT,
        api_mode TEXT DEFAULT 'openai',
        models TEXT,
        is_default INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_messages_session_id ON messages (session_id)');
    await db.execute('CREATE INDEX idx_sessions_updated_at ON sessions (updated_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
  }

  // ==================== Session Operations ====================

  Future<String> insertSession(Session session) async {
    final db = await database;
    await db.insert('sessions', session.toMap());
    return session.id;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<Session?> getSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Message Operations ====================

  Future<String> insertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
    return message.id;
  }

  Future<List<Message>> getMessagesForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<void> updateMessage(Message message) async {
    final db = await database;
    await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMessagesForSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // ==================== Provider Settings Operations ====================

  Future<String> insertProviderSettings(ProviderSettings settings) async {
    final db = await database;
    await db.insert('provider_settings', settings.toMap());
    return settings.id;
  }

  Future<List<ProviderSettings>> getAllProviderSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provider_settings',
      orderBy: 'display_name ASC',
    );
    return List.generate(maps.length, (i) => ProviderSettings.fromMap(maps[i]));
  }

  Future<ProviderSettings?> getProviderSettings(String provider) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provider_settings',
      where: 'provider = ?',
      whereArgs: [provider],
    );
    if (maps.isEmpty) return null;
    return ProviderSettings.fromMap(maps.first);
  }

  Future<void> updateProviderSettings(ProviderSettings settings) async {
    final db = await database;
    await db.update(
      'provider_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<void> deleteProviderSettings(String id) async {
    final db = await database;
    await db.delete(
      'provider_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProviderSettings>> getConfiguredProviders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provider_settings',
      where: 'api_key IS NOT NULL AND api_key != ? AND is_enabled = ?',
      whereArgs: ['', 1],
      orderBy: 'display_name ASC',
    );
    return List.generate(maps.length, (i) => ProviderSettings.fromMap(maps[i]));
  }
}
