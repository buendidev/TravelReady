import 'package:fpdart/fpdart.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/firebase_auth_datasource.dart';

/// Implementación del repositorio de autenticación con Firebase Auth.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _remote;

  AuthRepositoryImpl({required FirebaseAuthDataSource remote})
      : _remote = remote;

  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    try {
      final user = await _remote.signInWithEmail(email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signUpWithEmail(email, password, name);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await _remote.signInWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _remote.resetPassword(email);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges => _remote.authStateChanges;

  @override
  Future<Either<Failure, User>> updateUserPlan(
    String userId, {
    required UserPlan plan,
    DateTime? renewalDate,
  }) async {
    try {
      final user = await _remote.updateUserPlan(
        userId,
        plan: plan,
        renewalDate: renewalDate,
      );
      return Right(user);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
