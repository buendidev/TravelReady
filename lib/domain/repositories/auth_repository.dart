import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';
import '../../core/errors/failures.dart';

/// Contrato del repositorio de autenticación.
/// Las implementaciones están en data/repositories/.
abstract class AuthRepository {
  /// Inicia sesión con email y contraseña.
  Future<Either<Failure, User>> signIn(String email, String password);

  /// Registra un nuevo usuario.
  Future<Either<Failure, User>> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Inicia sesión con Google.
  Future<Either<Failure, User>> signInWithGoogle();

  /// Cierra la sesión del usuario actual.
  Future<Either<Failure, Unit>> signOut();

  /// Envía email de restablecimiento de contraseña.
  Future<Either<Failure, Unit>> resetPassword(String email);

  /// Devuelve el usuario actualmente autenticado, o null si no hay sesión.
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream del estado de autenticación (escucha cambios en tiempo real).
  Stream<User?> get authStateChanges;

  /// Actualiza el plan de suscripción del usuario.
  Future<Either<Failure, User>> updateUserPlan(
    String userId, {
    required UserPlan plan,
    DateTime? renewalDate,
  });
}
