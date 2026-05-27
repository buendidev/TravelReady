import 'package:fpdart/fpdart.dart';

import '../../repositories/chats_repository.dart';
import '../../../core/errors/failures.dart';

/// Caso de uso: Buscar un usuario por su email exacto.
class FindUserByEmailUseCase {
  final ChatsRepository _repo;

  FindUserByEmailUseCase(this._repo);

  Future<Either<Failure, Map<String, dynamic>?>> call(String email) =>
      _repo.findUserByEmail(email);
}
