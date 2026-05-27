import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

/// Parámetros del caso de uso de registro.
class SignUpParams extends Equatable {
  final String name;
  final String email;
  final String password;

  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

/// Caso de uso: Registrar nuevo usuario.
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Either<Failure, User>> call(SignUpParams params) {
    return _repository.signUp(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}
