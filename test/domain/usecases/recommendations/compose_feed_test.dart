import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommendation_filter.dart';
import 'package:travel_ready/domain/usecases/recommendations/compose_feed.dart';

PlaceResult place(String name, PlaceCategory category,
        {String? address, String? providerId}) =>
    PlaceResult(
      providerId: providerId,
      name: name,
      category: category,
      address: address ?? '$name street',
    );

List<PlaceResult> sample() => [
      for (var i = 0; i < 4; i++) place('Monument $i', PlaceCategory.monument),
      for (var i = 0; i < 4; i++) place('Museum $i', PlaceCategory.museum),
      for (var i = 0; i < 4; i++) place('Food $i', PlaceCategory.food),
      for (var i = 0; i < 4; i++) place('Nature $i', PlaceCategory.nature),
    ];

List<String> names(FeedComposition c) =>
    c.cards.map((card) => card.place.name).toList();

void main() {
  FeedComposition compose(
    Iterable<PlaceResult> fetched, {
    RecommendationFilter filter = RecommendationFilter.all,
    Set<String> excluded = const {},
    int seed = 1,
  }) =>
      composeFeed(
          fetched: fetched, filter: filter, excludedKeys: excluded, seed: seed);

  group('exclusions', () {
    test('drops places already reacted to, by key', () {
      final all = sample();
      final excluded = {placeKeyOf(all[0]), placeKeyOf(all[5])};

      final result = compose(all, excluded: excluded);

      expect(names(result), isNot(contains(all[0].name)));
      expect(names(result), isNot(contains(all[5].name)));
      expect(result.cards, hasLength(all.length - 2));
    });

    test('an exclusion is matched by key, not by provider id', () {
      final original = place('Monument 0', PlaceCategory.monument,
          providerId: 'prov-old');
      final sameVenueNewId = place('monument 0', PlaceCategory.monument,
          address: 'MONUMENT 0 STREET', providerId: 'prov-new');

      final result =
          compose([sameVenueNewId], excluded: {placeKeyOf(original)});

      expect(result.cards, isEmpty);
    });

    test('hotel and other never reach the feed, even under Todos', () {
      final result = compose([
        place('Grand Hotel', PlaceCategory.hotel),
        place('Mystery', PlaceCategory.other),
        place('Cafe', PlaceCategory.food),
      ]);

      expect(names(result), ['Cafe']);
    });

    test('a filter keeps only its categories even if the gateway ignores it',
        () {
      final result = compose(sample(), filter: RecommendationFilter.restaurants);

      expect(result.cards, hasLength(4));
      expect(result.cards.every((c) => c.place.category == PlaceCategory.food),
          isTrue);
    });

    test('the same venue arriving twice is a single card', () {
      final a = place('Museum 0', PlaceCategory.museum, providerId: 'p1');
      final b = place('museum 0', PlaceCategory.museum,
          address: 'MUSEUM 0 street', providerId: 'p2');

      final result = compose([a, b, place('Food 0', PlaceCategory.food)]);

      expect(result.cards, hasLength(2));
      expect(result.eligibleCount, 2);
    });

    test('every card carries the key of its place', () {
      final result = compose(sample());

      for (final card in result.cards) {
        expect(card.key, placeKeyOf(card.place));
      }
    });
  });

  group('eligibleCount', () {
    test('counts eligible venues before exclusions, to tell empty from exhausted',
        () {
      final all = sample();
      final result = compose(all, excluded: all.map(placeKeyOf).toSet());

      expect(result.cards, isEmpty);
      expect(result.eligibleCount, all.length);
    });

    test('is zero when nothing eligible was fetched', () {
      final result = compose([place('Grand Hotel', PlaceCategory.hotel)]);

      expect(result.cards, isEmpty);
      expect(result.eligibleCount, 0);
    });

    test('is zero for an empty fetch', () {
      final result = compose(const []);

      expect(result.cards, isEmpty);
      expect(result.eligibleCount, 0);
    });
  });

  group('ordering', () {
    test('the same seed gives the same order twice', () {
      expect(names(compose(sample(), seed: 42)), names(compose(sample(), seed: 42)));
    });

    test('a different seed gives a different order', () {
      expect(names(compose(sample(), seed: 42)),
          isNot(names(compose(sample(), seed: 43))));
    });

    test('is a permutation of the eligible places', () {
      final all = sample();

      final result = compose(all, seed: 7);

      expect(result.cards.map((c) => c.key).toSet(),
          all.map(placeKeyOf).toSet());
      expect(result.cards, hasLength(all.length));
    });

    test('does not depend on the iteration order of the exclusion set', () {
      final all = sample();
      final a = {placeKeyOf(all[1]), placeKeyOf(all[2])};
      final b = {placeKeyOf(all[2]), placeKeyOf(all[1])};

      expect(names(compose(all, excluded: a, seed: 3)),
          names(compose(all, excluded: b, seed: 3)));
    });

    test('Todos alternates categories instead of listing them in blocks', () {
      for (final seed in [1, 2, 3, 99]) {
        final cards = compose(sample(), seed: seed).cards;

        for (var i = 1; i < cards.length; i++) {
          expect(cards[i].place.category,
              isNot(cards[i - 1].place.category),
              reason: 'seed $seed: cards ${i - 1} and $i share a category');
        }
      }
    });

    test('alternation survives uneven buckets until the small ones run out', () {
      final fetched = [
        for (var i = 0; i < 5; i++) place('Food $i', PlaceCategory.food),
        place('Nature 0', PlaceCategory.nature),
      ];

      final cards = compose(fetched, seed: 5).cards;

      expect(cards.take(2).map((c) => c.place.category).toSet(), hasLength(2));
      expect(cards.where((c) => c.place.category == PlaceCategory.food),
          hasLength(5));
    });

    test('the opening category varies with the seed', () {
      final firstCategories = {
        for (var seed = 0; seed < 20; seed++)
          compose(sample(), seed: seed).cards.first.place.category,
      };

      expect(firstCategories.length, greaterThan(1));
    });

    test('does not mutate the fetched list', () {
      final all = sample();
      final snapshot = List<PlaceResult>.of(all);

      compose(all, seed: 11);

      expect(all, snapshot);
    });
  });
}
