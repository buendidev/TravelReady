import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/recommendations/applied_reaction.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommendation_filter.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/react_to_place_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/reset_dislikes_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/undo_reaction_usecase.dart';
import 'package:travel_ready/presentation/bloc/recommendations/recommendations_bloc.dart';

import '../../support/recommendations_fakes.dart';

void main() {
  late FakePlacesGateway gateway;
  late InMemoryFavoritesRepository repo;

  setUp(() {
    gateway = FakePlacesGateway(catalog: fakeCatalog(perCategory: 2));
    repo = InMemoryFavoritesRepository();
  });

  tearDown(() => repo.dispose());

  RecommendationsBloc build({int seed = 1}) {
    final feed = GetRecommendationFeedUseCase(gateway: gateway, favorites: repo);
    return RecommendationsBloc(
      getFeed: feed,
      refill: RefillRecommendationFeedUseCase(feed),
      react: ReactToPlaceUseCase(repo),
      undo: UndoReactionUseCase(repo),
      resetDislikes: ResetDislikesUseCase(repo),
      seedProvider: () => seed,
    );
  }

  /// Creates a bloc, starts it and waits for the in-memory futures to settle.
  Future<RecommendationsBloc> started({
    String? destination = 'Madrid',
    int seed = 1,
  }) async {
    final bloc = build(seed: seed);
    addTearDown(bloc.close);
    bloc.add(FeedStarted(destination: destination));
    await pumpEventQueue();
    return bloc;
  }

  Future<void> settle() => pumpEventQueue();

  // 12 feed-eligible venues in the catalog (6 categories x 2).
  const eligible = 12;

  group('loading', () {
    blocTest<RecommendationsBloc, RecommendationsState>(
      'loads the feed for the trip destination',
      build: build,
      act: (b) => b.add(const FeedStarted(destination: 'Madrid')),
      expect: () => [
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.loading),
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.ready)
            .having((s) => s.cards, 'cards', hasLength(eligible))
            .having((s) => s.destinationHint, 'hint', 'Madrid')
            .having((s) => s.filter, 'filter', RecommendationFilter.all),
      ],
      verify: (_) =>
          expect(gateway.calls.single.destinationHint, 'Madrid'),
    );

    blocTest<RecommendationsBloc, RecommendationsState>(
      'an unavailable provider is its own state and is never searched',
      build: build,
      setUp: () => gateway.availability = PlacesAvailability.unavailable,
      act: (b) => b.add(const FeedStarted(destination: 'Madrid')),
      expect: () => [
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.loading),
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.unavailable),
      ],
      verify: (_) => expect(gateway.calls, isEmpty),
    );

    blocTest<RecommendationsBloc, RecommendationsState>(
      'a provider failure is an error state with the message',
      build: build,
      setUp: () => gateway.failure = const ServerFailure('boom'),
      act: (b) => b.add(const FeedStarted(destination: 'Madrid')),
      expect: () => [
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.loading),
        isA<RecommendationsState>()
            .having((s) => s.status, 'status', FeedStatus.error)
            .having((s) => s.errorMessage, 'message', 'boom'),
      ],
    );

    test('retry reloads after an error', () async {
      gateway.failure = const ServerFailure('boom');
      final bloc = await started();
      expect(bloc.state.status, FeedStatus.error);

      gateway.failure = null;
      bloc.add(const FeedRetried());
      await settle();

      expect(bloc.state.status, FeedStatus.ready);
    });

    test('a provider with nothing for the filter is empty', () async {
      gateway.catalog = [];

      final bloc = await started();

      expect(bloc.state.status, FeedStatus.empty);
    });

    test('a filter whose places were all reacted to is exhausted, not empty',
        () async {
      for (final place in gateway.catalog) {
        await repo.dislike(placeKeyOf(place));
      }

      final bloc = await started();

      expect(bloc.state.status, FeedStatus.exhausted);
    });

    test('restarting the feed reloads it with a fresh session', () async {
      final bloc = await started();
      final first = bloc.state.cards.first;
      bloc.add(FeedCardReacted(key: first.key, reaction: PlaceReaction.like));
      await settle();

      bloc.add(const FeedStarted(destination: 'Madrid'));
      await settle();

      expect(bloc.state.status, FeedStatus.ready);
      expect(bloc.state.cards, hasLength(eligible - 1));
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(first.key)),
          reason: 'a liked place stays out of the feed');
    });
  });

  group('swiping', () {
    test('like saves a favorite and takes the card off the deck', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;

      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();

      expect(repo.favorites.map((f) => f.key), [top.key]);
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(top.key)));
      expect(bloc.state.cards, hasLength(eligible - 1));
      expect(bloc.state.lastReaction,
          AppliedReaction(place: top, reaction: PlaceReaction.like));
    });

    test('dislike hides the place by key and stores no favorite', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;

      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.dislike));
      await settle();

      expect(repo.dislikedKeys, {top.key});
      expect(repo.favorites, isEmpty);
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(top.key)));
    });

    test('a reaction to a card that is no longer on top is ignored', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      final second = bloc.state.cards[1];

      bloc.add(FeedCardReacted(key: second.key, reaction: PlaceReaction.like));
      await settle();

      expect(repo.log, isEmpty);
      expect(bloc.state.cards.first, top);
    });

    test('a double tap on the same card reacts once', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;

      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();

      expect(repo.log, ['like:${top.key}']);
      expect(bloc.state.cards, hasLength(eligible - 1));
    });

    test('a failed write puts the card back and says so', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      repo.writeFailure = const CacheFailure('disk full');

      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();

      expect(repo.favorites, isEmpty);
      expect(bloc.state.cards.first, top);
      expect(bloc.state.cards, hasLength(eligible));
      expect(bloc.state.notice, FeedNotice.reactionFailed);
      expect(bloc.state.lastReaction, isNull);
    });

    test('swiping the whole deck ends exhausted without resurrecting a card',
        () async {
      final bloc = await started();
      final offered = <String>[];

      while (bloc.state.status == FeedStatus.ready) {
        final top = bloc.state.cards.first;
        offered.add(top.key);
        bloc.add(FeedCardReacted(
            key: top.key,
            reaction:
                offered.length.isEven ? PlaceReaction.like : PlaceReaction.dislike));
        await settle();
      }

      expect(bloc.state.status, FeedStatus.exhausted);
      expect(offered, hasLength(eligible));
      expect(offered.toSet(), hasLength(eligible),
          reason: 'no card was offered twice');
    });
  });

  group('refill', () {
    test('tops the deck up when fewer than three cards remain', () async {
      // The provider only reveals more places on a wider (refill) window.
      final all = fakeCatalog(perCategory: 6);
      final firstWindow = all.where((p) => p.category == PlaceCategory.food).take(4).toList();
      gateway.responder = (call) => call.limit <= feedPageSize
          ? Right(firstWindow)
          : Right(all.where((p) => p.category == PlaceCategory.food).toList());
      final bloc = await started();
      expect(bloc.state.cards, hasLength(4));

      for (var i = 0; i < 2; i++) {
        bloc.add(FeedCardReacted(
            key: bloc.state.cards.first.key, reaction: PlaceReaction.dislike));
        await settle();
      }

      expect(bloc.state.status, FeedStatus.ready);
      expect(bloc.state.cards.length, greaterThan(2),
          reason: 'the refill added places beyond the first window');
      expect(gateway.calls.last.limit, greaterThan(feedPageSize));
    });

    test('never offers a card twice across refills', () async {
      final all = fakeCatalog(perCategory: 6);
      gateway.responder = (call) {
        final window = all.where((p) => p.category == PlaceCategory.food).toList();
        return Right(window.take(call.limit <= feedPageSize ? 4 : 6).toList());
      };
      final bloc = await started();
      final offered = <String>[];

      while (bloc.state.status == FeedStatus.ready) {
        final top = bloc.state.cards.first;
        offered.add(top.key);
        bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.dislike));
        await settle();
      }

      expect(offered.toSet(), hasLength(offered.length));
      expect(offered, hasLength(6));
      expect(bloc.state.status, FeedStatus.exhausted);
    });

    test('stops asking once the provider has nothing new', () async {
      final bloc = await started();
      final callsAfterLoad = gateway.calls.length;

      for (var i = 0; i < eligible; i++) {
        if (bloc.state.cards.isEmpty) break;
        bloc.add(FeedCardReacted(
            key: bloc.state.cards.first.key, reaction: PlaceReaction.dislike));
        await settle();
      }

      // One failed top-up (two attempts) once the deck dropped under three;
      // not another pair on every remaining swipe.
      expect(gateway.calls.length - callsAfterLoad, lessThanOrEqualTo(2));
      expect(bloc.state.status, FeedStatus.exhausted);
      expect(repo.dislikedKeys, hasLength(eligible));
    });
  });

  group('undo', () {
    test('undoing a like brings the card back and removes the favorite',
        () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(bloc.state.cards.first, top);
      expect(bloc.state.cards, hasLength(eligible));
      expect(repo.favorites, isEmpty);
      expect(repo.dislikedKeys, isEmpty);
      expect(bloc.state.lastReaction, isNull);
    });

    test('undoing a dislike brings the card back and lets it be offered again',
        () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.dislike));
      await settle();

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(bloc.state.cards.first, top);
      expect(repo.dislikedKeys, isEmpty);
    });

    test('undo is single-step: a second undo does nothing', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();
      bloc.add(const FeedUndoRequested());
      await settle();
      final logAfterUndo = List.of(repo.log);

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(repo.log, logAfterUndo);
    });

    test('undo with nothing to undo is a no-op', () async {
      final bloc = await started();

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(repo.log, isEmpty);
      expect(bloc.state.status, FeedStatus.ready);
    });

    test('the last swipe of the feed can still be undone from exhausted',
        () async {
      gateway.catalog = [fakePlace('only', PlaceCategory.food)];
      final bloc = await started();
      final only = bloc.state.cards.single;
      bloc.add(FeedCardReacted(key: only.key, reaction: PlaceReaction.dislike));
      await settle();
      expect(bloc.state.status, FeedStatus.exhausted);

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(bloc.state.status, FeedStatus.ready);
      expect(bloc.state.cards.single, only);
    });

    test('a failed undo keeps the reaction and says so', () async {
      final bloc = await started();
      final top = bloc.state.cards.first;
      bloc.add(FeedCardReacted(key: top.key, reaction: PlaceReaction.like));
      await settle();
      repo.writeFailure = const CacheFailure('disk full');

      bloc.add(const FeedUndoRequested());
      await settle();

      expect(bloc.state.notice, FeedNotice.undoFailed);
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(top.key)));
    });
  });

  group('filter and location', () {
    test('changing the filter reloads with only that filter\'s categories',
        () async {
      final bloc = await started();

      bloc.add(const FeedFilterChanged(RecommendationFilter.restaurants));
      await settle();

      expect(bloc.state.filter, RecommendationFilter.restaurants);
      expect(bloc.state.status, FeedStatus.ready);
      expect(
          bloc.state.cards.every((c) => c.place.category == PlaceCategory.food),
          isTrue);
      expect(gateway.calls.last.category, PlaceCategory.food);
    });

    test('a filter change starts a new session: undo no longer applies',
        () async {
      final bloc = await started();
      bloc.add(FeedCardReacted(
          key: bloc.state.cards.first.key, reaction: PlaceReaction.like));
      await settle();

      bloc.add(const FeedFilterChanged(RecommendationFilter.leisure));
      await settle();

      expect(bloc.state.lastReaction, isNull);
    });

    test('a typed city becomes the location hint', () async {
      final bloc = await started(destination: 'Madrid');

      bloc.add(const FeedLocationChanged('  Granada '));
      await settle();

      expect(bloc.state.destinationHint, 'Granada');
      expect(gateway.calls.last.destinationHint, 'Granada');
    });

    test('clearing the typed city falls back to the trip destination',
        () async {
      final bloc = await started(destination: 'Madrid');
      bloc.add(const FeedLocationChanged('Granada'));
      await settle();

      bloc.add(const FeedLocationChanged('   '));
      await settle();

      expect(bloc.state.destinationHint, 'Madrid');
      expect(gateway.calls.last.destinationHint, 'Madrid');
    });

    test('the filter survives a restart of the feed', () async {
      final bloc = await started();
      bloc.add(const FeedFilterChanged(RecommendationFilter.monuments));
      await settle();

      bloc.add(const FeedStarted(destination: 'Madrid'));
      await settle();

      expect(bloc.state.filter, RecommendationFilter.monuments);
    });
  });

  group('reset the feed', () {
    test('clears dislikes, keeps favorites and offers hidden places again',
        () async {
      final bloc = await started();
      final liked = bloc.state.cards[0];
      final hidden = bloc.state.cards[1];
      bloc.add(FeedCardReacted(key: liked.key, reaction: PlaceReaction.like));
      await settle();
      bloc.add(FeedCardReacted(key: hidden.key, reaction: PlaceReaction.dislike));
      await settle();
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(hidden.key)));

      bloc.add(const FeedDislikesResetRequested());
      await settle();

      expect(repo.dislikedKeys, isEmpty);
      expect(repo.favorites.map((f) => f.key), [liked.key]);
      expect(bloc.state.cards.map((c) => c.key), contains(hidden.key));
      expect(bloc.state.cards.map((c) => c.key), isNot(contains(liked.key)));
      expect(bloc.state.notice, FeedNotice.resetDone);
    });

    test('lets an exhausted feed come back to life', () async {
      for (final place in gateway.catalog) {
        await repo.dislike(placeKeyOf(place));
      }
      final bloc = await started();
      expect(bloc.state.status, FeedStatus.exhausted);

      bloc.add(const FeedDislikesResetRequested());
      await settle();

      expect(bloc.state.status, FeedStatus.ready);
      expect(bloc.state.cards, hasLength(eligible));
    });

    test('a failed reset says so and leaves the feed as it was', () async {
      final bloc = await started();
      final before = bloc.state.cards;
      repo.writeFailure = const CacheFailure('disk full');

      bloc.add(const FeedDislikesResetRequested());
      await settle();

      expect(bloc.state.notice, FeedNotice.resetFailed);
      expect(bloc.state.cards, before);
    });
  });

  test('the injected seed makes the opening order reproducible', () async {
    final a = await started(seed: 5);
    final b = await started(seed: 5);
    final c = await started(seed: 6);

    expect(a.state.cards.map((x) => x.key), b.state.cards.map((x) => x.key));
    expect(a.state.cards.map((x) => x.key),
        isNot(c.state.cards.map((x) => x.key)));
  });

  test('every offered card carries its provider-neutral key', () async {
    final bloc = await started();

    for (final RecommendedPlace card in bloc.state.cards) {
      expect(card.key, placeKeyOf(card.place));
    }
  });
}
