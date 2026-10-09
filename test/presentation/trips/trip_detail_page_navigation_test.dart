import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';
import 'package:travel_ready/data/models/packing_item_model.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/pages/trips/trip_detail_page.dart';

class _MockPackingRepository extends Mock implements PackingRepository {}
class _MockTripsLocalDataSource extends Mock implements TripsLocalDataSource {}

final _trip = Trip(
  id: 'trip-1',
  userId: 'user-1',
  name: 'Escapada a Valencia',
  destination: 'Valencia, España',
  startDate: DateTime(2026, 7, 1),
  endDate: DateTime(2026, 7, 3),
  createdAt: DateTime(2026),
);

void main() {
  late _MockTripsLocalDataSource dataSource;

  setUp(() {
    dataSource = _MockTripsLocalDataSource();
    when(() => dataSource.watchPackingLists(_trip.id))
        .thenAnswer((_) => Stream.value(<PackingListModel>[]));

    if (getIt.isRegistered<PackingRepository>()) {
      getIt.unregister<PackingRepository>();
    }
    if (getIt.isRegistered<TripsLocalDataSource>()) {
      getIt.unregister<TripsLocalDataSource>();
    }
    getIt.registerSingleton<PackingRepository>(_MockPackingRepository());
    getIt.registerSingleton<TripsLocalDataSource>(dataSource);
  });

  tearDown(() async {
    await getIt.unregister<PackingRepository>();
    await getIt.unregister<TripsLocalDataSource>();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    Size size = const Size(800, 1200),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/trips/${_trip.id}',
      routes: [
        GoRoute(
          path: '/trips/:id',
          builder: (_, __) => TripDetailPage(trip: _trip),
          routes: [
            GoRoute(
              path: 'itinerary',
              builder: (_, state) => Text(
                'itinerary:${identical(state.extra, _trip)}',
              ),
            ),
            GoRoute(
              path: 'discovery',
              builder: (_, state) => Text(
                'discovery:${identical(state.extra, _trip)}',
              ),
            ),
            GoRoute(
              path: 'recommendations',
              builder: (_, state) => Text(
                'recommendations:${identical(state.extra, _trip)}',
              ),
            ),
            GoRoute(
              path: 'favorites',
              builder: (_, state) => Text(
                'favorites:${identical(state.extra, _trip)}',
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('fits the empty packing state in a constrained viewport',
      (tester) async {
    await pumpDetail(tester, size: const Size(360, 600));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows accessible itinerary and discovery planning actions',
      (tester) async {
    await pumpDetail(tester);

    expect(find.text('Planifica tu viaje'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Itinerario'),
        findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Descubrir destinos'),
        findsOneWidget);
  });

  testWidgets('itinerary action pushes its nested route with the current trip',
      (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Itinerario'));
    await tester.pumpAndSettle();

    expect(find.text('itinerary:true'), findsOneWidget);
  });

  testWidgets('discovery action pushes its nested route with the current trip',
      (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Descubrir destinos'));
    await tester.pumpAndSettle();

    expect(find.text('discovery:true'), findsOneWidget);
  });

  testWidgets('shows accessible recommendations and favorites actions',
      (tester) async {
    await pumpDetail(tester);

    expect(find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Recomendaciones'),
        findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Favoritos'),
        findsOneWidget);
  });

  testWidgets('recommendations action pushes its nested route with the trip',
      (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Recomendaciones'));
    await tester.pumpAndSettle();

    expect(find.text('recommendations:true'), findsOneWidget);
  });

  testWidgets('favorites action pushes its nested route with the trip',
      (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('favorites:true'), findsOneWidget);
  });

  testWidgets('the favorites action does not claim the favorites are per trip',
      (tester) async {
    await pumpDetail(tester);

    expect(find.textContaining('este viaje'), findsNothing,
        reason: 'favorites are kept on the device, not per trip');
  });
}
