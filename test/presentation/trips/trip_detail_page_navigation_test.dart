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

}
