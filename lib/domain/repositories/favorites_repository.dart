import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/recommendations/favorite_place.dart';
import '../entities/recommendations/recommended_place.dart';

/// Contract of the swipe-feed reactions store (local to the device in v1).
///
/// A place is either liked, disliked or neither, never two at once.
abstract class FavoritesRepository {
  /// Liked places, newest first.
  Future<Either<Failure, List<FavoritePlace>>> getFavorites();

  /// Reactive favorites, newest first.
  Stream<Either<Failure, List<FavoritePlace>>> watchFavorites();

  /// Keys of every liked and disliked place.
  Future<Either<Failure, Set<String>>> getReactedKeys();

  /// Keeps [place] as a favorite and clears any dislike of it. Only
  /// provider-neutral fields are retained.
  Future<Either<Failure, Unit>> like(RecommendedPlace place);

  /// Hides the place for good (until [resetDislikes]) and clears any like.
  /// Takes only the key: nothing about the venue is stored.
  Future<Either<Failure, Unit>> dislike(String placeKey);

  /// Deletes a favorite. This is not a dislike.
  Future<Either<Failure, Unit>> removeFavorite(String placeKey);

  /// Undoes a dislike so the place can be offered again.
  Future<Either<Failure, Unit>> removeDislike(String placeKey);

  /// Clears every dislike. Favorites are untouched.
  Future<Either<Failure, Unit>> resetDislikes();
}
