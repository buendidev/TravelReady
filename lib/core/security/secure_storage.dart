import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sobre FlutterSecureStorage.
/// Almacena datos sensibles cifrados (Keystore en Android, Keychain en iOS).
/// NO usar SharedPreferences para tokens ni datos de usuario.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyTheme     = 'tr_theme_mode';
  static const _keyOnboarded = 'tr_onboarded';

  // ── Tema ─────────────────────────────────────────────────────────────
  static Future<String?> getTheme() => _storage.read(key: _keyTheme);
  static Future<void> setTheme(String mode) =>
      _storage.write(key: _keyTheme, value: mode);

  // ── Onboarding ────────────────────────────────────────────────────────
  static Future<bool> isOnboarded() async {
    final v = await _storage.read(key: _keyOnboarded);
    return v == 'true';
  }
  static Future<void> setOnboarded() =>
      _storage.write(key: _keyOnboarded, value: 'true');

  // ── Limpieza en logout ────────────────────────────────────────────────
  /// Borra solo datos de sesión, mantiene preferencias de app.
  static Future<void> clearSession() async {
    // Firebase gestiona su propio token — aquí solo limpiamos extras
    // Añadir claves adicionales de sesión si se guardan en futuro
  }

  /// Borra TODO (desinstalar / resetear cuenta).
  static Future<void> clearAll() => _storage.deleteAll();
}
