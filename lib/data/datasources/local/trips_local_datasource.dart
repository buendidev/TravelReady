import 'dart:async';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../domain/entities/trip.dart';
import '../../models/packing_item_model.dart';
import '../../models/trip_model.dart';

/// DataSource local para viajes y listas de equipaje usando SQLite.
/// Reemplaza completamente FirestoreDataSource.
///
/// Usa StreamController para notificar cambios en lugar de polling, lo que es
/// mucho más eficiente y evita race conditions con optimistic updates.
class TripsLocalDataSource {
  final DatabaseHelper _db;

  // Controllers para notificar cambios (key = userId o tripId)
  final Map<String, StreamController<List<TripModel>>> _tripsControllers = {};
  final Map<String, StreamController<List<PackingListModel>>> _packingControllers = {};

  TripsLocalDataSource({required DatabaseHelper database}) : _db = database;

  // ===========================================================================
  // CHANGE NOTIFICATIONS
  // ===========================================================================

  Future<void> _notifyTripsChanged(String userId) async {
    final controller = _tripsControllers[userId];
    if (controller == null || controller.isClosed) return;
    try {
      controller.add(await getTrips(userId));
    } catch (e) {
      controller.addError(e);
    }
  }

  Future<void> _notifyPackingChanged(String tripId) async {
    final controller = _packingControllers[tripId];
    if (controller == null || controller.isClosed) return;
    try {
      controller.add(await getPackingLists(tripId));
    } catch (e) {
      controller.addError(e);
    }
  }

  /// Cierra todos los controllers (llamar en dispose).
  void dispose() {
    for (final c in _tripsControllers.values) {
      c.close();
    }
    for (final c in _packingControllers.values) {
      c.close();
    }
    _tripsControllers.clear();
    _packingControllers.clear();
  }

  // ===========================================================================
  // TRIPS
  // ===========================================================================

