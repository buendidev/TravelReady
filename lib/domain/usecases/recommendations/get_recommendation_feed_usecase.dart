import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/services/places/place_result.dart';
import '../../../core/services/places/places_failures.dart';
import '../../../core/services/places/places_gateway.dart';
import '../../entities/recommendations/recommendation_filter.dart';
import '../../repositories/favorites_repository.dart';
import 'compose_feed.dart';

/// How many places one gateway call asks for.
const int feedPageSize = 20;

/// Loads the feed for one filter and location context.
///
/// Fetches through [PlacesGateway] (one search per category of the filter, or a
/// single uncategorised search for "Todos"), then hands the merged results to
/// [composeFeed] together with every reacted-to key and every key already shown
/// this session.
class GetRecommendationFeedUseCase {
  final PlacesGateway _gateway;
  final FavoritesRepository _favorites;

  GetRecommendationFeedUseCase({
    required PlacesGateway gateway,
    required FavoritesRepository favorites,
  })  : _gateway = gateway,
        _favorites = favorites;

  /// [destinationHint] is the typed city, or the trip destination as the
  /// pre-filled default. [seenKeys] are keys already offered this session, so a
  /// reload cannot resurrect them. An unavailable provider is never called and
  /// answers [PlacesConfigFailure].
  Future<Either<Failure, FeedComposition>> call({
    required RecommendationFilter filter,
    String? destinationHint,
    required int seed,
    Set<String> seenKeys = const {},
    int limit = feedPageSize,
  }) async {
    if (_gateway.availability == PlacesAvailability.unavailable) {
      return const Left(
          PlacesConfigFailure('The places provider is not configured.'));
    }

    final reacted = await _favorites.getReactedKeys();
    final reactedFailure = reacted.fold<Failure?>((f) => f, (_) => null);
    if (reactedFailure != null) return Left(reactedFailure);

    final fetched = <PlaceResult>[];
    for (final category in filter.searchCategories) {
      final result = await _gateway.search(
        query: '',
        category: category,
        destinationHint: destinationHint,
        limit: limit,
      );
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return Left(failure);
      fetched.addAll(result.getOrElse((_) => const []));
    }

    return Right(composeFeed(
      fetched: fetched,
      filter: filter,
      excludedKeys: {...reacted.getOrElse((_) => const {}), ...seenKeys},
      seed: seed,
    ));
  }
}
