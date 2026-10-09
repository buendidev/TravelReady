import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/recommendations/favorite_place.dart';
import '../../domain/entities/recommendations/recommended_place.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/local/favorites_local_datasource.dart';
import '../models/recommendations/favorite_place_model.dart';

/// [FavoritesRepository] over the local SQLite store.
///
/// [accountId] is threaded straight through to the datasource, which scopes
/// every row to it; this class owns no account state of its own.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource _local;
  final DateTime Function() _now;

  FavoritesRepositoryImpl({
    required FavoritesLocalDataSource local,
    DateTime Function()? now,
  })  : _local = local,
        _now = now ?? DateTime.now;

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FavoritePlace>>> getFavorites(
          {required String accountId}) =>
      _run(() async =>
          (await _local.getFavorites(accountId: accountId))
              .cast<FavoritePlace>());

  @override
  Stream<Either<Failure, List<FavoritePlace>>> watchFavorites(
          {required String accountId}) =>
      _local
          .watchFavorites(accountId: accountId)
          .transform(
            StreamTransformer<List<FavoritePlaceModel>,
                Either<Failure, List<FavoritePlace>>>.fromHandlers(
              handleData: (favorites, sink) =>
                  sink.add(Right(favorites.cast<FavoritePlace>())),
              handleError: (error, _, sink) => sink.add(Left(
                  error is ServerException
                      ? ServerFailure(error.message)
                      : UnexpectedFailure(error.toString()))),
            ),
          );

  @override
  Future<Either<Failure, Set<String>>> getReactedKeys(
          {required String accountId}) =>
      _run(() => _local.getReactedKeys(accountId: accountId));

  @override
  Future<Either<Failure, Unit>> like(RecommendedPlace place,
          {required String accountId}) =>
      _run(() async {
        await _local.like(
            FavoritePlaceModel.fromEntity(FavoritePlace.fromRecommended(place,
                createdAt: _now())),
            accountId: accountId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> dislike(String placeKey,
          {required String accountId}) =>
      _run(() async {
        await _local.dislike(placeKey, accountId: accountId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeFavorite(String placeKey,
          {required String accountId}) =>
      _run(() async {
        await _local.removeFavorite(placeKey, accountId: accountId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeDislike(String placeKey,
          {required String accountId}) =>
      _run(() async {
        await _local.removeDislike(placeKey, accountId: accountId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> resetDislikes({required String accountId}) =>
      _run(() async {
        await _local.clearDislikes(accountId: accountId);
        return unit;
      });
}
