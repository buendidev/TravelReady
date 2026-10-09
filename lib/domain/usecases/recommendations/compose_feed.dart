import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import '../../entities/recommendations/recommendation_filter.dart';
import '../../entities/recommendations/recommended_place.dart';

/// Result of [composeFeed].
class FeedComposition extends Equatable {
  /// Cards still worth showing, in presentation order.
  final List<RecommendedPlace> cards;

  /// Distinct feed-eligible venues that were fetched, counted **before**
  /// removing the ones already reacted to. Zero means the provider had nothing
  /// for this filter (empty); more than zero with no [cards] means the traveller
  /// has already reacted to all of them (exhausted).
  final int eligibleCount;

  const FeedComposition({required this.cards, required this.eligibleCount});

  @override
  List<Object?> get props => [cards, eligibleCount];
}

/// Pure, deterministic feed assembly. Same inputs and seed, same output.
///
/// 1. Keep only places whose category the [filter] lets through. This is also
///    where `hotel` and `other` are dropped, and it protects a specific filter
///    from a gateway that ignores the requested category.
/// 2. De-duplicate by place key: merged per-category searches can return the
///    same venue twice.
/// 3. Remove every key in [excludedKeys] (likes, dislikes and keys already shown
///    this session), so a reload can never resurrect them.
/// 4. Group by category, shuffle each group and the order of the groups with
///    the injected [seed], then interleave round-robin.
///
/// The shuffle happens inside each category rather than over the interleaved
/// list on purpose: a global shuffle after interleaving would destroy the
/// alternation that the interleave exists to guarantee.
FeedComposition composeFeed({
  required Iterable<PlaceResult> fetched,
  required RecommendationFilter filter,
  required Set<String> excludedKeys,
  required int seed,
}) {
  final allowed = filter.categories;
  final seen = <String>{};
  final eligible = <RecommendedPlace>[];
  for (final place in fetched) {
    if (!allowed.contains(place.category)) continue;
    final card = RecommendedPlace.from(place);
    if (seen.add(card.key)) eligible.add(card);
  }

  final buckets = <PlaceCategory, List<RecommendedPlace>>{};
  for (final card in eligible) {
    if (excludedKeys.contains(card.key)) continue;
    buckets.putIfAbsent(card.place.category, () => []).add(card);
  }

  final random = Random(seed);
  final order = PlaceCategory.values.where(buckets.containsKey).toList();
  for (final category in order) {
    buckets[category]!.shuffle(random);
  }
  order.shuffle(random);

  final cards = <RecommendedPlace>[];
  for (var round = 0;; round++) {
    var added = false;
    for (final category in order) {
      final bucket = buckets[category]!;
      if (round < bucket.length) {
        cards.add(bucket[round]);
        added = true;
      }
    }
    if (!added) break;
  }
  return FeedComposition(cards: cards, eligibleCount: eligible.length);
}
