import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import 'package:travel_ready/presentation/bloc/packing/packing_bloc.dart';
import 'package:travel_ready/domain/entities/packing_item.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';

import '../../helpers/test_helper.dart';
import '../../helpers/fake_data.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────
class MockTripsLocalDS extends Mock implements TripsLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PackingBloc bloc;
  late MockPackingRepository repo;
  late MockTripsLocalDS ds;

  setUpAll(registerFallbacks);

  setUp(() {
    repo = MockPackingRepository();
    ds   = MockTripsLocalDS();

    // Registra el mock en GetIt para que PackingBloc lo use internamente
    final getIt = GetIt.instance;
    if (getIt.isRegistered<TripsLocalDataSource>()) {
      getIt.unregister<TripsLocalDataSource>();
    }
    getIt.registerSingleton<TripsLocalDataSource>(ds);

    bloc = PackingBloc(repo: repo);
  });

  tearDown(() {
    bloc.close();
    GetIt.instance.unregister<TripsLocalDataSource>();
  });

  // ── PackingListsLoaded ────────────────────────────────────────────────────

  group('PackingListsLoaded — stream real-time', () {
    blocTest<PackingBloc, PackingState>(
      'emite [Loading, Ready] con lista del stream',
      build: () {
        when(() => ds.watchPackingLists(tTrip.id))
            .thenAnswer((_) => Stream.value([tPackingList]));
        return bloc;
      },
      act: (b) => b.add(PackingListsLoaded(tripId: tTrip.id)),
      expect: () => [
        const PackingLoading(),
        PackingListsReady(lists: [tPackingList], tripId: tTrip.id),
      ],
    );

    blocTest<PackingBloc, PackingState>(
      'emite [Loading, Error] cuando el stream falla',
      build: () {
        when(() => ds.watchPackingLists(any()))
            .thenAnswer((_) => Stream.error(Exception('fail')));
        return bloc;
      },
      act: (b) => b.add(PackingListsLoaded(tripId: tTrip.id)),
      expect: () => [
        const PackingLoading(),
        const PackingError('Error cargando listas.'),
      ],
    );

    blocTest<PackingBloc, PackingState>(
      'emite [Loading, Ready([])] para lista vacía',
      build: () {
        when(() => ds.watchPackingLists(any()))
            .thenAnswer((_) => Stream.value([]));
        return bloc;
      },
      act: (b) => b.add(PackingListsLoaded(tripId: 'userId123')),
      expect: () => [
        const PackingLoading(),
        PackingListsReady(lists: const [], tripId: 'userId123'),
      ],
    );
  });

  // ── PackingItemToggled — el stream emite la actualización, no optimistic ──

  group('PackingItemToggled', () {
    final unpackedItem = PackingItem(
      id: 'item_01', listId: tPackingList.id,
      tripId: tTrip.id, name: 'Pasaporte', isPacked: false,
    );

    test('llama a repo.updateItem con el item toggled', () async {
      when(() => ds.watchPackingLists(tTrip.id))
          .thenAnswer((_) => const Stream.empty());
      when(() => repo.updateItem(any()))
          .thenAnswer((_) async => Right(unpackedItem.toggle()));

      bloc.add(PackingListsLoaded(tripId: tTrip.id));
      await Future.delayed(Duration.zero);

      bloc.add(PackingItemToggled(unpackedItem));
      await Future.delayed(Duration.zero);

      verify(() => repo.updateItem(any())).called(1);
    });
  });

  // ── PackingListCreated ────────────────────────────────────────────────────

  group('PackingListCreated', () {
    test('llama a repo.createList con el nombre correcto', () async {
      when(() => ds.watchPackingLists(tTrip.id))
          .thenAnswer((_) => const Stream.empty());
      when(() => repo.createList(any()))
          .thenAnswer((_) async => Right(tPackingList));

      bloc.add(PackingListsLoaded(tripId: tTrip.id));
      await Future.delayed(Duration.zero);

      bloc.add(PackingListCreated(tripId: tTrip.id, name: 'Mi Maleta'));
      await Future.delayed(Duration.zero);

      verify(() => repo.createList(any())).called(1);
    });

    test('no procesa nombres vacíos', () async {
      when(() => ds.watchPackingLists(any()))
          .thenAnswer((_) => const Stream.empty());

      bloc.add(PackingListsLoaded(tripId: tTrip.id));
      await Future.delayed(Duration.zero);

      bloc.add(PackingListCreated(tripId: tTrip.id, name: ''));
      await Future.delayed(Duration.zero);

      verifyNever(() => repo.createList(any()));
    });
  });

  // ── PackingState equatable ────────────────────────────────────────────────

  group('PackingState equatable', () {
    test('PackingListsReady con mismas listas son iguales', () {
      final s1 = PackingListsReady(lists: [tPackingList], tripId: tTrip.id);
      final s2 = PackingListsReady(lists: [tPackingList], tripId: tTrip.id);
      expect(s1, equals(s2));
    });

    test('PackingError con mismo mensaje son iguales', () {
      const s1 = PackingError('error');
      const s2 = PackingError('error');
      expect(s1, equals(s2));
    });

    test('PackingLoading son iguales', () {
      expect(const PackingLoading(), equals(const PackingLoading()));
    });
  });
}
