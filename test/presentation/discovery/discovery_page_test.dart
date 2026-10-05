import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/demo_places_gateway.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/pages/discovery/discovery_page.dart';

import '../../helpers/fake_data.dart';

class MockItineraryRepository extends Mock implements ItineraryRepository {}

class FakeItineraryItem extends Fake implements ItineraryItem {}

class _UnavailableGateway implements PlacesGateway {
  @override
  PlacesAvailability get availability => PlacesAvailability.unavailable;
  @override
  String? get attributionText => null;
  @override
  Future<Either<Failure, List<PlaceResult>>> search({
    required String query,
    PlaceCategory? category,
    String? destinationHint,
    int limit = 20,
  }) async =>
      const Left(ServerFailure('no provider'));
}

void main() {
  late MockItineraryRepository repo;

  Widget pump({required bool withTrip}) =>
      MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoveryPage(trip: withTrip ? tTrip : null));

  setUpAll(() async {
    registerFallbackValue(FakeItineraryItem());
    await initializeDateFormatting();
  });

  setUp(() {
    repo = MockItineraryRepository();
    when(() => repo.watchItems(any()))
        .thenAnswer((_) => Stream.value(const Right(<ItineraryItem>[])));
    when(() => repo.addItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first));
    getIt.registerFactory<ItineraryBloc>(() => ItineraryBloc(repo: repo));
  });

  tearDown(() async {
    await getIt.unregister<ItineraryBloc>();
    if (getIt.isRegistered<PlacesGateway>()) {
      await getIt.unregister<PlacesGateway>();
    }
  });

  void registerDemo() {
    getIt.registerLazySingleton<PlacesGateway>(
        () => const DemoPlacesGateway(latency: Duration.zero));
  }

  group('DemoPlacesGateway', () {
    test('filters by query and category deterministically', () async {
      const gw = DemoPlacesGateway(latency: Duration.zero);
      expect(gw.availability, PlacesAvailability.demo);

      final all = (await gw.search(query: '')).getOrElse((_) => []);
      expect(all.length, greaterThanOrEqualTo(8));

      final prado =
          (await gw.search(query: 'prado')).getOrElse((_) => []);
      expect(prado.single.name, contains('Prado'));

      final museums = (await gw.search(
              query: '', category: PlaceCategory.museum))
          .getOrElse((_) => []);
      expect(museums.every((p) => p.category == PlaceCategory.museum),
          isTrue);
    });

    test('toSnapshot drops non-persisted fields', () async {
      const gw = DemoPlacesGateway(latency: Duration.zero);
      final place =
          (await gw.search(query: 'prado')).getOrElse((_) => []).single;
      expect(place.shortDescription, isNotNull);
      final snap = place.toSnapshot();
      expect(snap.name, place.name);
      expect(snap.websiteUri, place.websiteUri);
    });
  });

  group('DiscoveryPage', () {
    testWidgets('shows demo badge and fixture results', (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      expect(find.textContaining('Datos de ejemplo'), findsOneWidget);
      expect(find.text('Museo Nacional del Prado'), findsOneWidget);
    });

    testWidgets('category chip filters results', (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      await t.tap(find.widgetWithText(ChoiceChip, 'Museos'));
      await t.pumpAndSettle();
      expect(find.text('Museo Nacional del Prado'), findsOneWidget);
      expect(find.text('Parque de El Retiro'), findsNothing);
    });

    testWidgets('search with no match shows empty state', (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField).first, 'zzz inexistente');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(find.text('Sin resultados'), findsOneWidget);
    });

    testWidgets('unavailable provider shows honest state', (t) async {
      getIt.registerLazySingleton<PlacesGateway>(
          () => _UnavailableGateway());
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      expect(find.text('Proveedor no disponible'), findsOneWidget);
      expect(find.text('Museo Nacional del Prado'), findsNothing);
    });

    testWidgets('card tap opens details with official site action',
        (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      await t.tap(find.text('Museo Nacional del Prado'));
      await t.pumpAndSettle();

      expect(find.text('Sitio web oficial'), findsOneWidget);
      expect(find.text('Añadir al itinerario'), findsOneWidget);
      expect(find.textContaining('Horario'), findsOneWidget);
    });

    testWidgets('hides add-to-itinerary when there is no trip',
        (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: false));
      await t.pumpAndSettle();

      await t.tap(find.text('Museo Nacional del Prado'));
      await t.pumpAndSettle();

      expect(find.text('Sitio web oficial'), findsOneWidget);
      expect(find.text('Añadir al itinerario'), findsNothing);
    });

    testWidgets('does not confirm add-to-itinerary when persistence fails',
        (t) async {
      when(() => repo.addItem(any()))
          .thenAnswer((_) async => const Left(ServerFailure('write failed')));
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      await t.tap(find.text('Museo Nacional del Prado'));
      await t.pumpAndSettle();
      await t.tap(find.text('Añadir al itinerario'));
      await t.pumpAndSettle();

      final sheet = find.byType(BottomSheet).last;
      await t.tap(find.descendant(of: sheet, matching: find.text('Añadir')));
      await t.pumpAndSettle();

      expect(find.text('Añadido al itinerario'), findsNothing);
      expect(find.text('write failed'), findsOneWidget);
    });

    testWidgets('add-to-itinerary persists entry via repository',
        (t) async {
      registerDemo();
      await t.pumpWidget(pump(withTrip: true));
      await t.pumpAndSettle();

      await t.tap(find.text('Museo Nacional del Prado'));
      await t.pumpAndSettle();
      await t.tap(find.text('Añadir al itinerario'));
      await t.pumpAndSettle();

      // Sheet: elegir segundo día + guardar (scoped a la hoja de
      // día/hora — la de detalles y los chips de categoría no tienen
      // ChoiceChips con ese contenido)
      final sheet = find.byType(BottomSheet).last;
      final dayChips = find.descendant(
          of: sheet, matching: find.byType(ChoiceChip));
      expect(dayChips, findsWidgets);
      await t.tap(dayChips.at(1));
      await t.pumpAndSettle();
      await t.tap(
          find.descendant(of: sheet, matching: find.text('Añadir')));
      await t.pumpAndSettle();

      final saved = verify(() => repo.addItem(captureAny()))
          .captured
          .single as ItineraryItem;
      expect(saved.tripId, tTrip.id);
      expect(saved.title, 'Museo Nacional del Prado');
      expect(saved.day, DateTime(2026, 7, 2));
      expect(saved.place?.websiteUri,
          'https://www.museodelprado.es');
      expect(find.text('Añadido al itinerario'), findsOneWidget);
    });
  });
}
