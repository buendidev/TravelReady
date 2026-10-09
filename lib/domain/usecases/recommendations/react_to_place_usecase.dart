import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/recommendations/applied_reaction.dart';
import '../../entities/recommendations/recommended_place.dart';
import '../../repositories/favorites_repository.dart';

/// Right swipe likes, left swipe dislikes. The two are mutually exclusive.
class ReactToPlaceUseCase {
  final FavoritesRepository _repository;

  ReactToPlaceUseCase(this._repository);

  Future<Either<Failure, AppliedReaction>> call(
    RecommendedPlace place,
    PlaceReaction reaction, {
    required String accountId,
  }) async {
    final result = switch (reaction) {
      PlaceReaction.like =>
        await _repository.like(place, accountId: accountId),
      PlaceReaction.dislike =>
        await _repository.dislike(place.key, accountId: accountId),
    };
    return result.map((_) => AppliedReaction(place: place, reaction: reaction));
  }
}
