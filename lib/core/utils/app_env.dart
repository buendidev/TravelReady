import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acceso tipado y null-safe a variables de entorno.
/// Nunca usa dotenv.env['KEY'] directamente.
abstract final class AppEnv {

  // ── OpenWeatherMap ─────────────────────────────────────────────────────
  /// Devuelve la clave o '' si no está configurada.
  /// En producción, validar con EnvValidator antes de runApp().
  static String get openWeatherKey =>
      dotenv.maybeGet('OPENWEATHER_API_KEY') ?? '';

  // ── Google Maps ────────────────────────────────────────────────────────
  static String get googleMapsKey =>
      dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '';

  // ── RevenueCat ───────────────────────────────────────────────────────────
  static String get revenueCatApiKey =>
      dotenv.maybeGet('REVENUECAT_API_KEY') ?? '';

  static String get revenueCatApiKeyIOS =>
      dotenv.maybeGet('REVENUECAT_API_KEY_IOS') ?? revenueCatApiKey;

  static bool get hasRevenueCatKey => _isSet('REVENUECAT_API_KEY');

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Ambas claves configuradas y con valor real.
  static bool get isFullyConfigured =>
      _isSet('OPENWEATHER_API_KEY') && _isSet('GOOGLE_MAPS_API_KEY');

  /// Solo la clave de clima está configurada.
  static bool get hasWeatherKey => _isSet('OPENWEATHER_API_KEY');

  /// Solo la clave de mapas está configurada.
  static bool get hasMapsKey => _isSet('GOOGLE_MAPS_API_KEY');

  static bool _isSet(String key) {
    final v = dotenv.maybeGet(key);
    return v != null && v.isNotEmpty && !v.startsWith('tu_');
  }
}
