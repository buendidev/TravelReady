import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';
import 'package:travel_ready/data/models/packing_item_model.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/presentation/bloc/language/language_cubit.dart';
import 'package:travel_ready/presentation/bloc/theme/theme_cubit.dart';
import 'package:travel_ready/presentation/pages/profile/profile_page.dart';

import '../../../helpers/test_helper.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockTripsLocalDataSource extends Mock
    implements TripsLocalDataSource {}

final _user = User(
  id: 'u1',
  name: 'Test User',
  email: 't@t.com',
  createdAt: DateTime(2026),
);

void main() {
  late MockTripsRepository tripsRepository;
  late MockPackingRepository packingRepository;
  late _MockAuthBloc authBloc;
  late _MockTripsLocalDataSource dataSource;
  late SharedPreferences prefs;

  setUpAll(() {
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  setUp(() async {
    registerFallbacks();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    tripsRepository = MockTripsRepository();
    packingRepository = MockPackingRepository();
    dataSource = _MockTripsLocalDataSource();
    authBloc = _MockAuthBloc();

    when(() => authBloc.state).thenReturn(AuthAuthenticated(user: _user));
    when(() => tripsRepository.watchTrips(any()))
        .thenAnswer((_) => Stream.value(const Right(<Trip>[])));
    when(() => dataSource.watchPackingLists(any()))
        .thenAnswer((_) => Stream.value(<PackingListModel>[]));

    if (getIt.isRegistered<TripsRepository>()) {
      getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<PackingRepository>()) {
      getIt.unregister<PackingRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      getIt.unregister<CreateTripUseCase>();
    }
    if (getIt.isRegistered<TripsLocalDataSource>()) {
      getIt.unregister<TripsLocalDataSource>();
    }
    getIt.registerSingleton<TripsRepository>(tripsRepository);
    getIt.registerSingleton<PackingRepository>(packingRepository);
    getIt.registerSingleton<CreateTripUseCase>(
        CreateTripUseCase(tripsRepository));
    getIt.registerSingleton<TripsLocalDataSource>(dataSource);
  });

  tearDown(() async {
    if (getIt.isRegistered<TripsRepository>()) {
      await getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<PackingRepository>()) {
      await getIt.unregister<PackingRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      await getIt.unregister<CreateTripUseCase>();
    }
    if (getIt.isRegistered<TripsLocalDataSource>()) {
      await getIt.unregister<TripsLocalDataSource>();
    }
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const ProfilePage(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs: prefs)),
          BlocProvider<LanguageCubit>(
              create: (_) => LanguageCubit(prefs: prefs)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder avatarWith(String label) => find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.text(label),
      );

  const nameCases = [
    (label: 'repeated spaces', name: 'Ana  Pérez', initials: 'AP'),
    (label: 'leading and trailing spaces', name: '  Ana Pérez  ', initials: 'AP'),
    (label: 'single token', name: 'Ana', initials: 'A'),
    (label: 'padded single token', name: '  Ana  ', initials: 'A'),
    (label: 'empty', name: '', initials: 'U'),
    (label: 'spaces only', name: '   ', initials: 'U'),
    (label: 'whitespace only', name: '\t\n ', initials: 'U'),
    (label: 'tabs and newlines', name: '\tAna\tPérez\nLópez\n', initials: 'AP'),
    (label: 'first two of three tokens', name: 'Ana Pérez López', initials: 'AP'),
  ];

  for (final nameCase in nameCases) {
    testWidgets('avatar initials handle ${nameCase.label}', (tester) async {
      when(() => authBloc.state).thenReturn(
        AuthAuthenticated(user: _user.copyWith(name: nameCase.name)),
      );

      await pumpProfile(tester);

      expect(tester.takeException(), isNull);
      expect(avatarWith(nameCase.initials), findsOneWidget);
    });
  }
}
