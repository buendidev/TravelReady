import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/recommendations/applied_reaction.dart';
import '../../repositories/favorites_repository.dart';

/// Single-step undo of the last swipe. Undoing a like removes the favorite
/// (it does not dislike the place); undoing a dislike lets the place be
/// offered again.
class UndoReactionUseCase {
  final FavoritesRepository _repository;

  UndoReactionUseCase(this._repository);

  Future<Either<Failure, Unit>> call(AppliedReaction applied,
          {required String accountId}) =>
      switch (applied.reaction) {
        PlaceReaction.like => _repository.removeFavorite(applied.place.key,
            accountId: accountId),
        PlaceReaction.dislike => _repository.removeDislike(applied.place.key,
            accountId: accountId),
      };
}
