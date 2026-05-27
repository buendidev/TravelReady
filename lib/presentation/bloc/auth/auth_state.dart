part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated({required this.user});
  @override List<Object> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override List<Object> get props => [message];
}

/// Registro exitoso → navegar a login con email pre-rellenado.
final class AuthRegistered extends AuthState {
  final String email;
  const AuthRegistered({required this.email});
  @override List<Object> get props => [email];
}
