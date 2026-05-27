import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/domain/usecases/auth/sign_in_usecase.dart';
import 'package:travel_ready/domain/usecases/auth/sign_up_usecase.dart';
import 'package:travel_ready/domain/usecases/auth/sign_out_usecase.dart';
import 'package:travel_ready/core/errors/failures.dart';

import '../../helpers/test_helper.dart';
import '../../helpers/fake_data.dart';

// ── Mocks de UseCases ─────────────────────────────────────────────────────
class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthBloc bloc;
  late MockSignInUseCase signIn;
  late MockSignUpUseCase signUp;
  late MockSignOutUseCase signOut;
  late MockAuthRepository repo;

  setUpAll(registerFallbacks);

  setUp(() {
    signIn  = MockSignInUseCase();
    signUp  = MockSignUpUseCase();
    signOut = MockSignOutUseCase();
    repo    = MockAuthRepository();

    // authStateChanges vacío por defecto → no emite usuario
    when(() => repo.authStateChanges)
        .thenAnswer((_) => const Stream.empty());

    // signOut es llamado tras registro exitoso
    when(() => signOut.call())
        .thenAnswer((_) async => const Right(unit));

    bloc = AuthBloc(
      signInUseCase:  signIn,
      signUpUseCase:  signUp,
      signOutUseCase: signOut,
      authRepository: repo,
    );
  });

  tearDown(() => bloc.close());

  // ── SignIn ────────────────────────────────────────────────────────────────

  group('SignIn con email', () {
    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Authenticated] en login exitoso',
      build: () {
        when(() => signIn.call(any()))
            .thenAnswer((_) async => Right(tUserFull));
        return bloc;
      },
      act: (b) => b.add(
          AuthSignInRequested(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(user: tUserFull),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Error] con credenciales incorrectas',
      build: () {
        when(() => signIn.call(any()))
            .thenAnswer((_) async => const Left(tAuthFailure));
        return bloc;
      },
      act: (b) => b.add(
          AuthSignInRequested(email: tEmail, password: 'wrong')),
      expect: () => [
        const AuthLoading(),
        AuthError(message: tAuthFailure.message),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Error] sin conexión',
      build: () {
        when(() => signIn.call(any()))
            .thenAnswer((_) async => const Left(tNetworkFailure));
        return bloc;
      },
      act: (b) => b.add(
          AuthSignInRequested(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        AuthError(message: tNetworkFailure.message),
      ],
    );
  });

  // ── SignUp ────────────────────────────────────────────────────────────────

  group('SignUp', () {
    blocTest<AuthBloc, AuthState>(
      'emite [Loading, AuthRegistered] en registro exitoso → va a login',
      build: () {
        when(() => signUp.call(any()))
            .thenAnswer((_) async => Right(tUserFull));
        return bloc;
      },
      act: (b) => b.add(AuthSignUpRequested(
          name: tName, email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        AuthRegistered(email: tEmail),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Error] si el email ya existe',
      build: () {
        when(() => signUp.call(any()))
            .thenAnswer((_) async =>
                const Left(AuthFailure('Ya existe una cuenta con este email.')));
        return bloc;
      },
      act: (b) => b.add(AuthSignUpRequested(
          name: tName, email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        const AuthError(
            message: 'Ya existe una cuenta con este email.'),
      ],
    );
  });

  // ── SignOut ───────────────────────────────────────────────────────────────

  group('SignOut', () {
    blocTest<AuthBloc, AuthState>(
      'emite [Unauthenticated] al cerrar sesión',
      build: () => bloc,
      act: (b) => b.add(const AuthSignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );
  });

  // ── Google ────────────────────────────────────────────────────────────────

  group('Google Sign In', () {
    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Authenticated] en login Google exitoso',
      build: () {
        when(() => repo.signInWithGoogle())
            .thenAnswer((_) async => Right(tUserFull));
        return bloc;
      },
      act: (b) => b.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(user: tUserFull),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [Loading, Error] si el usuario cancela Google',
      build: () {
        when(() => repo.signInWithGoogle())
            .thenAnswer((_) async =>
                const Left(AuthFailure('Login cancelado.')));
        return bloc;
      },
      act: (b) => b.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Login cancelado.'),
      ],
    );
  });

  // ── States equatable ─────────────────────────────────────────────────────

  group('AuthState equatable', () {
    test('AuthAuthenticated con mismo user son iguales', () {
      final s1 = AuthAuthenticated(user: tUserFull);
      final s2 = AuthAuthenticated(user: tUserFull);
      expect(s1, equals(s2));
    });

    test('AuthError con mismo mensaje son iguales', () {
      const s1 = AuthError(message: 'test');
      const s2 = AuthError(message: 'test');
      expect(s1, equals(s2));
    });

    test('AuthRegistered con mismo email son iguales', () {
      const s1 = AuthRegistered(email: 'a@b.com');
      const s2 = AuthRegistered(email: 'a@b.com');
      expect(s1, equals(s2));
    });
  });
}
