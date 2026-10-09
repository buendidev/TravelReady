/// Jerarquía de errores de TravelReady!
/// Todos los fallos del sistema heredan de [Failure].
/// Se usa junto con fpdart: `Either<Failure, T>`
library;

import 'package:equatable/equatable.dart';

// ────────────────────────────────────────────────────────────────────────────
// Clase base abstracta
// ────────────────────────────────────────────────────────────────────────────

/// Clase base para todos los fallos de la aplicación.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

// ────────────────────────────────────────────────────────────────────────────
// Tipos de fallo concretos
// ────────────────────────────────────────────────────────────────────────────

/// Error de servidor / Firebase
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor. Inténtalo de nuevo.']);
}

/// Error de caché / SQLite local
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error al acceder a datos locales.']);
}

/// Sin conexión a internet
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet.']);
}

/// Error de autenticación (credenciales, sesión expirada, etc.)
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación.']);
}

/// Recurso no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

/// Error de validación (inputs del usuario)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Error desconocido / inesperado
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Error inesperado.']);
}

// ────────────────────────────────────────────────────────────────────────────
// Excepciones internas (lanzadas en data layer, convertidas a Failure)
// ────────────────────────────────────────────────────────────────────────────

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Error del servidor.']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Error de caché.']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Sin conexión.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Error de autenticación.']);
}
