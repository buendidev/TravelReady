import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:travel_ready/presentation/pages/itinerary/itinerary_page.dart';

import '../../helpers/fake_data.dart';

class MockItineraryRepository extends Mock implements ItineraryRepository {}

class FakeItineraryItem extends Fake implements ItineraryItem {}

void main() {
  late MockItineraryRepository repo;

  Widget pump() => MaterialApp(home: ItineraryPage(trip: tTrip));

  setUpAll(() async {
    registerFallbackValue(FakeItineraryItem());
    await initializeDateFormatting();
  });

  setUp(() {
    repo = MockItineraryRepository();
    if (!getIt.isRegistered<ItineraryBloc>()) {
      getIt.registerFactory<ItineraryBloc>(
          () => ItineraryBloc(repo: repo));
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<ItineraryBloc>()) {
      await getIt.unregister<ItineraryBloc>();
    }
  });

  testWidgets('shows loading while the stream has not emitted', (t) async {
    when(() => repo.watchItems(tTrip.id))
        .thenAnswer((_) => const Stream.empty());
    await t.pumpWidget(pump());
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows empty state with call to action', (t) async {
    when(() => repo.watchItems(tTrip.id))
        .thenAnswer((_) => Stream.value(const Right(<ItineraryItem>[])));
    await t.pumpWidget(pump());
    await t.pumpAndSettle();
    expect(find.text('Aún no hay planes'), findsOneWidget);
    expect(find.text('Añadir plan'), findsWidgets);
  });

  testWidgets('shows error state and retry reloads', (t) async {
    var calls = 0;
    when(() => repo.watchItems(tTrip.id)).thenAnswer((_) {
      calls++;
      return Stream.value(const Left(ServerFailure('sin datos')));
    });
    await t.pumpWidget(pump());
    await t.pumpAndSettle();
    expect(find.text('sin datos'), findsOneWidget);

    await t.tap(find.text('Reintentar'));
    await t.pump();
    expect(calls, 2);
  });

  testWidgets('lists items with time and deletes via icon', (t) async {
    final item = ItineraryItem(
      id: 'it-1',
      tripId: tTrip.id,
      day: DateTime(2026, 7, 1),
      startMinutes: 600,
      endMinutes: 720,
      title: 'Museo del Prado',
      category: ItineraryCategory.sightseeing,
    );
    when(() => repo.watchItems(tTrip.id))
        .thenAnswer((_) => Stream.value(Right([item])));
    when(() => repo.deleteItem(any()))
        .thenAnswer((_) async => const Right(unit));

    await t.pumpWidget(pump());
    await t.pumpAndSettle();
    expect(find.text('Museo del Prado'), findsOneWidget);
    expect(find.textContaining('10:00'), findsOneWidget);

    await t.tap(find.byTooltip('Eliminar plan'));
    verify(() => repo.deleteItem('it-1')).called(1);
  });

  test('reorder moves the first item to the end without overflow', () {
    expect(
      reorderItineraryIds(['a', 'b', 'c'], 0, 3),
      ['b', 'c', 'a'],
    );
  });

  test('reorder preserves an upward move', () {
    expect(
      reorderItineraryIds(['a', 'b', 'c'], 2, 0),
      ['c', 'a', 'b'],
    );
  });

  testWidgets('add flow opens sheet and saves a new entry', (t) async {
    when(() => repo.watchItems(tTrip.id))
        .thenAnswer((_) => Stream.value(const Right(<ItineraryItem>[])));
    when(() => repo.addItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first));

    await t.pumpWidget(pump());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Añadir plan'));
    await t.pumpAndSettle();

    expect(find.text('Nuevo plan'), findsOneWidget);
    await t.enterText(
        find.byType(TextField).first, 'Cena en La Latina');
    await t.tap(find.text('Añadir'));
    await t.pumpAndSettle();

    final saved = verify(() => repo.addItem(captureAny()))
        .captured.single as ItineraryItem;
    expect(saved.title, 'Cena en La Latina');
    expect(saved.tripId, tTrip.id);
  });
}
