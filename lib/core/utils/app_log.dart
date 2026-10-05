/// Diagnóstico de desarrollo.
///
/// Los mensajes se imprimen **solo** cuando las aserciones están activas, esto
/// es, en debug: en release no se emite nada a stdout. Así el log sigue siendo
/// útil mientras se desarrolla, sin filtrar datos del usuario ni errores
/// crudos en las compilaciones publicadas.
abstract final class AppLog {
  static void debug(String message) {
    assert(() {
      // ignore: avoid_print
      print(message);
      return true;
    }());
  }
}
