import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/recommendations/recommendation_filter.dart';

void main() {
  test('Monumentos groups monument and museum with one gateway call each', () {
    expect(RecommendationFilter.monuments.categories,
        {PlaceCategory.monument, PlaceCategory.museum});
    expect(RecommendationFilter.monuments.searchCategories,
        [PlaceCategory.monument, PlaceCategory.museum]);
  });

  test('Restaurantes is food with a single gateway call', () {
    expect(RecommendationFilter.restaurants.categories, {PlaceCategory.food});
    expect(RecommendationFilter.restaurants.searchCategories,
        [PlaceCategory.food]);
  });

  test('Ocio groups nature, nightlife and shopping', () {
    expect(RecommendationFilter.leisure.categories, {
      PlaceCategory.nature,
      PlaceCategory.nightlife,
      PlaceCategory.shopping,
    });
    expect(RecommendationFilter.leisure.searchCategories, [
      PlaceCategory.nature,
      PlaceCategory.nightlife,
      PlaceCategory.shopping,
    ]);
  });

  test('Todos is the union and searches once without a category', () {
    expect(RecommendationFilter.all.categories, {
      PlaceCategory.monument,
      PlaceCategory.museum,
      PlaceCategory.food,
      PlaceCategory.nature,
      PlaceCategory.nightlife,
      PlaceCategory.shopping,
    });
    expect(RecommendationFilter.all.searchCategories, [null]);
  });

  test('Todos is the default filter', () {
    expect(RecommendationFilter.values.first, RecommendationFilter.all);
  });

  test('hotel and other never belong to any filter', () {
    for (final filter in RecommendationFilter.values) {
      expect(filter.categories, isNot(contains(PlaceCategory.hotel)));
      expect(filter.categories, isNot(contains(PlaceCategory.other)));
    }
    expect(isFeedCategory(PlaceCategory.hotel), isFalse);
    expect(isFeedCategory(PlaceCategory.other), isFalse);
    expect(isFeedCategory(PlaceCategory.food), isTrue);
  });

  test('every feed category is reachable from exactly one specific filter', () {
    final specific = RecommendationFilter.values
        .where((f) => f != RecommendationFilter.all)
        .toList();
    for (final category in RecommendationFilter.all.categories) {
      expect(specific.where((f) => f.categories.contains(category)),
          hasLength(1),
          reason: '$category must belong to a single specific filter');
    }
  });
}
