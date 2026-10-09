import '../../../core/services/places/place_category.dart';

/// The three product filters plus the default, mapped onto the
/// provider-neutral [PlaceCategory].
///
/// Product rule: `hotel` and `other` never appear in the feed. A hotel is not a
/// recommendation of a place to visit, so no filter contains them and
/// [isFeedCategory] rejects them.
enum RecommendationFilter {
  /// Default: every feed category, mixed.
  all,
  monuments,
  restaurants,
  leisure;

  /// Categories this filter lets through.
  Set<PlaceCategory> get categories => switch (this) {
        RecommendationFilter.all => _feedCategories,
        RecommendationFilter.monuments => const {
            PlaceCategory.monument,
            PlaceCategory.museum,
          },
        RecommendationFilter.restaurants => const {PlaceCategory.food},
        RecommendationFilter.leisure => const {
            PlaceCategory.nature,
            PlaceCategory.nightlife,
            PlaceCategory.shopping,
          },
      };

  /// One entry per gateway call. `all` searches once without a category and
  /// classifies client-side; the others search once per category and merge.
  List<PlaceCategory?> get searchCategories => switch (this) {
        RecommendationFilter.all => const [null],
        _ => categories.toList(),
      };
}

const Set<PlaceCategory> _feedCategories = {
  PlaceCategory.monument,
  PlaceCategory.museum,
  PlaceCategory.food,
  PlaceCategory.nature,
  PlaceCategory.nightlife,
  PlaceCategory.shopping,
};

/// Whether a place of [category] may be recommended at all.
bool isFeedCategory(PlaceCategory category) =>
    _feedCategories.contains(category);
