import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../models/itinerary/itinerary_item_model.dart';

/// DataSource local del itinerario (SQLite, offline-first).
///
/// La tabla `itinerary_items` se crea perezosamente con
/// `CREATE TABLE IF NOT EXISTS` en el primer acceso — migración
/// autogestionada dentro de este datasource, sin tocar el esquema
/// central de [DatabaseHelper] ni forzar un bump de versión.
/// Si se prefiere la migración central, mover el DDL a
/// `DatabaseHelper.upgradeSchema` es un cambio de una línea.
///
/// El opener inyectado permite a los tests usar una base en memoria
/// sin abrir el fichero singleton de la app (misma convención que
/// [WeatherCacheDataSource]).
class ItineraryLocalDataSource {
  static const String tableName = 'itinerary_items';

  final Future<Database> Function() _openDatabase;
  Future<void>? _ensured;

  final Map<String, StreamController<List<ItineraryItemModel>>>
      _controllers = {};

  ItineraryLocalDataSource({Future<Database> Function()? openDatabase})
      : _openDatabase = openDatabase ?? (() => DatabaseHelper().database);

  // ── Migración perezosa ──────────────────────────────────────────────────

  Future<void> _ensureTable() =>
      _ensured ??= _createTable();

  Future<void> _createTable() async {
    final db = await _openDatabase();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id VARCHAR(36) PRIMARY KEY,
        trip_id VARCHAR(36) NOT NULL,
        day TEXT NOT NULL,
        start_minutes INTEGER NOT NULL,
        end_minutes INTEGER,
        title VARCHAR(120) NOT NULL,
        category VARCHAR(20) DEFAULT 'other',
        notes TEXT,
        order_index INTEGER DEFAULT 0,
        place_name TEXT,
        place_address TEXT,
        place_lat REAL,
        place_lng REAL,
        place_website TEXT,
        place_hours TEXT,
        place_price_label TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES ${DatabaseHelper.tableTrips}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_itinerary_trip
      ON $tableName(trip_id, day, start_minutes, order_index)
    ''');
  }

  // ── Notificaciones ──────────────────────────────────────────────────────

  Future<void> _notifyChanged(String tripId) async {
    final controller = _controllers[tripId];
    if (controller == null || controller.isClosed) return;
    try {
      controller.add(await getItems(tripId));
    } catch (e) {
      controller.addError(e);
    }
  }

  /// Cierra todos los controllers (llamar en dispose).
  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  // ── Lectura ─────────────────────────────────────────────────────────────

  Future<List<ItineraryItemModel>> getItems(String tripId) async {
    try {
      await _ensureTable();
      final db = await _openDatabase();
      final rows = await db.query(
        tableName,
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'day, start_minutes, order_index',
      );
      return rows.map(ItineraryItemModel.fromMap).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<ItineraryItemModel>> watchItems(String tripId) {
    final controller = _controllers.putIfAbsent(
      tripId,
      () => StreamController<List<ItineraryItemModel>>.broadcast(),
    );
    Future.microtask(() => _notifyChanged(tripId));
    return controller.stream;
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  Future<ItineraryItemModel> createItem(ItineraryItemModel item) async {
    try {
      await _ensureTable();
      final db = await _openDatabase();
      await db.insert(
        tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _notifyChanged(item.tripId);
      return item;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ItineraryItemModel> updateItem(ItineraryItemModel item) async {
    try {
      await _ensureTable();
      final db = await _openDatabase();
      await db.update(
        tableName,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _notifyChanged(item.tripId);
      return item;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _ensureTable();
      final db = await _openDatabase();
      final rows = await db.query(
        tableName,
        columns: ['trip_id'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      final tripId = rows.isNotEmpty ? rows.first['trip_id'] as String : null;

      await db.delete(tableName, where: 'id = ?', whereArgs: [itemId]);
      if (tripId != null) await _notifyChanged(tripId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Persiste `order_index` según la posición en [orderedIds].
  Future<void> reorderItems(String tripId, List<String> orderedIds) async {
    try {
      await _ensureTable();
      final db = await _openDatabase();
      await db.transaction((txn) async {
        for (var i = 0; i < orderedIds.length; i++) {
          await txn.update(
            tableName,
            {'order_index': i},
            where: 'id = ? AND trip_id = ?',
            whereArgs: [orderedIds[i], tripId],
          );
        }
      });
      await _notifyChanged(tripId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
