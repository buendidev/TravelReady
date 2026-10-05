import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth/sign_in_usecase.dart';
import '../../../domain/usecases/auth/sign_up_usecase.dart';
import '../../../domain/usecases/auth/sign_out_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/app_log.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase  _signIn;
  final SignUpUseCase  _signUp;
  final SignOutUseCase _signOut;
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSub;
  bool _signingUp = false;  // true mientras el stream está pausado en signup

  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required AuthRepository authRepository,
  })  : _signIn  = signInUseCase,
        _signUp  = signUpUseCase,
        _signOut = signOutUseCase,
        _repo    = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthSignOutRequested>(_onSignOut);
  }

  /// Inicia la escucha del stream de auth sin bloquear el handler.
  Future<void> _onStarted(
      AuthStarted e, Emitter<AuthState> emit) async {
    AppLog.debug('[AuthBloc] _onStarted iniciado');
    emit(const AuthLoading());
    await _authSub?.cancel();
    _authSub = _repo.authStateChanges
        .timeout(
          const Duration(seconds: 30),
          onTimeout: (sink) {
            AppLog.debug('[AuthBloc] Timeout en authStateChanges');
            // Solo cerrar sesión por timeout si actualmente NO estamos autenticados
            if (state is! AuthAuthenticated) sink.add(null);
          },
        )
        .listen(
          (user) {
            AppLog.debug('[AuthBloc] authStateChanges emit: uid=${user?.id}');
            add(_AuthUserChanged(user));
          },
          onError: (err) {
            // Error transitorio de red: si ya estamos autenticados, ignorar
            AppLog.debug('[AuthBloc] Error en authStateChanges: $err');
            if (state is! AuthAuthenticated) {
              add(const _AuthUserChanged(null));
            }
          },
        );
  }

  void _onUserChanged(_AuthUserChanged e, Emitter<AuthState> emit) {
    final user = e.user;
    AppLog.debug('[AuthBloc] _onUserChanged: uid=${user?.id}, state=$state, signingUp=$_signingUp');

    // El stream fue pausado durante signup → ignorar eventos buffereados
    if (_signingUp) return;

    // Null que llega después de un registro exitoso → es el signOut del signup
    // El router ya navegó a /login, ignorarlo para no pisar AuthRegistered
    if (user == null && state is AuthRegistered) return;

    emit(user != null
        ? AuthAuthenticated(user: user)
        : const AuthUnauthenticated());
  }

  /// Login con email + contraseña.
  Future<void> _onSignIn(
      AuthSignInRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    // Si el stream estaba pausado por un signup previo, reanudarlo
    if (_signingUp) {
      _signingUp = false;
      _authSub?.resume();
      AppLog.debug('[AuthBloc] Stream reanudado en signIn');
    }
    try {
      final result = await _signIn(
          SignInParams(email: e.email.trim().toLowerCase(), password: e.password));
      result.fold(
        (f) => emit(AuthError(message: f.message)),
        (u) => emit(AuthAuthenticated(user: u)),
      );
    } catch (e, stack) {
      AppLog.debug('[AuthBloc] Error crítico en _onSignIn: $e\n$stack');
      emit(AuthError(message: 'Error de conexión. Intenta de nuevo.'));
    }
  }

  /// Registro — emite AuthRegistered (→ navega a login, no a home).
  /// Usa un flag para ignorar eventos del stream durante signup para que
  /// Firebase no emita AuthAuthenticated antes de que hagamos signOut.
  Future<void> _onSignUp(
      AuthSignUpRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      // Activar flag para ignorar eventos del stream durante signup
      _signingUp = true;
      AppLog.debug('[AuthBloc] Flag _signingUp activado');

      final result = await _signUp(SignUpParams(
        name:     e.name.trim(),
        email:    e.email.trim().toLowerCase(),
        password: e.password,
      ));
      await result.fold(
        (f) async {
          _signingUp = false;
          emit(AuthError(message: f.message));
        },
        (_) async {
          try {
            await _signOut();
            AppLog.debug('[AuthBloc] signOut OK');
          } catch (signOutErr) {
            AppLog.debug('[AuthBloc] signOut error (ignorado): $signOutErr');
          }

          emit(AuthRegistered(email: e.email.trim().toLowerCase()));
          AppLog.debug('[AuthBloc] AuthRegistered emitido');
          // Flag sigue activo — se desactiva en _onSignIn/_onGoogle
        },
      );
    } catch (err) {
      _signingUp = false;
      emit(const AuthError(message: 'Error inesperado. Intenta de nuevo.'));
    }
  }

  /// Login con Google.
  Future<void> _onGoogle(
      AuthGoogleSignInRequested e, Emitter<AuthState> emit) async {
    AppLog.debug('[AuthBloc] _onGoogle iniciado');
    emit(const AuthLoading());
    // Si el stream estaba pausado por un signup previo, reanudarlo
    if (_signingUp) {
      _signingUp = false;
      _authSub?.resume();
      AppLog.debug('[AuthBloc] Stream reanudado en Google signIn');
    }
    try {
      final result = await _repo.signInWithGoogle();
      result.fold(
        (f) {
          AppLog.debug('[AuthBloc] Google Sign-In error: ${f.message}');
          emit(AuthError(message: f.message));
        },
        (u) {
          AppLog.debug('[AuthBloc] Google Sign-In success: uid=${u.id}');
          emit(AuthAuthenticated(user: u));
        },
      );
    } catch (e, stack) {
      AppLog.debug('[AuthBloc] Error crítico en _onGoogle: $e\n$stack');
      emit(AuthError(message: 'Error con Google. Intenta de nuevo.'));
    }
  }

  /// Logout completo.
  Future<void> _onSignOut(
      AuthSignOutRequested e, Emitter<AuthState> emit) async {
    // Asegurarse de que el stream esté activo al hacer logout manual
    if (_signingUp) {
      _signingUp = false;
      _authSub?.resume();
    }
    await _signOut();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
