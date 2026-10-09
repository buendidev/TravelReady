import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/recommendations/recommendation_filter.dart';
import '../../entities/recommendations/recommended_place.dart';
import 'get_recommendation_feed_usecase.dart';

/// A refill is considered when fewer unreacted cards than this remain.
const int feedRefillThreshold = 3;

/// A single user action never triggers more than this many refill attempts, so
/// a provider that has nothing new cannot cause a request loop.
const int feedMaxRefillAttempts = 2;

/// Tops the deck up when it is running low.
///
/// Every attempt passes the seen keys, so the reload cannot resurrect a card
/// that was already offered. The provider has no paging, so each attempt asks
/// for a wider window (`limit`) than the previous one; the keys already seen are
/// then removed from it.
class RefillRecommendationFeedUseCase {
  final GetRecommendationFeedUseCase _feed;

  RefillRecommendationFeedUseCase(this._feed);

  /// Returns only genuinely new cards, in presentation order. An empty list
  /// means there was nothing to add: either [remaining] is still above the
  /// threshold, or the provider has nothing new for this filter.
  Future<Either<Failure, List<RecommendedPlace>>> call({
    required RecommendationFilter filter,
    String? destinationHint,
    required int seed,
    required String accountId,
    required Set<String> seenKeys,
    required int remaining,
  }) async {
    final added = <RecommendedPlace>[];
    final seen = {...seenKeys};

    for (var attempt = 1; attempt <= feedMaxRefillAttempts; attempt++) {
      if (remaining + added.length >= feedRefillThreshold) break;

      final result = await _feed(
        filter: filter,
        destinationHint: destinationHint,
        seed: seed,
        accountId: accountId,
        seenKeys: seen,
        limit: feedPageSize * (attempt + 1),
      );
      var fresh = const <RecommendedPlace>[];
      final failure = result.fold<Failure?>((f) => f, (page) {
        fresh = page.cards;
        return null;
      });
      if (failure != null) return Left(failure);

      for (final card in fresh) {
        if (seen.add(card.key)) added.add(card);
      }
    }
    return Right(added);
  }
}
