part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

/// Subscribes to the favorites of [accountId], the signed-in account.
final class FavoritesStarted extends FavoritesEvent {
  final String accountId;
  const FavoritesStarted({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

/// Internal: the repository stream produced a new list (or a failure).
final class _FavoritesChanged extends FavoritesEvent {
  final Either<Failure, List<FavoritePlace>> result;
  const _FavoritesChanged(this.result);
  @override
  List<Object?> get props => [result];
}

/// "Quitar de favoritos": deletes the favorite. It is not a dislike.
final class FavoriteRemoved extends FavoritesEvent {
  final String key;
  final String accountId;
  const FavoriteRemoved(this.key, {required this.accountId});
  @override
  List<Object?> get props => [key, accountId];
}
