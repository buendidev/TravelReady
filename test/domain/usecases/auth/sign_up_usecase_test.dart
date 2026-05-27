import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:travel_ready/domain/usecases/auth/sign_up_usecase.dart';
import 'package:travel_ready/core/errors/failures.dart';

import '../../../helpers/test_helper.dart';
import '../../../helpers/fake_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SignUpUseCase useCase;
  late MockAuthRepository mockRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = SignUpUseCase(mockRepo);
  });

  final tParams = SignUpParams(
      name: tName, email: tEmail, password: tPassword);

  group('SignUpUseCase', () {
    test('devuelve User en registro exitoso', () async {
      when(() => mockRepo.signUp(
            name: tName, email: tEmail, password: tPassword))
          .thenAnswer((_) async => Right(tUserFull));

      final result = await useCase(tParams);

      expect(result, Right(tUserFull));
      verify(() => mockRepo.signUp(
            name: tName, email: tEmail, password: tPassword))
          .called(1);
    });

    test('devuelve AuthFailure si email ya existe', () async {
      const failure = AuthFailure('Ya existe una cuenta con este email.');
      when(() => mockRepo.signUp(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password')))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(tParams);

      expect(result, const Left(failure));
    });

    test('devuelve AuthFailure si contraseña débil', () async {
      const failure = AuthFailure('Contraseña: mínimo 6 caracteres.');
      when(() => mockRepo.signUp(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password')))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(tParams);

      expect(result, const Left(failure));
    });

    test('SignUpParams equatable', () {
      const p1 = SignUpParams(name: tName, email: tEmail, password: tPassword);
      const p2 = SignUpParams(name: tName, email: tEmail, password: tPassword);
      expect(p1, equals(p2));
    });
  });
}
