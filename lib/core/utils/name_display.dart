/// Utilidades para mostrar nombres de usuario.
///
/// Los nombres llegan de Firebase, Google o de entrada manual, así que pueden
/// traer espacios repetidos, espacios al inicio o al final, tabs o saltos de
/// línea. Todo avatar, saludo o etiqueta debe tratar esas formas como
/// separadores, nunca indexando caracteres sobre el texto crudo.
library;

/// Divide [name] por cualquier secuencia de espacios en blanco.
///
/// Devuelve una lista vacía cuando [name] está vacío o sólo tiene espacios,
/// de modo que quien lo consuma no tenga que volver a comprobarlo.
List<String> nameTokens(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? const <String>[] : trimmed.split(RegExp(r'\s+'));
}

/// Iniciales en mayúscula de [name], usando hasta los dos primeros tokens.
///
/// Devuelve [fallback] cuando [name] no tiene ningún token utilizable.
String nameInitials(String name, {String fallback = 'U'}) {
  final tokens = nameTokens(name);
  if (tokens.isEmpty) return fallback;
  return tokens.take(2).map((token) => token[0]).join().toUpperCase();
}
