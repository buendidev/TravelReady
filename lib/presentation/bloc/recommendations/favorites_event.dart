part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

final class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted();
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
  const FavoriteRemoved(this.key);
  @override
  List<Object?> get props => [key];
}
