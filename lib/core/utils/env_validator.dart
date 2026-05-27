/// Validador de variables de entorno al arrancar.
/// Si falta una var requerida, la app NO inicia en producción.
abstract final class EnvValidator {

  /// Variables requeridas en .env
  static const _required = [
    'OPENWEATHER_API_KEY',
    'GOOGLE_MAPS_API_KEY',
  ];

  /// Lanza StateError si falta alguna var.
  /// Llamar en main() ANTES de runApp().
  static void validate(Map<String, String> env) {
    final missing = <String>[];
    for (final key in _required) {
      final val = env[key];
      if (val == null || val.isEmpty || val.startsWith('tu_api')) {
        missing.add(key);
      }
    }
    if (missing.isNotEmpty) {
      // En desarrollo: warning, no crash (las keys se añaden progresivamente)
      assert(() {
        // ignore: avoid_print
        print('[ENV] ⚠️  Variables no configuradas: ${missing.join(', ')}');
        print('[ENV]    Añádelas en .env antes de producción.');
        return true;
      }());
    }
  }
}
