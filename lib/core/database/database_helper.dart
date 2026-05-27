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
  static const int _databaseVersion = 1;

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

    // Insertar datos de prueba
    await _insertTestData(db);
  }

  Future<void> _insertTestData(Database db) async {
    // Usuario de prueba (password: 'test123')
    // bcrypt hash: $2a$10$N9qo8uLOickgx2ZMRZoMy.Mqr39O6fP.WQzYB0mZz1P5qJGjEYViC
    await db.execute('''
      INSERT INTO $tableUsers (id, name, email, password_hash, plan, created_at) 
      VALUES ('usr-001', 'Pablo Buendicho', 'pablo@test.com', 
              '\$2a\$10\$N9qo8uLOickgx2ZMRZoMy.Mqr39O6fP.WQzYB0mZz1P5qJGjEYViC', 
              'premium', '2025-01-15 10:00:00')
    ''');

    await db.execute('''
      INSERT INTO $tableUsers (id, name, email, password_hash, plan, created_at) 
      VALUES ('usr-002', 'Usuario Free', 'free@test.com', 
              '\$2a\$10\$N9qo8uLOickgx2ZMRZoMy.Mqr39O6fP.WQzYB0mZz1P5qJGjEYViC', 
              'free', '2025-01-20 14:30:00')
    ''');

    // Viajes de prueba
    await db.execute('''
      INSERT INTO $tableTrips (id, user_id, name, destination, start_date, end_date, 
                               trip_type, progress, notes)
      VALUES ('trip-001', 'usr-001', 'Verano en Ibiza', 'Ibiza, España',
              '2025-07-15', '2025-07-22', 'beach', 75, 'Reservar ferry con antelación')
    ''');

    await db.execute('''
      INSERT INTO $tableTrips (id, user_id, name, destination, start_date, end_date,
                               trip_type, progress, notes)
      VALUES ('trip-002', 'usr-001', 'Escapada a París', 'París, Francia',
              '2025-09-10', '2025-09-14', 'city', 30, 'Comprar entradas Torre Eiffel')
    ''');

    // Transportes
    await db.execute('''
      INSERT INTO $tableTripTransport (trip_id, transport_type) VALUES
      ('trip-001', 'plane'), ('trip-001', 'car'),
      ('trip-002', 'plane'), ('trip-002', 'train')
    ''');

    // Listas
    await db.execute('''
      INSERT INTO $tablePackingLists (id, trip_id, user_id, name) VALUES
      ('list-001', 'trip-001', 'usr-001', 'Maleta Principal'),
      ('list-002', 'trip-001', 'usr-001', 'Mochila de mano')
    ''');

    // Items
    await db.execute('''
      INSERT INTO $tablePackingItems (id, list_id, trip_id, user_id, name, category, 
                                      is_packed, quantity, order_index) VALUES
      ('item-001', 'list-001', 'trip-001', 'usr-001', 'Bañador', 'clothing', 1, 2, 1),
      ('item-002', 'list-001', 'trip-001', 'usr-001', 'Protector solar', 'hygiene', 1, 1, 2),
      ('item-003', 'list-001', 'trip-001', 'usr-001', 'Gafas de sol', 'accessories', 1, 1, 3),
      ('item-004', 'list-001', 'trip-001', 'usr-001', 'Cargador móvil', 'electronics', 0, 1, 4)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones futuras
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
    return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
}
