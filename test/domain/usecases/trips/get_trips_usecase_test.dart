import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/domain/usecases/trips/get_trips_usecase.dart';
import '../../../helpers/test_helper.dart';
import '../../../helpers/fake_data.dart';

void main() {
  late GetTripsUseCase useCase;
  late MockTripsRepository mockRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    mockRepo = MockTripsRepository();
    useCase  = GetTripsUseCase(mockRepo);
  });

  const tUserId = 'user_test_01';

  group('GetTripsUseCase', () {
    test('devuelve lista de viajes en éxito', () async {
      when(() => mockRepo.getTrips(tUserId))
          .thenAnswer((_) async => Right([tTrip]));

      final result = await useCase(tUserId);

      expect(result.isRight(), true);
      expect((result as Right).value, [tTrip]);
      verify(() => mockRepo.getTrips(tUserId)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('devuelve lista vacía sin viajes', () async {
      when(() => mockRepo.getTrips(tUserId))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase(tUserId);

      expect(result.isRight(), true);
      expect((result as Right).value, isEmpty);
    });

    test('devuelve ServerFailure cuando el servidor falla', () async {
      when(() => mockRepo.getTrips(any()))
          .thenAnswer((_) async => const Left(tServerFailure));

      final result = await useCase(tUserId);

      expect(result, const Left(tServerFailure));
    });

    test('devuelve NetworkFailure sin conexión', () async {
      when(() => mockRepo.getTrips(any()))
          .thenAnswer((_) async => const Left(tNetworkFailure));

      expect(await useCase(tUserId), const Left(tNetworkFailure));
    });
  });
}
