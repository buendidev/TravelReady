import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/places_failures.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommendation_filter.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/usecases/recommendations/compose_feed.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';

import '../../../support/recommendations_fakes.dart';

void main() {
  late FakePlacesGateway gateway;
  late InMemoryFavoritesRepository favorites;
  late GetRecommendationFeedUseCase feed;

  setUp(() {
    gateway = FakePlacesGateway(catalog: fakeCatalog());
    favorites = InMemoryFavoritesRepository();
    feed = GetRecommendationFeedUseCase(gateway: gateway, favorites: favorites);
  });

  tearDown(() => favorites.dispose());

  Future<FeedComposition> run({
    RecommendationFilter filter = RecommendationFilter.all,
    String? destinationHint = 'Madrid',
    int seed = 1,
    String accountId = 'me',
    Set<String> seenKeys = const {},
    int limit = 20,
  }) async =>
      (await feed(
        filter: filter,
        destinationHint: destinationHint,
        seed: seed,
        accountId: accountId,
        seenKeys: seenKeys,
        limit: limit,
      ))
          .getOrElse((f) => fail('expected Right, got $f'));

  group('gateway calls per filter', () {
    test('Todos searches once with no category and classifies client-side',
        () async {
      final result = await run();

      expect(gateway.calls, hasLength(1));
      expect(gateway.calls.single.category, isNull);
      expect(result.cards.map((c) => c.place.category).toSet(),
          RecommendationFilter.all.categories);
    });

    test('Monumentos searches monument and museum, then merges', () async {
      final result = await run(filter: RecommendationFilter.monuments);

      expect(gateway.calls.map((c) => c.category),
          [PlaceCategory.monument, PlaceCategory.museum]);
      expect(result.cards, hasLength(6));
    });

    test('Restaurantes searches food once', () async {
      final result = await run(filter: RecommendationFilter.restaurants);

      expect(gateway.calls.map((c) => c.category), [PlaceCategory.food]);
      expect(result.cards, hasLength(3));
    });

    test('Ocio searches nature, nightlife and shopping, then merges', () async {
      final result = await run(filter: RecommendationFilter.leisure);

      expect(gateway.calls.map((c) => c.category), [
        PlaceCategory.nature,
        PlaceCategory.nightlife,
        PlaceCategory.shopping,
      ]);
      expect(result.cards, hasLength(9));
    });

    test('passes the location hint and the limit, with no free-text query',
        () async {
      await run(destinationHint: 'Granada', limit: 40);

      expect(gateway.calls.single.destinationHint, 'Granada');
      expect(gateway.calls.single.limit, 40);
      expect(gateway.calls.single.query, isEmpty);
    });

    test('a venue returned by two searches is a single card', () async {
      gateway.responder = (call) =>
          Right([fakePlace('Prado', PlaceCategory.museum)]);

      final result = await run(filter: RecommendationFilter.monuments);

      expect(result.cards, hasLength(1));
      expect(result.eligibleCount, 1);
    });
  });

  group('exclusions', () {
    test('never offers a liked or disliked place', () async {
      final liked = RecommendedPlace.from(fakePlace('monument-0', PlaceCategory.monument));
      final disliked = RecommendedPlace.from(fakePlace('food-1', PlaceCategory.food));
      await favorites.like(liked, accountId: 'me');
      await favorites.dislike(disliked.key, accountId: 'me');

      final result = await run();

      final keys = result.cards.map((c) => c.key);
      expect(keys, isNot(contains(liked.key)));
      expect(keys, isNot(contains(disliked.key)));
    });

    test('a place another account disliked is still offered', () async {
      final disliked =
          RecommendedPlace.from(fakePlace('food-1', PlaceCategory.food));
      await favorites.dislike(disliked.key, accountId: 'someone-else');

      final result = await run(accountId: 'me');

      expect(result.cards.map((c) => c.key), contains(disliked.key));
    });

    test('never offers a key already seen this session', () async {
      final seen = placeKeyOf(fakePlace('nature-2', PlaceCategory.nature));

      final result = await run(seenKeys: {seen});

      expect(result.cards.map((c) => c.key), isNot(contains(seen)));
    });

    test('hotel and other from the provider never reach the cards', () async {
      final result = await run();

      final names = result.cards.map((c) => c.place.name);
      expect(names, isNot(contains('grand-hotel')));
      expect(names, isNot(contains('mystery')));
    });

    test('reports eligibleCount before exclusions, so empty and exhausted differ',
        () async {
      for (final place in fakeCatalog()) {
        await favorites.dislike(placeKeyOf(place), accountId: 'me');
      }

      final result = await run();

      expect(result.cards, isEmpty);
      expect(result.eligibleCount, 18);
    });

    test('an empty provider answer is empty, not exhausted', () async {
      gateway.catalog = [];

      final result = await run();

      expect(result.cards, isEmpty);
      expect(result.eligibleCount, 0);
    });
  });

  group('determinism', () {
    test('the same seed reproduces the same order', () async {
      final a = await run(seed: 9);
      final b = await run(seed: 9);

      expect(a.cards.map((c) => c.key), b.cards.map((c) => c.key));
    });

    test('a different seed changes the order', () async {
      final a = await run(seed: 9);
      final b = await run(seed: 10);

      expect(a.cards.map((c) => c.key), isNot(b.cards.map((c) => c.key)));
    });
  });

  group('failures', () {
    test('an unavailable provider is a config failure and is never called',
        () async {
      gateway.availability = PlacesAvailability.unavailable;

      final result = await feed(
          filter: RecommendationFilter.all,
          seed: 1,
          accountId: 'me',
          destinationHint: 'x');

      expect(result.swap().getOrElse((_) => fail('expected Left')),
          isA<PlacesConfigFailure>());
      expect(gateway.calls, isEmpty);
    });

    test('a demo provider is served normally', () async {
      gateway.availability = PlacesAvailability.demo;

      final result = await run();

      expect(result.cards, isNotEmpty);
    });

    test('a failing search fails the whole load', () async {
      gateway.failure = const ServerFailure('boom');

      final result =
          await feed(
          filter: RecommendationFilter.leisure,
          seed: 1,
          accountId: 'me');

      expect(result.swap().getOrElse((_) => fail('expected Left')),
          const ServerFailure('boom'));
    });

    test('one failing search among several is not hidden by the others',
        () async {
      gateway.responder = (call) => call.category == PlaceCategory.museum
          ? const Left(ServerFailure('museum search failed'))
          : Right([fakePlace('a-monument', PlaceCategory.monument)]);

      final result =
          await feed(
          filter: RecommendationFilter.monuments, seed: 1, accountId: 'me');

      expect(result.isLeft(), isTrue);
    });

    test('a failing reactions read fails the load', () async {
      favorites.readFailure = const CacheFailure('db down');

      final result = await feed(
          filter: RecommendationFilter.all, seed: 1, accountId: 'me');

      expect(result.swap().getOrElse((_) => fail('expected Left')),
          const CacheFailure('db down'));
    });
  });
}
