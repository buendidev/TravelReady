import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_ready/core/router/app_router.dart';
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
import 'package:travel_ready/presentation/pages/trips/trips_page.dart';

import '../helpers/test_helper.dart';

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

/// APP-2: un modal abierto debe cubrir toda la shell, incluida la barra
/// inferior. Si el sheet se apila en el navegador de la rama (default de
/// `useRootNavigator`), la barrera solo cubre el cuerpo y la barra sigue
/// operativa: el usuario puede cambiar de rama con el modal abierto.
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

  /// Router real (buildAppRouter) con AuthBloc mockeado y usuario autenticado.
  /// Se navega a /profile (rama 5 de la shell) y se abre el sheet real de
  /// edición de perfil mediante su trigger real en la página.
  Future<GoRouter> pumpShellWithProfile(WidgetTester tester) async {
    final router = buildAppRouter(authBloc);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
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
    await tester.pump();

    // El router real arranca en splash; con sesión autenticada vamos al perfil.
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget,
        reason: 'la rama /profile debe estar activa');
    return router;
  }

  testWidgets('an open modal sheet cannot be bypassed with the bottom bar',
      (tester) async {
    final router = await pumpShellWithProfile(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProfilePage)),
    );

    // Abrir el sheet real de edición de perfil desde su trigger (el avatar).
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // El sheet está abierto (trigger en el menú + título dentro del sheet).
    expect(find.text(l10n.editProfile), findsNWidgets(2),
        reason: 'el sheet de edición debe estar abierto');

    final pathWithSheetOpen =
        router.routeInformationProvider.value.uri.path;

    // Intentar cambiar de rama con el sheet abierto: la barrera del modal,
    // correctamente root-scoped, cubre la barra y absorbe el tap (no navega).
    // warnIfMissed: false porque el propósito es precisamente que el tap no
    // alcance el GestureDetector del destino: lo intercepta la barrera raíz.
    await tester.tap(find.text('Mis viajes'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      pathWithSheetOpen,
      reason:
          'con un modal abierto, tocar la barra inferior no debe cambiar de rama',
    );
    expect(find.byType(TripsPage), findsNothing,
        reason: 'la app debe seguir en la rama del perfil');
  });
}
