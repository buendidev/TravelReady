import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

/// Parámetros del caso de uso de inicio de sesión.
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// Caso de uso: Iniciar sesión con email y contraseña.
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Either<Failure, User>> call(SignInParams params) {
    return _repository.signIn(params.email, params.password);
  }
}
