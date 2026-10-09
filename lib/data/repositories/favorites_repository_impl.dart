import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/recommendations/favorite_place.dart';
import '../../domain/entities/recommendations/recommended_place.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/local/favorites_local_datasource.dart';
import '../models/recommendations/favorite_place_model.dart';

/// [FavoritesRepository] over the local SQLite store.
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
  Future<Either<Failure, List<FavoritePlace>>> getFavorites() =>
      _run(() async => (await _local.getFavorites()).cast<FavoritePlace>());

  @override
  Stream<Either<Failure, List<FavoritePlace>>> watchFavorites() =>
      _local.watchFavorites().transform(
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
  Future<Either<Failure, Set<String>>> getReactedKeys() =>
      _run(_local.getReactedKeys);

  @override
  Future<Either<Failure, Unit>> like(RecommendedPlace place) =>
      _run(() async {
        await _local.like(FavoritePlaceModel.fromEntity(
            FavoritePlace.fromRecommended(place, createdAt: _now())));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> dislike(String placeKey) => _run(() async {
        await _local.dislike(placeKey);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeFavorite(String placeKey) =>
      _run(() async {
        await _local.removeFavorite(placeKey);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeDislike(String placeKey) =>
      _run(() async {
        await _local.removeDislike(placeKey);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> resetDislikes() => _run(() async {
        await _local.clearDislikes();
        return unit;
      });
}
