import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper para base de datos SQLite local.
/// Usa SQL cipher para encriptación de datos sensibles.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'travelready.db';
  static const int _databaseVersion = 3;

  // Tablas
  static const String tableUsers = 'users';
  static const String tableTrips = 'trips';
  static const String tableTripTransport = 'trip_transport';
  static const String tableTripActivities = 'trip_activities';
  static const String tablePackingLists = 'packing_lists';
  static const String tablePackingItems = 'packing_items';
  static const String tableChats = 'chats';
  static const String tableChatMembers = 'chat_members';
  static const String tableMessages = 'messages';
  static const String tableSessions = 'user_sessions';
  static const String tableWeatherCache = 'weather_cache';
  static const String tablePlaceFavorites = 'place_favorites';
  static const String tablePlaceDislikes = 'place_dislikes';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await createSchema(db, version);
  }

  /// Creates the current schema for a new database without inserting data.
  static Future<void> createSchema(Database db, int version) async {
    // 1. Tabla de usuarios
    await db.execute('''
      CREATE TABLE $tableUsers (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255),
        plan VARCHAR(10) DEFAULT 'free',
        plan_renewal_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        photo_url TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_users_email ON $tableUsers(email)
    ''');

    // 2. Tabla de viajes
    await db.execute('''
      CREATE TABLE $tableTrips (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL,
        destination VARCHAR(200) NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        trip_type VARCHAR(20) DEFAULT 'city',
        progress INTEGER DEFAULT 0 CHECK(progress >= 0 AND progress <= 100),
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_user_id ON $tableTrips(user_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_trips_dates ON $tableTrips(start_date, end_date)
    ''');

    // 3. Tabla de transportes (relación N:M con trips)
    await db.execute('''
      CREATE TABLE $tableTripTransport (
        trip_id VARCHAR(36) NOT NULL,
        transport_type VARCHAR(20) NOT NULL,
        PRIMARY KEY (trip_id, transport_type),
        FOREIGN KEY (trip_id) REFERENCES $tableTrips(id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla de actividades
    await db.execute('''
      CREATE TABLE $tableTripActivities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id VARCHAR(36) NOT NULL,
        activity VARCHAR(100) NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES $tableTrips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_activities_trip ON $tableTripActivities(trip_id)
    ''');

    // 5. Tabla de listas de equipaje
    await db.execute('''
      CREATE TABLE $tablePackingLists (
        id VARCHAR(36) PRIMARY KEY,
        trip_id VARCHAR(36) NOT NULL,
        user_id VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES $tableTrips(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_lists_trip ON $tablePackingLists(trip_id)
    ''');

    // 6. Tabla de items de equipaje
    await db.execute('''
      CREATE TABLE $tablePackingItems (
        id VARCHAR(36) PRIMARY KEY,
        list_id VARCHAR(36) NOT NULL,
        trip_id VARCHAR(36) NOT NULL,
        user_id VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL,
        category VARCHAR(20) DEFAULT 'other',
        is_packed INTEGER DEFAULT 0,
        is_auto_generated INTEGER DEFAULT 0,
        quantity INTEGER DEFAULT 1,
        order_index INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (list_id) REFERENCES $tablePackingLists(id) ON DELETE CASCADE,
        FOREIGN KEY (trip_id) REFERENCES $tableTrips(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_items_list ON $tablePackingItems(list_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_items_category ON $tablePackingItems(category)
    ''');

    // 7. Tabla de chats
    await db.execute('''
      CREATE TABLE $tableChats (
        id VARCHAR(36) PRIMARY KEY,
        type VARCHAR(20) DEFAULT 'support',
        name VARCHAR(100),
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 8. Tabla de miembros de chat
    await db.execute('''
      CREATE TABLE $tableChatMembers (
        chat_id VARCHAR(36) NOT NULL,
        user_id VARCHAR(36) NOT NULL,
        joined_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (chat_id, user_id),
        FOREIGN KEY (chat_id) REFERENCES $tableChats(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    // 9. Tabla de mensajes
    await db.execute('''
      CREATE TABLE $tableMessages (
        id VARCHAR(36) PRIMARY KEY,
        chat_id VARCHAR(36) NOT NULL,
        sender_id VARCHAR(36) NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (chat_id) REFERENCES $tableChats(id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_chat ON $tableMessages(chat_id)
    ''');

    // 10. Tabla de sesiones (para seguridad)
    await db.execute('''
      CREATE TABLE $tableSessions (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        token VARCHAR(255) NOT NULL,
        device_info TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        expires_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_token ON $tableSessions(token)
    ''');

    // Trigger para actualizar updated_at en trips
    await db.execute('''
      CREATE TRIGGER update_trips_timestamp 
      AFTER UPDATE ON $tableTrips
      BEGIN
        UPDATE $tableTrips SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
      END
    ''');

    // Trigger para actualizar updated_at en packing_lists
    await db.execute('''
      CREATE TRIGGER update_lists_timestamp 
      AFTER UPDATE ON $tablePackingLists
      BEGIN
        UPDATE $tablePackingLists SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
      END
    ''');

    // Trigger para actualizar updated_at en packing_items
    await db.execute('''
      CREATE TRIGGER update_items_timestamp 
      AFTER UPDATE ON $tablePackingItems
      BEGIN
        UPDATE $tablePackingItems SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
      END
    ''');

    await _createWeatherCacheTable(db);
    await createReactionTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await upgradeSchema(db, oldVersion, newVersion);
  }

  /// Additive migration: sqflite runs onUpgrade in a transaction and advances
  /// user_version only after it succeeds. Existing tables and rows are untouched.
  static Future<void> upgradeSchema(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createWeatherCacheTable(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await createReactionTables(db);
    }
  }

  static Future<void> _createWeatherCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableWeatherCache (
        location_key TEXT PRIMARY KEY,
        weather_json TEXT NOT NULL,
        retrieved_at TEXT NOT NULL
      )
    ''');
  }

  /// Swipe-feed reactions of the signed-in account (v3).
  ///
  /// Rows carry `account_id` (the signed-in user id, the same value the trips
  /// and chats stores key on) with a composite primary key
  /// `(account_id, place_key)`: two accounts on the same device never see each
  /// other's favorites or dislikes, and signing out cannot leak them.
  ///
  /// `place_favorites` keeps only the provider-neutral snapshot fields the
  /// traveller chose to keep. `place_dislikes` deliberately keeps the key and a
  /// timestamp and nothing else: "do not recommend this again" needs no venue
  /// data. Idempotent, so the datasource can also call it lazily on databases
  /// opened without going through [createSchema] or [upgradeSchema].
  static Future<void> createReactionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePlaceFavorites (
        account_id TEXT NOT NULL,
        place_key TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        website_uri TEXT,
        opening_hours_text TEXT,
        price_level_label TEXT,
        created_at TEXT NOT NULL,
        PRIMARY KEY (account_id, place_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePlaceDislikes (
        account_id TEXT NOT NULL,
        place_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (account_id, place_key)
      )
    ''');
  }

  // Métodos utilitarios
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Utilidad para transacciones
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Queries comunes
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
}
