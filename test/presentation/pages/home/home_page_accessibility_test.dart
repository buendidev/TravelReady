import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/presentation/pages/home/home_page.dart';

import '../../../helpers/test_helper.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

final _user = User(
  id: 'u1',
  name: 'Test User',
  email: 't@t.com',
  createdAt: DateTime(2026),
);

void main() {
  late MockTripsRepository repo;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  setUp(() {
    registerFallbacks();
    repo = MockTripsRepository();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthAuthenticated(user: _user));
    when(() => repo.watchTrips(any()))
        .thenAnswer((_) => Stream.value(const Right(<Trip>[])));

    if (getIt.isRegistered<TripsRepository>()) {
      getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      getIt.unregister<CreateTripUseCase>();
    }
    getIt.registerSingleton<TripsRepository>(repo);
    getIt.registerSingleton<CreateTripUseCase>(CreateTripUseCase(repo));
  });

  tearDown(() async {
    if (getIt.isRegistered<TripsRepository>()) {
      await getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      await getIt.unregister<CreateTripUseCase>();
    }
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    List<Trip> trips = const [],
    double textScale = 1,
  }) async {
    when(() => repo.watchTrips(any()))
        .thenAnswer((_) => Stream.value(Right(trips)));
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('PROFILE_PAGE')),
        ),
        GoRoute(
          path: '/trips/:id',
          builder: (_, state) => Scaffold(
            body: Text('TRIP_DETAIL:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder greetingFor(String firstName) => find.byWidgetPredicate(
        (widget) => widget is Text &&
            (widget.data?.endsWith(', $firstName! 👋') ?? false),
      );

  const nameCases = [
    (label: 'repeated spaces', name: 'Ana  Pérez', first: 'Ana', initials: 'AP'),
    (label: 'leading and trailing spaces', name: '  Ana Pérez  ', first: 'Ana', initials: 'AP'),
    (label: 'single token', name: 'Ana', first: 'Ana', initials: 'A'),
    (label: 'padded single token', name: '  Ana  ', first: 'Ana', initials: 'A'),
    (label: 'empty', name: '', first: 'viajero', initials: 'U'),
    (label: 'spaces only', name: '   ', first: 'viajero', initials: 'U'),
    (label: 'whitespace only', name: '\t\n ', first: 'viajero', initials: 'U'),
    (label: 'tabs and newlines', name: '\tAna\tPérez\nLópez\n', first: 'Ana', initials: 'AP'),
    (label: 'first two of three tokens', name: 'Ana Pérez López', first: 'Ana', initials: 'AP'),
  ];

  for (final nameCase in nameCases) {
    testWidgets('profile name handles ${nameCase.label}', (tester) async {
      when(() => authBloc.state).thenReturn(
        AuthAuthenticated(user: _user.copyWith(name: nameCase.name)),
      );

      await pumpHome(tester);

      expect(tester.takeException(), isNull);
      expect(greetingFor(nameCase.first), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.text(nameCase.initials),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('mounted Home refreshes same-ID name and plan emissions',
      (tester) async {
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    whenListen(authBloc, states.stream,
        initialState: AuthAuthenticated(user: _user));
    await pumpHome(tester);
    final mountedHome = tester.element(find.byType(HomePage));
    final premiumOffer = find.byIcon(Icons.workspace_premium_rounded);
    expect(greetingFor('Test'), findsOneWidget);
    expect(find.text('TU'), findsOneWidget);
    expect(premiumOffer, findsOneWidget);

    final renamed = _user.copyWith(name: 'Lucía Gómez');
    states.add(AuthAuthenticated(user: renamed));
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(HomePage)), same(mountedHome));
    expect(greetingFor('Lucía'), findsOneWidget);
    expect(find.text('LG'), findsOneWidget);
    expect(greetingFor('Test'), findsNothing);
    expect(find.text('TU'), findsNothing);
    expect(premiumOffer, findsOneWidget);

    states.add(AuthAuthenticated(
        user: renamed.copyWith(plan: UserPlan.premium)));
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(HomePage)), same(mountedHome));
    expect(greetingFor('Lucía'), findsOneWidget);
    expect(find.text('LG'), findsOneWidget);
    expect(premiumOffer, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-name header at 320px and 2x keeps profile usable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => authBloc.state).thenReturn(AuthAuthenticated(
      user: _user.copyWith(name: 'MaximilianoAlejandro Montenegro'),
    ));

    await pumpHome(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(greetingFor('MaximilianoAlejandro'), findsOneWidget);
    final avatar = find.byType(CircleAvatar);
    final initials = find.descendant(of: avatar, matching: find.text('MM'));
    final avatarRect = tester.getRect(avatar);
    final initialsRect = tester.getRect(initials);
    final viewport = Offset.zero & const Size(320, 800);
    expect(viewport.contains(avatarRect.topLeft), isTrue);
    expect(viewport.contains(avatarRect.bottomRight), isTrue);
    expect(avatarRect.contains(initialsRect.topLeft), isTrue);
    expect(avatarRect.contains(initialsRect.bottomRight), isTrue);
    expect(tester.getSemantics(avatar), matchesSemantics(
      label: 'Perfil', isButton: true, hasTapAction: true,
    ));

    await tester.tap(avatar);
    await tester.pumpAndSettle();

    expect(find.text('PROFILE_PAGE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contextual action prioritizes active trip and opens its detail',
      (tester) async {
    final now = DateTime.now();
    final activeTrip = Trip(
      id: 'active-trip',
      userId: _user.id,
      name: 'Active trip',
      destination: 'Madrid',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
      createdAt: now,
    );
    final upcomingTrip = Trip(
      id: 'upcoming-trip',
      userId: _user.id,
      name: 'Upcoming trip',
      destination: 'Paris',
      startDate: now.add(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 4)),
      createdAt: now,
    );

    await pumpHome(tester, trips: [upcomingTrip, activeTrip]);

    expect(find.widgetWithText(ElevatedButton, 'Preparación de equipaje'),
        findsOneWidget);
    expect(find.text('Active trip'), findsWidgets);

    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Preparación de equipaje'));
    await tester.pumpAndSettle();

    expect(find.text('TRIP_DETAIL:active-trip'), findsOneWidget);
  });

  testWidgets('profile control exposes button role and profile label',
      (tester) async {
    await pumpHome(tester);

    final node = tester.getSemantics(find.byType(CircleAvatar));
    expect(
      node,
      matchesSemantics(
        label: 'Perfil',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('profile control still navigates to the profile route',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE_PAGE'), findsOneWidget);
  });
}
