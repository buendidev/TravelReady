import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import '../../../helpers/test_helper.dart';
import '../../../helpers/fake_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CreateTripUseCase useCase;
  late MockTripsRepository mockRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    mockRepo = MockTripsRepository();
    useCase  = CreateTripUseCase(mockRepo);
  });

  final tParams = CreateTripParams(
    userId:      tUserFull.id,
    name:        tTrip.name,
    destination: tTrip.destination,
    startDate:   tTrip.startDate,
    endDate:     tTrip.endDate,
    tripType:    tTrip.tripType,
    transport:   tTrip.transport,
  );

  group('CreateTripUseCase', () {
    test('devuelve Trip cuando el repositorio responde con éxito', () async {
      when(() => mockRepo.createTrip(any()))
          .thenAnswer((_) async => Right(tTrip));

      final result = await useCase(tParams);

      expect(result.isRight(), true);
      verify(() => mockRepo.createTrip(any())).called(1);
    });

    test('pasa los parámetros correctos al repositorio', () async {
      Trip? captured;
      when(() => mockRepo.createTrip(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Trip;
        return Right(tTrip);
      });

      await useCase(tParams);

      expect(captured?.name,        tParams.name);
      expect(captured?.destination, tParams.destination);
      expect(captured?.userId,      tParams.userId);
      expect(captured?.tripType,    tParams.tripType);
    });

    test('devuelve ServerFailure cuando el servidor falla', () async {
      when(() => mockRepo.createTrip(any()))
          .thenAnswer((_) async => const Left(tServerFailure));

      final result = await useCase(tParams);

      expect(result, const Left(tServerFailure));
    });

    test('devuelve NetworkFailure sin conexión', () async {
      when(() => mockRepo.createTrip(any()))
          .thenAnswer((_) async => const Left(tNetworkFailure));

      final result = await useCase(tParams);

      expect(result, const Left(tNetworkFailure));
    });

    test('CreateTripParams equatable — mismos valores iguales', () {
      final p1 = CreateTripParams(
        userId:      tUserFull.id,
        name:        'Test',
        destination: 'Madrid',
        startDate:   DateTime(2026, 7, 1),
        endDate:     DateTime(2026, 7, 8),
      );
      final p2 = CreateTripParams(
        userId:      tUserFull.id,
        name:        'Test',
        destination: 'Madrid',
        startDate:   DateTime(2026, 7, 1),
        endDate:     DateTime(2026, 7, 8),
      );
      expect(p1, equals(p2));
    });
  });
}
