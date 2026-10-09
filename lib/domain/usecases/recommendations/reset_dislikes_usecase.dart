import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/favorites_repository.dart';

/// Clears every dislike so hidden places can be offered again. Dislikes have no
/// list in the UI by design, so this is the traveller's way out of accidental
/// swipes. Favorites are untouched.
class ResetDislikesUseCase {
  final FavoritesRepository _repository;

  ResetDislikesUseCase(this._repository);

  Future<Either<Failure, Unit>> call({required String accountId}) =>
      _repository.resetDislikes(accountId: accountId);
}
