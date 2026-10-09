import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/presentation/widgets/discovery/place_details_sheet.dart';

import '../../../helpers/fake_data.dart';

class _MockItineraryRepository extends Mock implements ItineraryRepository {}

class _FakeItineraryItem extends Fake implements ItineraryItem {}

const _place = PlaceResult(
  providerId: 'demo-prado',
  name: 'Museo Nacional del Prado',
  category: PlaceCategory.museum,
  address: 'C. de Ruiz de Alarcón 23, Madrid',
  websiteUri: 'https://www.museodelprado.es',
  openingHoursText: 'L–S 10:00–20:00',
  priceLevelLabel: '€€',
  shortDescription: 'Pinacoteca estatal.',
);

void main() {
  late _MockItineraryRepository repo;

  setUpAll(() async {
    registerFallbackValue(_FakeItineraryItem());
    await initializeDateFormatting();
  });

  setUp(() {
    repo = _MockItineraryRepository();
    when(() => repo.addItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first));
  });

  Future<void> pumpHost(WidgetTester t, {required bool withTrip}) async {
    // El bloc nace dentro del cuerpo del test: creado en setUp quedaría fuera de
    // la zona FakeAsync y sus eventos no avanzarían con pump().
    final bloc = ItineraryBloc(repo: repo);
    addTearDown(bloc.close);
    await t.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ItineraryBloc>.value(
        value: bloc,
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlaceDetailsSheet(
                context,
                place: _place,
                trip: withTrip ? tTrip : null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  testWidgets('shows the place details and the official site action',
      (t) async {
    await pumpHost(t, withTrip: false);

    expect(find.text('Museo Nacional del Prado'), findsOneWidget);
    expect(find.text('Sitio web oficial'), findsOneWidget);
    expect(find.textContaining('Horario'), findsOneWidget);
    expect(find.text('Pinacoteca estatal.'), findsOneWidget);
  });

  testWidgets('hides add-to-itinerary when there is no trip', (t) async {
    await pumpHost(t, withTrip: false);

    expect(find.text('Añadir al itinerario'), findsNothing);
  });

  testWidgets('add-to-itinerary stacks the day sheet and persists the entry',
      (t) async {
    await pumpHost(t, withTrip: true);

    await t.tap(find.text('Añadir al itinerario'));
    await t.pumpAndSettle();

    final sheet = find.byType(BottomSheet).last;
    await t.tap(find.descendant(of: sheet, matching: find.byType(ChoiceChip)).at(1));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: sheet, matching: find.text('Añadir')));
    await t.pumpAndSettle();

    final saved =
        verify(() => repo.addItem(captureAny())).captured.single as ItineraryItem;
    expect(saved.tripId, tTrip.id);
    expect(saved.day, DateTime(2026, 7, 2));
    expect(saved.title, 'Museo Nacional del Prado');
    expect(saved.place?.websiteUri, 'https://www.museodelprado.es');
    expect(find.text('Añadido al itinerario'), findsOneWidget);
  });

  testWidgets('does not confirm the add when persistence fails', (t) async {
    when(() => repo.addItem(any()))
        .thenAnswer((_) async => const Left(ServerFailure('write failed')));
    await pumpHost(t, withTrip: true);

    await t.tap(find.text('Añadir al itinerario'));
    await t.pumpAndSettle();
    final sheet = find.byType(BottomSheet).last;
    await t.tap(find.descendant(of: sheet, matching: find.text('Añadir')));
    await t.pumpAndSettle();

    expect(find.text('Añadido al itinerario'), findsNothing);
    expect(find.text('write failed'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNWidgets(2));
  });
}
