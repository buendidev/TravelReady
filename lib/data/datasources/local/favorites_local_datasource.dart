import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/failures.dart';
import '../../models/recommendations/favorite_place_model.dart';

/// Local (SQLite) store of swipe-feed reactions: `place_favorites` and
/// `place_dislikes`.
///
/// The schema is registered centrally in [DatabaseHelper] (v3). The tables are
/// also ensured lazily with the same idempotent DDL, so a database opened
/// without the central migration (tests, an in-memory instance) still works.
///
/// A place is never liked and disliked at once: both writes run in a
/// transaction that also clears the opposite reaction.
///
/// The injected opener lets tests use an in-memory database instead of the
/// app's singleton file (same convention as the itinerary and weather stores).
class FavoritesLocalDataSource {
  final Future<Database> Function() _openDatabase;
  final DateTime Function() _now;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  Database? _ensuredFor;

  FavoritesLocalDataSource({
    Future<Database> Function()? openDatabase,
    DateTime Function()? now,
  })  : _openDatabase = openDatabase ?? (() => DatabaseHelper().database),
        _now = now ?? DateTime.now;

  Future<Database> _db() async {
    final db = await _openDatabase();
    if (!identical(_ensuredFor, db)) {
      await DatabaseHelper.createReactionTables(db);
      _ensuredFor = db;
    }
    return db;
  }

  Future<T> _guard<T>(Future<T> Function(Database db) action) async {
    try {
      return await action(await _db());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Newest first. A row that cannot be read is skipped rather than hiding
  /// every other favorite.
  Future<List<FavoritePlaceModel>> getFavorites() => _guard((db) async {
        final rows = await db.query(
          DatabaseHelper.tablePlaceFavorites,
          orderBy: 'created_at DESC, rowid DESC',
        );
        final favorites = <FavoritePlaceModel>[];
        for (final row in rows) {
          try {
            favorites.add(FavoritePlaceModel.fromMap(row));
          } catch (_) {
            continue;
          }
        }
        return favorites;
      });

  /// Emits the current favorites on listen and again after every change.
  Stream<List<FavoritePlaceModel>> watchFavorites() {
    late final StreamController<List<FavoritePlaceModel>> controller;
    StreamSubscription<void>? subscription;

    Future<void> emit() async {
      try {
        final favorites = await getFavorites();
        if (!controller.isClosed) controller.add(favorites);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<FavoritePlaceModel>>(
      onListen: () {
        subscription = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  /// Keys of every place the traveller has reacted to, likes and dislikes.
  Future<Set<String>> getReactedKeys() => _guard((db) async {
        final rows = await db.rawQuery(
          'SELECT place_key FROM ${DatabaseHelper.tablePlaceFavorites} '
          'UNION SELECT place_key FROM ${DatabaseHelper.tablePlaceDislikes}',
        );
        return rows.map((r) => r['place_key'] as String).toSet();
      });

  Future<void> like(FavoritePlaceModel favorite) => _guard((db) async {
        await db.transaction((txn) async {
          await txn.insert(
            DatabaseHelper.tablePlaceFavorites,
            favorite.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(DatabaseHelper.tablePlaceDislikes,
              where: 'place_key = ?', whereArgs: [favorite.key]);
        });
        _changes.add(null);
      });

  /// Takes only the key: a dislike keeps no venue name and no snapshot.
  Future<void> dislike(String placeKey) => _guard((db) async {
        await db.transaction((txn) async {
          await txn.insert(
            DatabaseHelper.tablePlaceDislikes,
            {
              'place_key': placeKey,
              'created_at': _now().toUtc().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(DatabaseHelper.tablePlaceFavorites,
              where: 'place_key = ?', whereArgs: [placeKey]);
        });
        _changes.add(null);
      });

  /// Deletes the favorite only. It is not a dislike: the place may be offered
  /// again.
  Future<void> removeFavorite(String placeKey) => _guard((db) async {
        await db.delete(DatabaseHelper.tablePlaceFavorites,
            where: 'place_key = ?', whereArgs: [placeKey]);
        _changes.add(null);
      });

  Future<void> removeDislike(String placeKey) => _guard((db) => db.delete(
      DatabaseHelper.tablePlaceDislikes,
      where: 'place_key = ?',
      whereArgs: [placeKey]));

  /// Clears every dislike. Favorites are untouched.
  Future<void> clearDislikes() =>
      _guard((db) => db.delete(DatabaseHelper.tablePlaceDislikes));

  void dispose() => _changes.close();
}
