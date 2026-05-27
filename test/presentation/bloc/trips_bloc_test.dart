import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/presentation/bloc/trips/trips_bloc.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';

import '../../helpers/test_helper.dart';
import '../../helpers/fake_data.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────
class MockCreateTripUseCase extends Mock implements CreateTripUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TripsBloc bloc;
  late MockCreateTripUseCase createTrip;
  late MockTripsRepository    repo;

  setUpAll(registerFallbacks);

  setUp(() {
    createTrip = MockCreateTripUseCase();
    repo       = MockTripsRepository();

    bloc = TripsBloc(
      createTripUseCase: createTrip,
      repo:              repo,
    );
  });

  tearDown(() => bloc.close());

  // ── TripsLoaded ───────────────────────────────────────────────────────────

  group('TripsLoaded — watchTrips stream', () {
    blocTest<TripsBloc, TripsState>(
      'emite [Loading, Ready([trip])] cuando el stream devuelve datos',
      build: () {
        when(() => repo.watchTrips(tUserFull.id))
            .thenAnswer((_) => Stream.value(Right([tTrip])));
        return bloc;
      },
      act: (b) => b.add(TripsLoaded(userId: tUserFull.id)),
      expect: () => [
        const TripsLoading(),
        TripsReady([tTrip]),
      ],
    );

    blocTest<TripsBloc, TripsState>(
      'emite [Loading, Ready([])] cuando el stream devuelve lista vacía',
      build: () {
        when(() => repo.watchTrips(tUserFull.id))
            .thenAnswer((_) => Stream.value(const Right([])));
        return bloc;
      },
      act: (b) => b.add(TripsLoaded(userId: tUserFull.id)),
      expect: () => [
        const TripsLoading(),
        const TripsReady([]),
      ],
    );

    blocTest<TripsBloc, TripsState>(
      'emite [Loading, Error] cuando el stream devuelve Failure',
      build: () {
        when(() => repo.watchTrips(tUserFull.id))
            .thenAnswer((_) => Stream.value(const Left(tServerFailure)));
        return bloc;
      },
      act: (b) => b.add(TripsLoaded(userId: tUserFull.id)),
      expect: () => [
        const TripsLoading(),
        TripsError(tServerFailure.message),
      ],
    );

    blocTest<TripsBloc, TripsState>(
      'emite múltiples Ready cuando el stream emite múltiples eventos',
      build: () {
        when(() => repo.watchTrips(tUserFull.id))
            .thenAnswer((_) => Stream.fromIterable([
                  Right([tTrip]),
                  Right([tTrip, tTrip2]),
                ]));
        return bloc;
      },
      act: (b) => b.add(TripsLoaded(userId: tUserFull.id)),
      expect: () => [
        const TripsLoading(),
        TripsReady([tTrip]),
        TripsReady([tTrip, tTrip2]),
      ],
    );
  });

  // ── TripCreated ───────────────────────────────────────────────────────────

  group('TripCreated', () {
    test('llama a createTripUseCase con los parámetros correctos', () async {
      when(() => createTrip.call(any()))
          .thenAnswer((_) async => Right(tTrip));
      when(() => repo.watchTrips(tUserFull.id))
          .thenAnswer((_) => const Stream.empty());

      bloc.add(TripsLoaded(userId: tUserFull.id));
      await Future.delayed(Duration.zero);

      bloc.add(TripCreated(
        userId:      tUserFull.id,
        name:        tTrip.name,
        destination: tTrip.destination,
        startDate:   tTrip.startDate,
        endDate:     tTrip.endDate,
        tripType:    tTrip.tripType,
        transport:   tTrip.transport,
      ));
      await Future.delayed(Duration.zero);

      verify(() => createTrip.call(any())).called(1);
    });

    blocTest<TripsBloc, TripsState>(
      'no emite estado extra (stream actualiza automáticamente)',
      build: () {
        when(() => createTrip.call(any()))
            .thenAnswer((_) async => Right(tTrip));
        when(() => repo.watchTrips(tUserFull.id))
            .thenAnswer((_) => const Stream.empty());
        return bloc;
      },
      act: (b) async {
        b.add(TripsLoaded(userId: tUserFull.id));
        await Future.delayed(Duration.zero);
        b.add(TripCreated(
          userId:      tUserFull.id,
          name:        'Test',
          destination: 'Test',
          startDate:   DateTime(2026, 7, 1),
          endDate:     DateTime(2026, 7, 8),
        ));
      },
      expect: () => [const TripsLoading()],
    );
  });

  // ── TripDeleted ───────────────────────────────────────────────────────────

  group('TripDeleted', () {
    test('llama a repo.deleteTrip con el ID correcto', () async {
      when(() => repo.deleteTrip(tTrip.id))
          .thenAnswer((_) async => const Right(unit));
      when(() => repo.watchTrips(tUserFull.id))
          .thenAnswer((_) => const Stream.empty());

      bloc.add(TripsLoaded(userId: tUserFull.id));
      await Future.delayed(Duration.zero);

      bloc.add(TripDeleted(tripId: tTrip.id, userId: tUserFull.id));
      await Future.delayed(Duration.zero);

      verify(() => repo.deleteTrip(tTrip.id)).called(1);
    });
  });

  // ── TripsState equatable ──────────────────────────────────────────────────

  group('TripsState equatable', () {
    test('TripsReady con misma lista son iguales', () {
      final s1 = TripsReady([tTrip]);
      final s2 = TripsReady([tTrip]);
      expect(s1, equals(s2));
    });

    test('TripsReady con distinta lista son distintos', () {
      final s1 = TripsReady([tTrip]);
      final s2 = TripsReady([tTrip, tTrip2]);
      expect(s1, isNot(equals(s2)));
    });

    test('TripsError con mismo mensaje son iguales', () {
      const s1 = TripsError('error');
      const s2 = TripsError('error');
      expect(s1, equals(s2));
    });

    test('TripsLoading es igual a otra TripsLoading', () {
      expect(const TripsLoading(), equals(const TripsLoading()));
    });
  });
}
