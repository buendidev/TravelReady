part of 'favorites_bloc.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

final class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// Liked places, newest first.
final class FavoritesReady extends FavoritesState {
  final List<FavoritePlace> favorites;

  /// A removal could not be written; the list is unchanged.
  final bool removeFailed;

  /// Distinguishes two consecutive failures for UI listeners.
  final int revision;

  const FavoritesReady({
    required this.favorites,
    this.removeFailed = false,
    this.revision = 0,
  });

  @override
  List<Object?> get props => [favorites, removeFailed, revision];
}

final class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}
