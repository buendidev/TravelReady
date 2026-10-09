import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/repositories/favorites_repository.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/react_to_place_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/reset_dislikes_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/undo_reaction_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/presentation/bloc/recommendations/favorites_bloc.dart';
import 'package:travel_ready/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:travel_ready/presentation/pages/recommendations/recommendations_page.dart';

import '../../helpers/fake_data.dart';
import '../../support/recommendations_fakes.dart';

class _MockItineraryRepository extends Mock implements ItineraryRepository {}

class _FakeItineraryItem extends Fake implements ItineraryItem {}

const _top = ValueKey('deck-top-card');

void main() {
  late FakePlacesGateway gateway;
  late InMemoryFavoritesRepository repo;
  late _MockItineraryRepository itinerary;

  const prado = PlaceResult(
    providerId: 'prov-prado',
    photoReference: 'photo-prado',
    name: 'Museo del Prado',
    category: PlaceCategory.museum,
    address: 'C. de Ruiz de Alarcón 23, Madrid',
    latitude: 40.4138,
    longitude: -3.6921,
    websiteUri: 'https://www.museodelprado.es',
    openingHoursText: 'L–S 10:00–20:00',
    priceLevelLabel: '€€',
    shortDescription: 'Pinacoteca estatal.',
  );
  const retiro = PlaceResult(
    name: 'Parque del Retiro',
    category: PlaceCategory.nature,
    address: 'Plaza de la Independencia 7, Madrid',
    priceLevelLabel: 'Gratis',
  );

  setUpAll(() async {
    registerFallbackValue(_FakeItineraryItem());
    await initializeDateFormatting();
  });

  setUp(() {
    gateway = FakePlacesGateway(catalog: fakeCatalog(perCategory: 2));
    repo = InMemoryFavoritesRepository();
    itinerary = _MockItineraryRepository();
    when(() => itinerary.watchItems(any()))
        .thenAnswer((_) => Stream.value(const Right(<ItineraryItem>[])));
    when(() => itinerary.addItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first));

    getIt.registerSingleton<PlacesGateway>(gateway);
    getIt.registerSingleton<FavoritesRepository>(repo);
    getIt.registerFactory<ItineraryBloc>(() => ItineraryBloc(repo: itinerary));
    getIt.registerFactory<FavoritesBloc>(() => FavoritesBloc(repo: repo));
    getIt.registerFactory<RecommendationsBloc>(() {
      final feed =
          GetRecommendationFeedUseCase(gateway: gateway, favorites: repo);
      return RecommendationsBloc(
        getFeed: feed,
        refill: RefillRecommendationFeedUseCase(feed),
        react: ReactToPlaceUseCase(repo),
        undo: UndoReactionUseCase(repo),
        resetDislikes: ResetDislikesUseCase(repo),
        seedProvider: () => 1,
      );
    });
  });

  tearDown(() async {
    await getIt.reset();
    repo.dispose();
  });

  Future<void> likeFixtures() async {
    await repo.like(RecommendedPlace.from(prado), accountId: '');
    await repo.like(RecommendedPlace.from(retiro), accountId: '');
  }

  Future<void> pumpPage(
    WidgetTester t, {
    RecommendationsTab initialTab = RecommendationsTab.discover,
    Locale locale = const Locale('es'),
  }) async {
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecommendationsPage(trip: tTrip, initialTab: initialTab),
    ));
    await t.pumpAndSettle();
  }

  Future<void> openFavorites(WidgetTester t) async {
    await t.tap(find.text('Favoritos'));
    await t.pumpAndSettle();
  }

  group('tabs', () {
    testWidgets('offers Descubrir and Favoritos and starts on Descubrir',
        (t) async {
      await pumpPage(t);

      expect(find.text('Descubrir'), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.byKey(_top), findsOneWidget);
    });

    testWidgets('can open straight on Favoritos', (t) async {
      await likeFixtures();

      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      expect(find.text('Museo del Prado'), findsOneWidget);
      expect(find.byKey(_top), findsNothing);
    });

    testWidgets('switching tabs swaps the content', (t) async {
      await likeFixtures();
      await pumpPage(t);

      await openFavorites(t);
      expect(find.byKey(_top), findsNothing);
      expect(find.text('Museo del Prado'), findsOneWidget);

      await t.tap(find.text('Descubrir'));
      await t.pumpAndSettle();
      expect(find.byKey(_top), findsOneWidget);
      expect(find.text('Museo del Prado'), findsNothing);
    });

    testWidgets('the reset action only exists on Descubrir', (t) async {
      await pumpPage(t);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await openFavorites(t);

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('the labels follow the app language', (t) async {
      await pumpPage(t, locale: const Locale('en'));

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });

  group('favorites list', () {
    testWidgets('lists liked places newest first with the card visuals',
        (t) async {
      await likeFixtures();
      await pumpPage(t);

      await openFavorites(t);

      final names = t
          .widgetList<Text>(find.descendant(
              of: find.byType(ListView), matching: find.byType(Text)))
          .map((w) => w.data)
          .whereType<String>()
          .toList();
      expect(names.indexOf('Parque del Retiro'),
          lessThan(names.indexOf('Museo del Prado')),
          reason: 'the newest favorite comes first');
      expect(find.text('C. de Ruiz de Alarcón 23, Madrid'), findsOneWidget);
      expect(find.text('Museos'), findsOneWidget);
      expect(find.text('€€'), findsOneWidget);
    });

    testWidgets('an empty list explains how to add favorites', (t) async {
      await pumpPage(t);

      await openFavorites(t);

      expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    });

    testWidgets('a swipe on Descubrir shows up in Favoritos', (t) async {
      await pumpPage(t);
      final name = t
          .widget<Text>(find
              .descendant(of: find.byKey(_top), matching: find.byType(Text))
              .first)
          .data!;
      await t.fling(find.byKey(_top), const Offset(300, 0), 1500);
      await t.pumpAndSettle();

      await openFavorites(t);

      expect(find.text(name), findsOneWidget);
    });

    testWidgets('a favorite never shows the provider description', (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      await t.tap(find.text('Museo del Prado'));
      await t.pumpAndSettle();

      expect(find.text('Pinacoteca estatal.'), findsNothing);
    });

    testWidgets('a read failure is reported and can be retried', (t) async {
      repo.readFailure = const CacheFailure('db down');
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      expect(find.text('No se pudieron cargar tus favoritos'), findsOneWidget);
      expect(find.text('db down'), findsOneWidget);

      repo.readFailure = null;
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();

      expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    });
  });

  group('details and the itinerary path', () {
    testWidgets('opens the existing details sheet with the official site',
        (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      await t.tap(find.text('Museo del Prado'));
      await t.pumpAndSettle();

      expect(find.text('Sitio web oficial'), findsOneWidget);
      expect(find.text('Añadir al itinerario'), findsOneWidget);
      expect(find.textContaining('Horario'), findsOneWidget);
    });

    testWidgets('a favorite without a website has no official-site action',
        (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      await t.tap(find.text('Parque del Retiro'));
      await t.pumpAndSettle();

      expect(find.text('Sitio web oficial'), findsNothing);
      expect(find.text('Añadir al itinerario'), findsOneWidget);
    });

    testWidgets('adding a favorite persists an entry for the right trip and day',
        (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);
      await t.tap(find.text('Museo del Prado'));
      await t.pumpAndSettle();
      await t.tap(find.text('Añadir al itinerario'));
      await t.pumpAndSettle();

      final sheet = find.byType(BottomSheet).last;
      await t.tap(
          find.descendant(of: sheet, matching: find.byType(ChoiceChip)).at(1));
      await t.pumpAndSettle();
      await t.tap(find.descendant(of: sheet, matching: find.text('Añadir')));
      await t.pumpAndSettle();

      final saved =
          verify(() => itinerary.addItem(captureAny())).captured.single
              as ItineraryItem;
      expect(saved.tripId, tTrip.id);
      expect(saved.day, DateTime(2026, 7, 2));
      expect(saved.title, 'Museo del Prado');
      expect(saved.place?.websiteUri, 'https://www.museodelprado.es');
      expect(saved.place?.providerId, isNull);
      expect(find.text('Añadido al itinerario'), findsOneWidget);
    });

    testWidgets('does not confirm the add when persistence fails', (t) async {
      when(() => itinerary.addItem(any()))
          .thenAnswer((_) async => const Left(ServerFailure('write failed')));
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);
      await t.tap(find.text('Museo del Prado'));
      await t.pumpAndSettle();
      await t.tap(find.text('Añadir al itinerario'));
      await t.pumpAndSettle();

      final sheet = find.byType(BottomSheet).last;
      await t.tap(find.descendant(of: sheet, matching: find.text('Añadir')));
      await t.pumpAndSettle();

      expect(find.text('Añadido al itinerario'), findsNothing);
      expect(find.text('write failed'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNWidgets(2),
          reason: 'the sheet stays open so the traveller can retry');
    });
  });

  group('removing a favorite', () {
    testWidgets('deletes it without disliking the place', (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      await t.tap(find.byTooltip('Quitar de favoritos').first);
      await t.pumpAndSettle();

      expect(find.text('Parque del Retiro'), findsNothing);
      expect(find.text('Museo del Prado'), findsOneWidget);
      expect(repo.dislikesFor(''), isEmpty);
      expect(find.text('Quitado de favoritos'), findsOneWidget);
    });

    testWidgets('lets the place appear in the feed again', (t) async {
      gateway.catalog = [prado];
      await repo.like(RecommendedPlace.from(prado), accountId: '');
      await pumpPage(t);
      expect(find.byKey(_top), findsNothing,
          reason: 'a liked place is not offered');
      await openFavorites(t);

      await t.tap(find.byTooltip('Quitar de favoritos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Descubrir'));
      await t.pumpAndSettle();

      expect(
          find.descendant(of: find.byKey(_top), matching: find.text('Museo del Prado')),
          findsOneWidget);
    });

    testWidgets('a failed removal keeps the list and says so', (t) async {
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);
      repo.writeFailure = const CacheFailure('disk full');

      await t.tap(find.byTooltip('Quitar de favoritos').first);
      await t.pumpAndSettle();

      expect(find.text('Parque del Retiro'), findsOneWidget);
      expect(find.text('No se pudo quitar de favoritos.'), findsOneWidget);
    });

    testWidgets('the remove action is a labelled button for assistive tech',
        (t) async {
      final handle = t.ensureSemantics();
      await likeFixtures();
      await pumpPage(t, initialTab: RecommendationsTab.favorites);

      expect(find.bySemanticsLabel('Quitar de favoritos'), findsWidgets);
      handle.dispose();
    });
  });
}
