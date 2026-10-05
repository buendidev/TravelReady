import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/presentation/pages/itinerary/itinerary_page.dart';

import '../../helpers/fake_data.dart';

class MockItineraryRepository extends Mock implements ItineraryRepository {}
class FakeItineraryItem extends Fake implements ItineraryItem {}

/// El editor de planes tenía los textos en español escritos a mano, así que con
/// la app en inglés seguía saliendo en español. Aquí se fija el idioma y se
/// exige el texto traducido, incluidos los nombres de las categorías.
void main() {
  late MockItineraryRepository repo;

  setUpAll(() async {
    registerFallbackValue(FakeItineraryItem());
    await initializeDateFormatting();
  });

  setUp(() {
    repo = MockItineraryRepository();
    // Con un stream que no emite, la pagina se queda en el spinner y
    // pumpAndSettle no termina nunca: se emite una lista vacia.
    when(() => repo.watchItems(tTrip.id))
        .thenAnswer((_) => Stream.value(const Right(<ItineraryItem>[])));
    if (!getIt.isRegistered<ItineraryBloc>()) {
      getIt.registerFactory<ItineraryBloc>(() => ItineraryBloc(repo: repo));
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<ItineraryBloc>()) {
      await getIt.unregister<ItineraryBloc>();
    }
  });

  Future<void> pump(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ItineraryPage(trip: tTrip),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('un plan nuevo se crea con el editor en inglés', (tester) async {
    await pump(tester, const Locale('en'));

    await tester.tap(find.byTooltip('Add plan'));
    await tester.pumpAndSettle();

    expect(find.text('New plan'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Museum, restaurant, activity…'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('End · optional'), findsOneWidget);

    for (final label in const [
      'Sightseeing',
      'Food',
      'Transport',
      'Lodging',
      'Activity',
      'Other',
    ]) {
      expect(find.text(label), findsOneWidget,
          reason: 'falta la categoría "$label" en inglés');
    }

    // y no puede quedar nada en español
    for (final spanish in const [
      'Nuevo plan',
      'Título',
      'Notas',
      'Visita',
      'Comida',
      'Opcional',
    ]) {
      expect(find.text(spanish), findsNothing,
          reason: '"$spanish" seguía en español con la app en inglés');
    }
  });

  testWidgets('el mismo editor sigue en español con la app en español',
      (tester) async {
    await pump(tester, const Locale('es'));

    await tester.tap(find.byTooltip('Añadir plan'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo plan'), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Visita'), findsOneWidget);
  });
}
