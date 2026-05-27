import 'dart:async';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/failures.dart';
import '../../../core/security/crypto_service.dart';
import '../../../core/utils/rate_limiter.dart';
import '../../../core/utils/security_log.dart';
import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';

/// DataSource de autenticación local usando SQLite.
/// Reemplaza completamente Firebase Auth.
abstract class AuthLocalDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUserPlan(
    String userId, {
    required UserPlan plan,
    DateTime? renewalDate,
  });
  Future<void> updateUserProfile(String userId, {String? name, String? photoUrl});
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper _db;
  final _authController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  AuthLocalDataSourceImpl({required DatabaseHelper database}) : _db = database;

  String _hashEmail(String email) => CryptoService.hashEmailForLog(email);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final key = 'signin:${_hashEmail(normalizedEmail)}';
    
    // Rate limiting
    if (!RateLimiter.check(key, isAuth: true)) {
      final secs = RateLimiter.secondsUntilReset(key, isAuth: true);
      SecurityLog.rateLimitExceeded(key, 5);
      throw AuthException(
          'Demasiados intentos. Espera ${(secs / 60).ceil()} min.');
    }

    try {
      // Buscar usuario por email
      final results = await _db.query(
        DatabaseHelper.tableUsers,
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );

      if (results.isEmpty) {
        SecurityLog.authFailed(_hashEmail(normalizedEmail), 'user_not_found');
        throw const AuthException('Usuario o contraseña incorrectos.');
      }

      final userData = results.first;
      final storedHash = userData['password_hash'] as String?;

      if (storedHash == null || storedHash.isEmpty) {
        SecurityLog.authFailed(_hashEmail(normalizedEmail), 'no_password');
        throw const AuthException('Usuario o contraseña incorrectos.');
      }

      // Verificar contraseña
      if (!CryptoService.verifyPassword(password, storedHash)) {
        SecurityLog.authFailed(_hashEmail(normalizedEmail), 'wrong_password');
        throw const AuthException('Usuario o contraseña incorrectos.');
      }

      // Crear sesión
      final user = UserModel.fromMap(userData);
      _currentUser = user;
      _authController.add(user);

      // Limpiar rate limiter
      RateLimiter.clear(key);
      SecurityLog.sessionEvent('login_ok', user.id);

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      SecurityLog.authFailed(_hashEmail(normalizedEmail), 'exception: $e');
      throw AuthException('Error de autenticación: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
      String email, String password, String name) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();
    final key = 'signup:${_hashEmail(normalizedEmail)}';

    // Rate limiting
    if (!RateLimiter.check(key, isAuth: true)) {
      final secs = RateLimiter.secondsUntilReset(key, isAuth: true);
      SecurityLog.rateLimitExceeded(key, 5);
      throw AuthException(
          'Demasiados intentos. Espera ${(secs / 60).ceil()} min.');
    }

    // Validaciones
    if (trimmedName.isEmpty || trimmedName.length < 2) {
      throw const AuthException('El nombre debe tener al menos 2 caracteres.');
    }

    if (password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres.');
    }

    try {
      // Verificar si email ya existe
      final existing = await _db.query(
        DatabaseHelper.tableUsers,
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw const AuthException('Ya existe una cuenta con este email.');
      }

      // Hashear contraseña
      final passwordHash = CryptoService.hashPassword(password);

      // Crear usuario
      final userId = CryptoService.generateUuid();
      final now = DateTime.now().toIso8601String();

      final userData = {
        'id': userId,
        'name': trimmedName,
        'email': normalizedEmail,
        'password_hash': passwordHash,
        'plan': 'free',
        'created_at': now,
      };

      await _db.insert(DatabaseHelper.tableUsers, userData);

      final user = UserModel(
        id: userId,
        name: trimmedName,
        email: normalizedEmail,
        plan: UserPlan.free,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _authController.add(user);

      RateLimiter.clear(key);
      SecurityLog.sessionEvent('register_ok', userId);

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      SecurityLog.authFailed(_hashEmail(normalizedEmail), 'exception: $e');
      throw AuthException('Error al registrar: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    if (_currentUser != null) {
      SecurityLog.sessionEvent('logout', _currentUser!.id);
    }
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final key = 'reset:${_hashEmail(normalizedEmail)}';

    // Rate limiting más estricto para reset
    if (!RateLimiter.check(key, maxAttempts: 3)) {
      final secs = RateLimiter.secondsUntilReset(key, maxAttempts: 3);
      throw AuthException(
          'Demasiados intentos. Espera ${(secs / 60).ceil()} min.');
    }

    try {
      // Verificar que el usuario existe
      final results = await _db.query(
        DatabaseHelper.tableUsers,
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );

      // No revelar si el usuario existe o no (seguridad)
      if (results.isEmpty) {
        // Simular delay para no revelar que el usuario no existe
        await Future.delayed(const Duration(milliseconds: 800));
        return;
      }

      // En una app real, aquí enviaríamos email con token
      // Por ahora, simulamos el éxito
      await Future.delayed(const Duration(milliseconds: 800));
      
      SecurityLog.sessionEvent('password_reset_requested', results.first['id'] as String);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<UserModel?> get authStateChanges async* {
    // Emite inmediatamente el estado actual al suscribirse
    yield _currentUser;
    // Luego escucha cambios futuros
    yield* _authController.stream;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel> updateUserPlan(
    String userId, {
    required UserPlan plan,
    DateTime? renewalDate,
  }) async {
    try {
      final updates = {
        'plan': plan.name,
        if (renewalDate != null)
          'plan_renewal_date': renewalDate.toIso8601String(),
      };

      await _db.update(
        DatabaseHelper.tableUsers,
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Recargar usuario actual
      final results = await _db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) {
        throw const ServerException('Usuario no encontrado');
      }

      final updatedUser = UserModel.fromMap(results.first);
      
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
        _authController.add(updatedUser);
      }

      return updatedUser;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile(String userId, {String? name, String? photoUrl}) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.isNotEmpty) {
        updates['name'] = name.trim();
      }
      if (photoUrl != null) {
        updates['photo_url'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _db.update(
          DatabaseHelper.tableUsers,
          updates,
          where: 'id = ?',
          whereArgs: [userId],
        );

        // Actualizar usuario en memoria si es el actual
        if (_currentUser?.id == userId) {
          final results = await _db.query(
            DatabaseHelper.tableUsers,
            where: 'id = ?',
            whereArgs: [userId],
            limit: 1,
          );
          
          if (results.isNotEmpty) {
            _currentUser = UserModel.fromMap(results.first);
            _authController.add(_currentUser);
          }
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
