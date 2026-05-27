import 'package:fpdart/fpdart.dart';

import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

/// Caso de uso: Cerrar sesión del usuario.
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Either<Failure, Unit>> call() {
    return _repository.signOut();
  }
}
