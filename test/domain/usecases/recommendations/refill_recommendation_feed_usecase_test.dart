import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommendation_filter.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';

import '../../../support/recommendations_fakes.dart';

void main() {
  late FakePlacesGateway gateway;
  late InMemoryFavoritesRepository favorites;
  late RefillRecommendationFeedUseCase refill;

  setUp(() {
    gateway = FakePlacesGateway(catalog: fakeCatalog());
    favorites = InMemoryFavoritesRepository();
    refill = RefillRecommendationFeedUseCase(
        GetRecommendationFeedUseCase(gateway: gateway, favorites: favorites));
  });

  tearDown(() => favorites.dispose());

  Set<String> allKeys() => fakeCatalog().map(placeKeyOf).toSet();

  Future<Either<Failure, List<RecommendedPlace>>> run({
    required int remaining,
    Set<String> seen = const {},
    RecommendationFilter filter = RecommendationFilter.all,
  }) =>
      refill(
        filter: filter,
        destinationHint: 'Madrid',
        seed: 1,
        seenKeys: seen,
        remaining: remaining,
      );

  test('does not touch the provider while three or more cards remain',
      () async {
    final result = await run(remaining: 3);

    expect(result.getOrElse((f) => fail('expected Right, got $f')), isEmpty);
    expect(gateway.calls, isEmpty);
  });

  test('refills when fewer than three cards remain', () async {
    final result = await run(remaining: 2);

    expect(result.getOrElse((_) => []), isNotEmpty);
    expect(gateway.calls, isNotEmpty);
  });

  test('stops as soon as the deck is back to three cards', () async {
    gateway.catalog = [
      fakePlace('a', PlaceCategory.food),
      fakePlace('b', PlaceCategory.food),
      fakePlace('c', PlaceCategory.food),
    ];

    final added = (await run(remaining: 0)).getOrElse((_) => []);

    expect(added, hasLength(3));
    expect(gateway.calls, hasLength(1), reason: 'one attempt was enough');
  });

  test('never resurrects a key that was already seen', () async {
    final seen = allKeys();

    final added = (await run(remaining: 0, seen: seen)).getOrElse((_) => []);

    expect(added, isEmpty);
  });

  test('only adds places that were not seen', () async {
    final seen = fakeCatalog()
        .where((p) => p.category != PlaceCategory.nature)
        .map(placeKeyOf)
        .toSet();

    final added = (await run(remaining: 0, seen: seen)).getOrElse((_) => []);

    expect(added.map((c) => c.place.category).toSet(), {PlaceCategory.nature});
    expect(added.map((c) => c.key).toSet().intersection(seen), isEmpty);
  });

  test('does not offer a place reacted to in the meantime', () async {
    final liked = fakePlace('nature-0', PlaceCategory.nature);
    await favorites.like(RecommendedPlace.from(liked));

    final added = (await run(remaining: 0)).getOrElse((_) => []);

    expect(added.map((c) => c.key), isNot(contains(placeKeyOf(liked))));
  });

  test('retries at most twice per user action, then gives up', () async {
    final added =
        (await run(remaining: 0, seen: allKeys())).getOrElse((_) => []);

    expect(added, isEmpty);
    expect(gateway.calls, hasLength(2));
  });

  test('the retry asks the provider for a wider window', () async {
    await run(remaining: 0, seen: allKeys());

    expect(gateway.calls[1].limit, greaterThan(gateway.calls[0].limit));
  });

  test('the second attempt can still fill a deck the first could not',
      () async {
    var attempt = 0;
    gateway.responder = (call) {
      attempt++;
      return attempt == 1
          ? const Right([])
          : Right([fakePlace('late', PlaceCategory.food)]);
    };

    final added = (await run(remaining: 0)).getOrElse((_) => []);

    expect(added.map((c) => c.place.name), ['late']);
    expect(gateway.calls, hasLength(2));
  });

  test('a multi-category filter still obeys the two-attempt cap', () async {
    await run(
        remaining: 0,
        seen: allKeys(),
        filter: RecommendationFilter.leisure);

    // 2 attempts x 3 category searches each.
    expect(gateway.calls, hasLength(6));
  });

  test('propagates a provider failure', () async {
    gateway.failure = const ServerFailure('boom');

    final result = await run(remaining: 0);

    expect(result.swap().getOrElse((_) => fail('expected Left')),
        const ServerFailure('boom'));
  });
}
