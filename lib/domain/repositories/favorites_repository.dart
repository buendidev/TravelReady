import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/recommendations/favorite_place.dart';
import '../entities/recommendations/recommended_place.dart';

/// Contract of the swipe-feed reactions store.
///
/// Reactions belong to the signed-in account: [accountId] is the user id of
/// the signed-in account (the same value the trips and chats stores key on),
/// and no method ever reads or writes another account's rows.
///
/// A place is either liked, disliked or neither, never two at once.
abstract class FavoritesRepository {
  /// Liked places, newest first, for [accountId] only.
  Future<Either<Failure, List<FavoritePlace>>> getFavorites(
      {required String accountId});

  /// Reactive favorites for [accountId], newest first.
  Stream<Either<Failure, List<FavoritePlace>>> watchFavorites(
      {required String accountId});

  /// Keys of every place [accountId] liked or disliked.
  Future<Either<Failure, Set<String>>> getReactedKeys(
      {required String accountId});

  /// Keeps [place] as a favorite of [accountId] and clears any dislike of it.
  /// Only provider-neutral fields are retained.
  Future<Either<Failure, Unit>> like(RecommendedPlace place,
      {required String accountId});

  /// Hides the place for [accountId] (until [resetDislikes]) and clears any
  /// like. Takes only the key: nothing about the venue is stored.
  Future<Either<Failure, Unit>> dislike(String placeKey,
      {required String accountId});

  /// Deletes a favorite of [accountId]. This is not a dislike.
  Future<Either<Failure, Unit>> removeFavorite(String placeKey,
      {required String accountId});

  /// Undoes a dislike of [accountId] so the place can be offered again.
  Future<Either<Failure, Unit>> removeDislike(String placeKey,
      {required String accountId});

  /// Clears every dislike of [accountId]. Favorites are untouched, and so are
  /// other accounts' dislikes.
  Future<Either<Failure, Unit>> resetDislikes({required String accountId});
}