  Future<List<TripModel>> getTrips(String userId) async {
    try {
      final tripRows = await _db.query(
        DatabaseHelper.tableTrips,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      final trips = <TripModel>[];
      for (final row in tripRows) {
        final trip = await _loadTripWithRelations(row);
        trips.add(trip);
      }

      return trips;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<TripModel>> watchTrips(String userId) {
    final controller = _tripsControllers.putIfAbsent(
      userId,
      () => StreamController<List<TripModel>>.broadcast(),
    );
    // Emitir el estado inicial inmediatamente
    Future.microtask(() => _notifyTripsChanged(userId));
    return controller.stream;
  }

  Future<TripModel> getTripById(String tripId) async {
    try {
      final rows = await _db.query(
        DatabaseHelper.tableTrips,
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const ServerException('Viaje no encontrado');
      }

      return await _loadTripWithRelations(rows.first);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final result = await _db.transaction((txn) async {
        await txn.insert(DatabaseHelper.tableTrips, _tripToMap(trip));
        for (final transport in trip.transport) {
          await txn.insert(DatabaseHelper.tableTripTransport, {
            'trip_id': trip.id,
            'transport_type': transport.name,
          });
        }
        for (final activity in trip.activities) {
          await txn.insert(DatabaseHelper.tableTripActivities, {
            'trip_id': trip.id,
            'activity': activity,
          });
        }
        return trip;
      });
      await _notifyTripsChanged(trip.userId);
      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      final result = await _db.transaction((txn) async {
        await txn.update(
          DatabaseHelper.tableTrips,
          _tripToMap(trip),
          where: 'id = ?',
          whereArgs: [trip.id],
        );
        await txn.delete(
          DatabaseHelper.tableTripTransport,
          where: 'trip_id = ?',
          whereArgs: [trip.id],
        );
        for (final transport in trip.transport) {
          await txn.insert(DatabaseHelper.tableTripTransport, {
            'trip_id': trip.id,
            'transport_type': transport.name,
          });
        }
        await txn.delete(
          DatabaseHelper.tableTripActivities,
          where: 'trip_id = ?',
          whereArgs: [trip.id],
        );
        for (final activity in trip.activities) {
          await txn.insert(DatabaseHelper.tableTripActivities, {
            'trip_id': trip.id,
            'activity': activity,
          });
        }
        return trip;
      });
      await _notifyTripsChanged(trip.userId);
      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      // Obtener userId antes de borrar para notificar
      final rows = await _db.query(
        DatabaseHelper.tableTrips,
        columns: ['user_id'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      final userId = rows.isNotEmpty ? rows.first['user_id'] as String : null;

      await _db.delete(
        DatabaseHelper.tableTrips,
        where: 'id = ?',
        whereArgs: [tripId],
      );

      if (userId != null) await _notifyTripsChanged(userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ===========================================================================
  // PACKING LISTS
  // ===========================================================================

  Future<List<PackingListModel>> getPackingLists(String tripId) async {
    try {
      final listRows = await _db.query(
        DatabaseHelper.tablePackingLists,
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'created_at',
      );

      final lists = <PackingListModel>[];
      for (final row in listRows) {
        final list = await _loadPackingListWithItems(row);
        lists.add(list);
      }

      return lists;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<PackingListModel> getPackingListById(String listId) async {
    try {
      final rows = await _db.query(
        DatabaseHelper.tablePackingLists,
        where: 'id = ?',
        whereArgs: [listId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const ServerException('Lista no encontrada');
      }

      return await _loadPackingListWithItems(rows.first);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<PackingListModel>> watchPackingLists(String tripId) {
    final controller = _packingControllers.putIfAbsent(
      tripId,
      () => StreamController<List<PackingListModel>>.broadcast(),
    );
    Future.microtask(() => _notifyPackingChanged(tripId));
    return controller.stream;
  }

  Future<PackingListModel> createPackingList(PackingListModel list) async {
    try {
      await _db.insert(
        DatabaseHelper.tablePackingLists,
        _packingListToMap(list),
      );
      for (final item in list.items) {
        await _db.insert(
          DatabaseHelper.tablePackingItems,
          _packingItemToMap(item),
        );
      }
      await _notifyPackingChanged(list.tripId);
      return list;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<PackingListModel> updatePackingList(PackingListModel list) async {
    try {
      await _db.update(
        DatabaseHelper.tablePackingLists,
        _packingListToMap(list),
        where: 'id = ?',
        whereArgs: [list.id],
      );
      await _notifyPackingChanged(list.tripId);
      return list;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deletePackingList(String listId) async {
    try {
      // Obtener tripId antes de borrar para notificar
      final rows = await _db.query(
        DatabaseHelper.tablePackingLists,
        columns: ['trip_id'],
        where: 'id = ?',
        whereArgs: [listId],
        limit: 1,
      );
      final tripId = rows.isNotEmpty ? rows.first['trip_id'] as String : null;

      await _db.delete(
        DatabaseHelper.tablePackingLists,
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (tripId != null) await _notifyPackingChanged(tripId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ===========================================================================
  // PACKING ITEMS
  // ===========================================================================

  Future<PackingItemModel> createPackingItem(PackingItemModel item) async {
    try {
      await _db.insert(
        DatabaseHelper.tablePackingItems,
        _packingItemToMap(item),
      );
      await _notifyPackingChanged(item.tripId);
      return item;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<PackingItemModel> updatePackingItem(PackingItemModel item) async {
    try {
      await _db.update(
        DatabaseHelper.tablePackingItems,
        _packingItemToMap(item),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _notifyPackingChanged(item.tripId);
      return item;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deletePackingItem(String itemId) async {
    try {
      // Obtener tripId antes de borrar para notificar
      final rows = await _db.query(
        DatabaseHelper.tablePackingItems,
        columns: ['trip_id'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      final tripId = rows.isNotEmpty ? rows.first['trip_id'] as String : null;

      await _db.delete(
        DatabaseHelper.tablePackingItems,
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (tripId != null) await _notifyPackingChanged(tripId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> toggleItemPacked(String itemId, bool isPacked) async {
    try {
      final rows = await _db.query(
        DatabaseHelper.tablePackingItems,
        columns: ['trip_id'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      final tripId = rows.isNotEmpty ? rows.first['trip_id'] as String : null;

      await _db.update(
        DatabaseHelper.tablePackingItems,
        {'is_packed': isPacked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (tripId != null) await _notifyPackingChanged(tripId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<TripModel> _loadTripWithRelations(Map<String, dynamic> row) async {
    final tripId = row['id'] as String;

    // Cargar transportes
    final transportRows = await _db.query(
      DatabaseHelper.tableTripTransport,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    final transport = transportRows
        .map((r) => TransportType.values.firstWhere(
              (t) => t.name == r['transport_type'],
              orElse: () => TransportType.other,
            ))
        .toList();

    // Cargar actividades
    final activityRows = await _db.query(
      DatabaseHelper.tableTripActivities,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    final activities = activityRows
        .map((r) => r['activity'] as String)
        .toList();

    return TripModel(
      id: tripId,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      destination: row['destination'] as String,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: DateTime.parse(row['end_date'] as String),
      transport: transport,
      tripType: TripType.values.firstWhere(
        (t) => t.name == row['trip_type'],
        orElse: () => TripType.city,
      ),
      activities: activities,
      progress: row['progress'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      notes: row['notes'] as String?,
    );
  }

  Future<PackingListModel> _loadPackingListWithItems(Map<String, dynamic> row) async {
    final listId = row['id'] as String;
    final tripId = row['trip_id'] as String;

    // Cargar items
    final itemRows = await _db.query(
      DatabaseHelper.tablePackingItems,
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'order_index',
    );

    final items = itemRows.map((r) => PackingItemModel(
      id: r['id'] as String,
      listId: listId,
      tripId: tripId,
      userId: r['user_id'] as String,
      name: r['name'] as String,
      category: PackingCategory.values.firstWhere(
        (c) => c.name == r['category'],
        orElse: () => PackingCategory.other,
      ),
      isPacked: (r['is_packed'] as int) == 1,
      isAutoGenerated: (r['is_auto_generated'] as int) == 1,
      quantity: r['quantity'] as int,
      order: r['order_index'] as int,
      notes: r['notes'] as String?,
    )).toList();

    return PackingListModel(
      id: listId,
      tripId: tripId,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      items: items,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _tripToMap(TripModel trip) {
    return {
      'id': trip.id,
      'user_id': trip.userId,
      'name': trip.name,
      'destination': trip.destination,
      'start_date': trip.startDate.toIso8601String(),
      'end_date': trip.endDate.toIso8601String(),
      'trip_type': trip.tripType.name,
      'progress': trip.progress,
      'created_at': trip.createdAt.toIso8601String(),
      'notes': trip.notes,
    };
  }

  Map<String, dynamic> _packingListToMap(PackingListModel list) {
    return {
      'id': list.id,
      'trip_id': list.tripId,
      'user_id': list.userId,
      'name': list.name,
      'created_at': list.createdAt.toIso8601String(),
      'updated_at': list.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _packingItemToMap(PackingItem item) {
    return {
      'id': item.id,
      'list_id': item.listId,
      'trip_id': item.tripId,
      'user_id': item.userId,
      'name': item.name,
      'category': item.category.name,
      'is_packed': item.isPacked ? 1 : 0,
      'is_auto_generated': item.isAutoGenerated ? 1 : 0,
      'quantity': item.quantity,
      'order_index': item.order,
      'notes': item.notes,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Extensiones para modelos
extension on TripModel {
  // Usamos los getters del modelo
}
