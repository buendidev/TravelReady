import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/domain/usecases/auth/sign_out_usecase.dart';
import 'package:travel_ready/core/errors/failures.dart';

import '../../../helpers/test_helper.dart';

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = SignOutUseCase(mockRepo);
  });

  group('SignOutUseCase', () {
    test('devuelve Unit en logout exitoso', () async {
      when(() => mockRepo.signOut())
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase();

      expect(result, const Right(unit));
      verify(() => mockRepo.signOut()).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('devuelve UnexpectedFailure si falla', () async {
      const failure = UnexpectedFailure('Error inesperado al cerrar sesión');
      when(() => mockRepo.signOut())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });

    test('llama al repositorio exactamente una vez', () async {
      when(() => mockRepo.signOut())
          .thenAnswer((_) async => const Right(unit));

      await useCase();

      verify(() => mockRepo.signOut()).called(1);
    });
  });
}
