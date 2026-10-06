import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth/sign_in_usecase.dart';
import '../../../domain/usecases/auth/sign_up_usecase.dart';
import '../../../domain/usecases/auth/sign_out_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/datasources/local/session_snapshot_store.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase  _signIn;
  final SignUpUseCase  _signUp;
  final SignOutUseCase _signOut;
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSub;
  Timer? _startupTimer;
  Timer? _provisionalTimer;
  bool _signingUp = false;  // true mientras el stream está pausado en signup
  final SessionSnapshotStore _sessions;
  final Duration _startupGrace;
  final Duration _provisionalGrace;

  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required AuthRepository authRepository,
    SessionSnapshotStore? sessionStore,
    Duration startupGrace = const Duration(seconds: 30),
    Duration provisionalGrace = const Duration(seconds: 5),
  })  : _signIn  = signInUseCase,
        _signUp  = signUpUseCase,
        _signOut = signOutUseCase,
        _repo    = authRepository,
        _sessions = sessionStore ?? SessionSnapshotStore(),
        _startupGrace = startupGrace,
        _provisionalGrace = provisionalGrace,
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
    _startupTimer?.cancel();
    _provisionalTimer?.cancel();

    _authSub = _repo.authStateChanges.listen(
      (user) {
        // Firebase respondió: la instantánea se refresca (o se borra si ya no
        // hay sesión) y dejan de hacer falta los respaldos.
        _startupTimer?.cancel();
        _provisionalTimer?.cancel();
        user != null
            ? unawaited(_sessions.save(user))
            : unawaited(_sessions.clear());
        add(_AuthUserChanged(user));
      },
      onError: (err) {
        AppLog.debug('[AuthBloc] Error en authStateChanges: $err');
        if (state is! AuthAuthenticated) unawaited(_startOffline());
      },
    );

    // Sin conexión, el stream de Firebase puede no emitir nunca. Con el plazo
    // corto se muestra ya la sesión guardada (provisional: Firebase sigue
    // verificando en segundo plano); si no hay instantánea, no se emite nada y
    // manda el plazo exterior. El stream sigue escuchando, así que en cuanto
    // responda sustituye esa sesión por la verificada, y si responde que ya no
    // hay sesión, se cierra igual.
    _provisionalTimer = Timer(_provisionalGrace, () {
      if (state is! AuthAuthenticated) unawaited(_restoreProvisional());
    });
    _startupTimer = Timer(_startupGrace, () {
      if (state is! AuthAuthenticated) unawaited(_startOffline());
    });
  }

  /// Restauración provisional al plazo corto: se muestra la última sesión que
  /// Firebase confirmó sin esperar a que el stream responda.
  ///
  /// Si no hay instantánea no se emite nada (el plazo exterior decide), y si
  /// mientras se leía llegó una respuesta verificada, tampoco: nunca se pisa.
  Future<void> _restoreProvisional() async {
    final guardada = await _sessions.read();
    if (guardada == null || state is AuthAuthenticated) return;
    AppLog.debug('[AuthBloc] Sesión guardada restaurada (provisional)');
    add(_AuthUserChanged(guardada));
  }

  /// Arranca con la última sesión que Firebase confirmó.
  ///
  /// Es lo que permite llegar a los viajes y las maletas, que están en el
  /// dispositivo, cuando no hay red. Sin sesión guardada se emite igual que
  /// antes: no autenticado.
  Future<void> _startOffline() async {
    final guardada = await _sessions.read();
    if (guardada == null) {
      add(const _AuthUserChanged(null));
      return;
    }
    AppLog.debug('[AuthBloc] Firebase no respondió: sesión guardada restaurada');
    add(_AuthUserChanged(guardada));
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
    _startupTimer?.cancel();
    _provisionalTimer?.cancel();
    _authSub?.cancel();
    return super.close();
  }
}
