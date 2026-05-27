part of 'auth_bloc.dart';

/// Eventos del BLoC de autenticación.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Comprueba el estado de sesión al arrancar la app.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Solicita inicio de sesión con email y contraseña.
final class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Solicita registro de nuevo usuario.
final class AuthSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

/// Solicita inicio de sesión con Google.
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Solicita cierre de sesión.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Evento interno: el stream de auth emitió un nuevo usuario.
final class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
