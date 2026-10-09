import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/recommendations/favorite_place.dart';
import '../../../domain/repositories/favorites_repository.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// Reactive list of favorites for the Favorites tab. Same stream-driven shape as
/// ItineraryBloc: the repository stream emits on every change, so removing a
/// favorite needs no local bookkeeping.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repo;
  int _revision = 0;

  FavoritesBloc({required FavoritesRepository repo})
      : _repo = repo,
        super(const FavoritesInitial()) {
    on<FavoritesStarted>(_onStarted);
    on<FavoriteRemoved>(_onRemoved);
  }

  Future<void> _onStarted(
      FavoritesStarted e, Emitter<FavoritesState> emit) async {
    emit(const FavoritesLoading());
    await emit.forEach<Either<Failure, List<FavoritePlace>>>(
      _repo.watchFavorites(),
      onData: (either) => either.fold(
        (f) => FavoritesError(f.message),
        (favorites) => FavoritesReady(favorites: favorites),
      ),
      onError: (_, __) => const FavoritesError('Error cargando favoritos.'),
    );
  }

  Future<void> _onRemoved(
      FavoriteRemoved e, Emitter<FavoritesState> emit) async {
    final result = await _repo.removeFavorite(e.key);
    final current = state;
    if (result.isLeft() && current is FavoritesReady) {
      emit(FavoritesReady(
        favorites: current.favorites,
        removeFailed: true,
        revision: ++_revision,
      ));
    }
  }
}
