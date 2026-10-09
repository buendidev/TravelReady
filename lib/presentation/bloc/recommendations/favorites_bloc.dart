import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/recommendations/favorite_place.dart';
import '../../../domain/repositories/favorites_repository.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// Reactive list of favorites for the Favorites tab. Stream-driven like
/// ItineraryBloc: the repository stream emits on every change, so removing a
/// favorite needs no local bookkeeping.
///
/// The subscription is owned here (not by a long-running handler) so a retry
/// replaces it instead of stacking a second one.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repo;
  StreamSubscription<Either<Failure, List<FavoritePlace>>>? _subscription;
  int _revision = 0;

  FavoritesBloc({required FavoritesRepository repo})
      : _repo = repo,
        super(const FavoritesInitial()) {
    on<FavoritesStarted>(_onStarted);
    on<_FavoritesChanged>(_onChanged);
    on<FavoriteRemoved>(_onRemoved);
  }

  void _onStarted(FavoritesStarted e, Emitter<FavoritesState> emit) {
    // Once cancelled, the old subscription delivers nothing more, so there is no
    // need to wait for the cancellation to settle before starting the new one.
    unawaited(_subscription?.cancel());
    emit(const FavoritesLoading());
    _subscription = _repo.watchFavorites().listen(
          (either) => add(_FavoritesChanged(either)),
          onError: (Object _) => add(const _FavoritesChanged(
              Left(UnexpectedFailure('Error cargando favoritos.')))),
        );
  }

  void _onChanged(_FavoritesChanged e, Emitter<FavoritesState> emit) =>
      emit(e.result.fold(
        (f) => FavoritesError(f.message),
        (favorites) => FavoritesReady(favorites: favorites),
      ));

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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
