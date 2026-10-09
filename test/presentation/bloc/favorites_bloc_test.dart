import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/presentation/bloc/recommendations/favorites_bloc.dart';

import '../../support/recommendations_fakes.dart';

void main() {
  late InMemoryFavoritesRepository repo;
  final prado = RecommendedPlace.from(fakePlace('Prado', PlaceCategory.museum));
  final retiro = RecommendedPlace.from(fakePlace('Retiro', PlaceCategory.nature));

  setUp(() => repo = InMemoryFavoritesRepository());

  tearDown(() => repo.dispose());

  Future<FavoritesBloc> started() async {
    final bloc = FavoritesBloc(repo: repo);
    addTearDown(bloc.close);
    bloc.add(const FavoritesStarted());
    await pumpEventQueue();
    return bloc;
  }

  test('starts empty when nothing was liked', () async {
    final bloc = await started();

    expect(bloc.state, isA<FavoritesReady>());
    expect((bloc.state as FavoritesReady).favorites, isEmpty);
  });

  test('lists favorites newest first and follows new likes live', () async {
    await repo.like(prado);
    final bloc = await started();

    await repo.like(retiro);
    await pumpEventQueue();

    final ready = bloc.state as FavoritesReady;
    expect(ready.favorites.map((f) => f.key), [retiro.key, prado.key]);
  });

  test('removing a favorite deletes it without disliking the place', () async {
    await repo.like(prado);
    final bloc = await started();

    bloc.add(FavoriteRemoved(prado.key));
    await pumpEventQueue();

    expect((bloc.state as FavoritesReady).favorites, isEmpty);
    expect(repo.dislikedKeys, isEmpty);
    expect(repo.log, contains('removeFavorite:${prado.key}'));
  });

  test('a disliked place disappears from the list', () async {
    await repo.like(prado);
    final bloc = await started();

    await repo.dislike(prado.key);
    await pumpEventQueue();

    expect((bloc.state as FavoritesReady).favorites, isEmpty);
  });

  test('a failed removal keeps the list and flags the failure', () async {
    await repo.like(prado);
    final bloc = await started();
    repo.writeFailure = const CacheFailure('disk full');

    bloc.add(FavoriteRemoved(prado.key));
    await pumpEventQueue();

    final ready = bloc.state as FavoritesReady;
    expect(ready.favorites.map((f) => f.key), [prado.key]);
    expect(ready.removeFailed, isTrue);
  });

  test('starting again recovers from an error and replaces the subscription',
      () async {
    repo.readFailure = const CacheFailure('db down');
    final bloc = await started();
    expect(bloc.state, isA<FavoritesError>());

    repo.readFailure = null;
    bloc.add(const FavoritesStarted());
    await pumpEventQueue();

    expect(bloc.state, isA<FavoritesReady>());
    expect(repo.activeWatchers, 1,
        reason: 'the previous subscription must be cancelled, not stacked');
    await repo.like(prado);
    await pumpEventQueue();
    expect((bloc.state as FavoritesReady).favorites, hasLength(1));
  });

  test('closing the bloc releases its subscription', () async {
    final bloc = await started();
    expect(repo.activeWatchers, 1);

    await bloc.close();

    expect(repo.activeWatchers, 0);
  });

  test('a read failure is an error state', () async {
    repo.readFailure = const CacheFailure('db down');

    final bloc = await started();

    expect(bloc.state, isA<FavoritesError>());
    expect((bloc.state as FavoritesError).message, 'db down');
  });
}
