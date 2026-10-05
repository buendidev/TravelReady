import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_log.dart';

/// Valida al arrancar que todas las variables de entorno existen.
/// Si falta alguna crítica, lanza excepción antes de runApp().
abstract final class EnvValidator {
  /// Variables requeridas para que la app funcione.
  /// Si están vacías o ausentes → la app no inicia.
  static const _required = <String>[
    // API keys opcionales en dev pero obligatorias en producción:
    // 'OPENWEATHER_API_KEY',
    // 'GOOGLE_MAPS_API_KEY',
  ];

  /// Variables que deben existir pero pueden estar vacías en dev.
  static const _optional = <String>[
    'OPENWEATHER_API_KEY',
    'GOOGLE_MAPS_API_KEY',
  ];

  /// Ejecutar en main() tras dotenv.load().
  static void validate() {
    final missing = <String>[];

    for (final key in _required) {
      final val = dotenv.env[key];
      if (val == null || val.isEmpty) missing.add(key);
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Variables de entorno faltantes: ${missing.join(', ')}\n'
        'Revisa el archivo .env en la raíz del proyecto.',
      );
    }

    // Warnings para opcionales no configuradas
    for (final key in _optional) {
      final val = dotenv.env[key];
      if (val == null || val.isEmpty || val.contains('tu_api_key')) {
        // ignore: avoid_print
        AppLog.debug('[ENV] Aviso: $key no configurada — funcionalidad limitada.');
      }
    }
  }

  /// Devuelve una API key validada.
  /// Lanza si es nula o contiene el placeholder.
  static String require(String key) {
    final val = dotenv.env[key];
    if (val == null || val.isEmpty || val.contains('tu_api_key')) {
      throw StateError('Variable de entorno $key no configurada.');
    }
    return val;
  }

  static String? optional(String key) {
    final val = dotenv.env[key];
    if (val == null || val.isEmpty || val.contains('tu_api_key')) return null;
    return val;
  }
}
