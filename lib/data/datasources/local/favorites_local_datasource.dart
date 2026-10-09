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
/// Every row belongs to an account: [accountId] is the signed-in user id (the
/// same value the trips and chats stores key on) and every read, list and
/// write is scoped to it, so two accounts on the same device never see each
/// other's reactions.
///
/// A place is never liked and disliked at once: both writes run in a
/// transaction that also clears the opposite reaction, within the account.
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

  /// Newest first, for this account only. A row that cannot be read is skipped
  /// rather than hiding every other favorite.
  Future<List<FavoritePlaceModel>> getFavorites(
          {required String accountId}) =>
      _guard((db) async {
        final rows = await db.query(
          DatabaseHelper.tablePlaceFavorites,
          where: 'account_id = ?',
          whereArgs: [accountId],
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

  /// Emits this account's favorites on listen and again after every change.
  Stream<List<FavoritePlaceModel>> watchFavorites(
      {required String accountId}) {
    late final StreamController<List<FavoritePlaceModel>> controller;
    StreamSubscription<void>? subscription;

    Future<void> emit() async {
      try {
        final favorites = await getFavorites(accountId: accountId);
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

  /// Keys of every place this account has reacted to, likes and dislikes.
  Future<Set<String>> getReactedKeys({required String accountId}) =>
      _guard((db) async {
        final rows = await db.rawQuery(
          'SELECT place_key FROM ${DatabaseHelper.tablePlaceFavorites} '
          'WHERE account_id = ? '
          'UNION SELECT place_key FROM ${DatabaseHelper.tablePlaceDislikes} '
          'WHERE account_id = ?',
          [accountId, accountId],
        );
        return rows.map((r) => r['place_key'] as String).toSet();
      });

  Future<void> like(FavoritePlaceModel favorite,
          {required String accountId}) =>
      _guard((db) async {
        await db.transaction((txn) async {
          await txn.insert(
            DatabaseHelper.tablePlaceFavorites,
            {...favorite.toMap(), 'account_id': accountId},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(DatabaseHelper.tablePlaceDislikes,
              where: 'account_id = ? AND place_key = ?',
              whereArgs: [accountId, favorite.key]);
        });
        _changes.add(null);
      });

  /// Takes only the key: a dislike keeps no venue name and no snapshot.
  Future<void> dislike(String placeKey, {required String accountId}) =>
      _guard((db) async {
        await db.transaction((txn) async {
          await txn.insert(
            DatabaseHelper.tablePlaceDislikes,
            {
              'account_id': accountId,
              'place_key': placeKey,
              'created_at': _now().toUtc().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(DatabaseHelper.tablePlaceFavorites,
              where: 'account_id = ? AND place_key = ?',
              whereArgs: [accountId, placeKey]);
        });
        _changes.add(null);
      });

  /// Deletes the favorite only. It is not a dislike: the place may be offered
  /// again.
  Future<void> removeFavorite(String placeKey, {required String accountId}) =>
      _guard((db) async {
        await db.delete(DatabaseHelper.tablePlaceFavorites,
            where: 'account_id = ? AND place_key = ?',
            whereArgs: [accountId, placeKey]);
        _changes.add(null);
      });

  Future<void> removeDislike(String placeKey, {required String accountId}) =>
      _guard((db) => db.delete(DatabaseHelper.tablePlaceDislikes,
          where: 'account_id = ? AND place_key = ?',
          whereArgs: [accountId, placeKey]));

  /// Clears every dislike of this account. Favorites are untouched, and so are
  /// the dislikes of any other account on the device.
  Future<void> clearDislikes({required String accountId}) =>
      _guard((db) => db.delete(DatabaseHelper.tablePlaceDislikes,
          where: 'account_id = ?', whereArgs: [accountId]));

  void dispose() => _changes.close();
}
