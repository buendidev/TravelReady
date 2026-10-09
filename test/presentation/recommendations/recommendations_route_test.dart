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
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';
import 'package:travel_ready/data/models/packing_item_model.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/repositories/favorites_repository.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/react_to_place_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/reset_dislikes_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/undo_reaction_usecase.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/presentation/bloc/recommendations/favorites_bloc.dart';
import 'package:travel_ready/presentation/bloc/language/language_cubit.dart';
import 'package:travel_ready/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:travel_ready/presentation/bloc/theme/theme_cubit.dart';
import 'package:travel_ready/presentation/pages/recommendations/recommendations_page.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/test_helper.dart';
import '../../support/recommendations_fakes.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockTripsLocalDataSource extends Mock implements TripsLocalDataSource {}

class _MockItineraryRepository extends Mock implements ItineraryRepository {}

void main() {
  late _MockAuthBloc authBloc;
  late SharedPreferences prefs;
  late InMemoryFavoritesRepository repo;

  setUpAll(() => dotenv.loadFromString(envString: '', isOptional: true));

  setUp(() async {
    registerFallbacks();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthAuthenticated(
        user: User(id: 'u1', name: 'T', email: 't@t.com', createdAt: DateTime(2026))));

    final tripsRepository = MockTripsRepository();
    when(() => tripsRepository.watchTrips(any()))
        .thenAnswer((_) => Stream.value(const Right(<Trip>[])));
    final dataSource = _MockTripsLocalDataSource();
    when(() => dataSource.watchPackingLists(any()))
        .thenAnswer((_) => Stream.value(<PackingListModel>[]));

    final gateway = FakePlacesGateway(catalog: fakeCatalog());
    repo = InMemoryFavoritesRepository();
    getIt
      ..registerSingleton<TripsRepository>(tripsRepository)
      ..registerSingleton<PackingRepository>(MockPackingRepository())
      ..registerSingleton<CreateTripUseCase>(CreateTripUseCase(tripsRepository))
      ..registerSingleton<TripsLocalDataSource>(dataSource)
      ..registerSingleton<PlacesGateway>(gateway)
      ..registerSingleton<FavoritesRepository>(repo)
      ..registerFactory<FavoritesBloc>(() => FavoritesBloc(repo: repo))
      ..registerFactory<ItineraryBloc>(
          () => ItineraryBloc(repo: _MockItineraryRepository()))
      ..registerFactory<RecommendationsBloc>(() {
        final feed =
            GetRecommendationFeedUseCase(gateway: gateway, favorites: repo);
        return RecommendationsBloc(
          getFeed: feed,
          refill: RefillRecommendationFeedUseCase(feed),
          react: ReactToPlaceUseCase(repo),
          undo: UndoReactionUseCase(repo),
          resetDislikes: ResetDislikesUseCase(repo),
        );
      });
  });

  tearDown(() async {
    await getIt.reset();
    repo.dispose();
  });

  Future<GoRouter> pumpRouter(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final router = buildAppRouter(authBloc);
    addTearDown(router.dispose);
    await t.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs: prefs)),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit(prefs: prefs)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await t.pump();
    return router;
  }

  test('the paths are nested under the trip, next to discovery', () {
    expect(AppRoutes.recommendationsPath('abc'), '/trips/abc/recommendations');
    expect(AppRoutes.favoritesPath('abc'), '/trips/abc/favorites');
    expect(AppRoutes.favoritesPath('abc'),
        startsWith(AppRoutes.tripDetailPath('abc')));
    expect(AppRoutes.recommendationsPath('abc'),
        startsWith(AppRoutes.tripDetailPath('abc')));
  });

  testWidgets('opens the feed for the trip passed as extra', (t) async {
    final router = await pumpRouter(t);

    router.go(AppRoutes.recommendationsPath(tTrip.id), extra: tTrip);
    await t.pumpAndSettle();

    final page =
        t.widget<RecommendationsPage>(find.byType(RecommendationsPage));
    expect(page.trip, tTrip);
    expect(find.byKey(const ValueKey('deck-top-card')), findsOneWidget);
  });

  testWidgets('without a trip it falls back instead of crashing', (t) async {
    final router = await pumpRouter(t);

    router.go(AppRoutes.recommendationsPath(tTrip.id));
    await t.pumpAndSettle();

    expect(find.byType(RecommendationsPage), findsNothing);
    expect(find.text('Viaje no encontrado'), findsWidgets);
  });

  testWidgets('the favorites route opens the same page on the Favoritos tab',
      (t) async {
    final router = await pumpRouter(t);

    router.go(AppRoutes.favoritesPath(tTrip.id), extra: tTrip);
    await t.pumpAndSettle();

    final page =
        t.widget<RecommendationsPage>(find.byType(RecommendationsPage));
    expect(page.trip, tTrip);
    expect(page.initialTab, RecommendationsTab.favorites);
    expect(find.byKey(const ValueKey('deck-top-card')), findsNothing);
    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
  });

  testWidgets('the favorites route also falls back without a trip', (t) async {
    final router = await pumpRouter(t);

    router.go(AppRoutes.favoritesPath(tTrip.id));
    await t.pumpAndSettle();

    expect(find.byType(RecommendationsPage), findsNothing);
    expect(find.text('Viaje no encontrado'), findsWidgets);
  });
}
