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
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

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
