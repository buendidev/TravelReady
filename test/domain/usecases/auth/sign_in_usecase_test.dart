import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/domain/usecases/auth/sign_in_usecase.dart';
import '../../../helpers/test_helper.dart';
import '../../../helpers/fake_data.dart';

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = SignInUseCase(mockRepo);
  });

  const tParams = SignInParams(email: tEmail, password: tPassword);

  group('SignInUseCase', () {
    test('devuelve User en login exitoso', () async {
      when(() => mockRepo.signIn(tEmail, tPassword))
          .thenAnswer((_) async => Right(tUserFull));

      final result = await useCase(tParams);

      expect(result, Right(tUserFull));
      verify(() => mockRepo.signIn(tEmail, tPassword)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('devuelve AuthFailure con credenciales incorrectas', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => const Left(tAuthFailure));

      expect(await useCase(tParams), const Left(tAuthFailure));
    });

    test('devuelve NetworkFailure sin conexión', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => const Left(tNetworkFailure));

      expect(await useCase(tParams), const Left(tNetworkFailure));
    });

    test('SignInParams equatable', () {
      const p1 = SignInParams(email: tEmail, password: tPassword);
      const p2 = SignInParams(email: tEmail, password: tPassword);
      expect(p1, equals(p2));
    });
  });
}
