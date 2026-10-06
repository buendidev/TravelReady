import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_ready/data/datasources/local/session_snapshot_store.dart';
import 'package:travel_ready/data/models/user_model.dart';
import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/usecases/auth/sign_in_usecase.dart';
import 'package:travel_ready/domain/usecases/auth/sign_out_usecase.dart';
import 'package:travel_ready/domain/usecases/auth/sign_up_usecase.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';

import '../../helpers/test_helper.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockSessionStore extends Mock implements SessionSnapshotStore {}

final _guardado = UserModel(
  id: 'u-guardado',
  name: 'Pepito',
  email: 'pepito@gmail.com',
  plan: UserPlan.premium,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// Arranque sin red: el stream de Firebase no emite dentro del margen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository repo;
  late MockSessionStore store;

  setUpAll(registerFallbacks);

  AuthBloc build({
    Duration grace = const Duration(milliseconds: 40),
    Duration provisionalGrace = const Duration(milliseconds: 20),
  }) =>
      AuthBloc(
        signInUseCase: MockSignInUseCase(),
        signUpUseCase: MockSignUpUseCase(),
        signOutUseCase: MockSignOutUseCase(),
        authRepository: repo,
        sessionStore: store,
        startupGrace: grace,
        provisionalGrace: provisionalGrace,
      );

  Future<void> settle([int ms = 200]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    repo = MockAuthRepository();
    store = MockSessionStore();
    when(() => store.read()).thenAnswer((_) async => null);
    when(() => store.save(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
  });

  test('arranca con la sesión guardada cuando Firebase no responde a tiempo',
      () async {
    when(() => store.read()).thenAnswer((_) async => _guardado);
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthStarted());
    await settle();

    expect(bloc.state, isA<AuthAuthenticated>(),
        reason: 'sin red no se puede mandar al login a alguien con sesión');
    expect((bloc.state as AuthAuthenticated).user.id, 'u-guardado');
    verify(() => store.read()).called(1);
  });

  test('sin sesión guardada sigue yendo a no autenticado', () async {
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthStarted());
    await settle();

    expect(bloc.state, isA<AuthUnauthenticated>());
  });

  test('una emisión real sustituye la sesión guardada y refresca la instantánea',
      () async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);
    when(() => repo.authStateChanges).thenAnswer((_) => controller.stream);
    when(() => store.read()).thenAnswer((_) async => _guardado);
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthStarted());
    await settle();
    expect((bloc.state as AuthAuthenticated).user.id, 'u-guardado');

    final verificado = UserModel(
      id: 'u-real',
      name: 'Pepito Real',
      email: 'pepito@gmail.com',
      createdAt: DateTime.utc(2026, 2, 2),
    );
    controller.add(verificado);
    await settle();

    expect((bloc.state as AuthAuthenticated).user.id, 'u-real');
    verify(() => store.save(any())).called(1);
  });

  test('una emisión nula borra la instantánea', () async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);
    when(() => repo.authStateChanges).thenAnswer((_) => controller.stream);
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthStarted());
    await settle();
    controller.add(null);
    await settle();

    expect(bloc.state, isA<AuthUnauthenticated>());
    verify(() => store.clear()).called(1);
  });

  test('un fallo del stream también recurre a la sesión guardada', () async {
    when(() => repo.authStateChanges)
        .thenAnswer((_) => Stream<User?>.error(Exception('sin red')));
    when(() => store.read()).thenAnswer((_) async => _guardado);
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthStarted());
    await settle();

    expect(bloc.state, isA<AuthAuthenticated>(),
        reason: 'un error de red no cierra la sesión de nadie');
  });

  group('restauración provisional', () {
    final verificado = UserModel(
      id: 'u-real',
      name: 'Pepito Real',
      email: 'pepito@gmail.com',
      createdAt: DateTime.utc(2026, 2, 2),
    );

    test('sin emisión, la sesión guardada aparece en el plazo provisional, sin esperar la gracia exterior',
        () async {
      when(() => store.read()).thenAnswer((_) async => _guardado);
      final bloc = build(
        grace: const Duration(seconds: 10),
        provisionalGrace: const Duration(milliseconds: 20),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await settle();

      expect(bloc.state, isA<AuthAuthenticated>(),
          reason: 'con el plazo provisional vencido no hay que esperar 30 s '
              'de splash para llegar a la sesión guardada');
      expect((bloc.state as AuthAuthenticated).user.id, 'u-guardado');
    });

    test('una emisión verificada posterior sustituye la sesión provisional',
        () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      when(() => repo.authStateChanges).thenAnswer((_) => controller.stream);
      when(() => store.read()).thenAnswer((_) async => _guardado);
      final bloc = build(
        grace: const Duration(seconds: 10),
        provisionalGrace: const Duration(milliseconds: 20),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await settle();
      expect((bloc.state as AuthAuthenticated).user.id, 'u-guardado');

      controller.add(verificado);
      await settle();

      expect((bloc.state as AuthAuthenticated).user.id, 'u-real');
      verify(() => store.save(any())).called(1);
    });

    test('una emisión nula posterior cierra la sesión provisional y borra la instantánea',
        () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      when(() => repo.authStateChanges).thenAnswer((_) => controller.stream);
      when(() => store.read()).thenAnswer((_) async => _guardado);
      final bloc = build(
        grace: const Duration(seconds: 10),
        provisionalGrace: const Duration(milliseconds: 20),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await settle();
      expect(bloc.state, isA<AuthAuthenticated>());

      controller.add(null);
      await settle();

      expect(bloc.state, isA<AuthUnauthenticated>(),
          reason: 'la respuesta verificada manda siempre, también la nula');
      verify(() => store.clear()).called(1);
    });

    test('si la respuesta verificada llega antes del plazo provisional, la instantánea no se lee',
        () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      when(() => repo.authStateChanges).thenAnswer((_) => controller.stream);
      final bloc = build(
        grace: const Duration(seconds: 10),
        provisionalGrace: const Duration(milliseconds: 500),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await settle(50);
      controller.add(verificado);
      await settle();
      expect((bloc.state as AuthAuthenticated).user.id, 'u-real');

      // Se rebasa el plazo provisional: no debe haberse leído la instantánea
      // ni emitirse estado provisional alguno.
      await settle(600);
      expect((bloc.state as AuthAuthenticated).user.id, 'u-real');
      verifyNever(() => store.read());
    });

    test('sin instantánea, el plazo provisional no cambia el comportamiento actual',
        () async {
      final bloc = build(
        grace: const Duration(milliseconds: 60),
        provisionalGrace: const Duration(milliseconds: 20),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await settle(40);
      expect(bloc.state, isA<AuthLoading>(),
          reason: 'sin sesión guardada el plazo provisional no emite nada');

      await settle();
      expect(bloc.state, isA<AuthUnauthenticated>(),
          reason: 'la gracia exterior sigue siendo el plazo final');
    });
  });

  group('SessionSnapshotStore', () {
    test('guarda y recupera la sesión completa', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SessionSnapshotStore();

      await store.save(_guardado);
      final leido = await store.read();

      expect(leido?.id, _guardado.id);
      expect(leido?.name, _guardado.name);
      expect(leido?.email, _guardado.email);
      expect(leido?.plan, UserPlan.premium);

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('una instantánea ilegible no rompe el arranque', () async {
      SharedPreferences.setMockInitialValues(
          {'auth_session_snapshot': 'esto no es json'});
      final store = SessionSnapshotStore();

      expect(await store.read(), isNull);
    });
  });
}
