/// Sanitiza y valida inputs del usuario antes de procesarlos.
/// Aplica reglas: trim, longitud máx, sin caracteres peligrosos.
abstract final class InputSanitizer {
  // ── Límites de longitud ──────────────────────────────────────────────
  static const int maxEmailLength    = 254;  // RFC 5321
  static const int maxPasswordLength = 128;
  static const int maxNameLength     = 100;
  static const int maxNoteLength     = 1000;
  static const int maxItemNameLength = 200;
  static const int maxCityLength     = 100;
  static const int maxTripNameLength = 150;

  // ── Regex ────────────────────────────────────────────────────────────
  static final _emailRx     = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$');
  static final _unsafeChars = RegExp(r'[<>&"\\]');

  // ── Email ────────────────────────────────────────────────────────────
  static String email(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.length > maxEmailLength) throw _err('Email demasiado largo.');
    if (!_emailRx.hasMatch(v))     throw _err('Formato de email inválido.');
    return v;
  }

  // ── Contraseña (no se modifica, solo valida) ─────────────────────────
  static String password(String raw) {
    if (raw.length < 6)                throw _err('Mínimo 6 caracteres.');
    if (raw.length > maxPasswordLength) throw _err('Contraseña demasiado larga.');
    return raw; // No trim en contraseñas — el espacio puede ser intencional
  }

  // ── Nombre de usuario ────────────────────────────────────────────────
  static String name(String raw) {
    final v = _strip(raw.trim());
    if (v.isEmpty)             throw _err('El nombre no puede estar vacío.');
    if (v.length < 2)          throw _err('El nombre debe tener al menos 2 caracteres.');
    if (v.length > maxNameLength) throw _err('Nombre demasiado largo.');
    return v;
  }

  // ── Nombre de viaje / lista ──────────────────────────────────────────
  static String tripName(String raw) {
    final v = _strip(raw.trim());
    if (v.isEmpty)                throw _err('El nombre no puede estar vacío.');
    if (v.length > maxTripNameLength) throw _err('Nombre demasiado largo.');
    return v;
  }

  // ── Nombre de artículo ───────────────────────────────────────────────
  static String itemName(String raw) {
    final v = _strip(raw.trim());
    if (v.isEmpty)                  throw _err('El nombre del artículo no puede estar vacío.');
    if (v.length > maxItemNameLength) throw _err('Nombre demasiado largo.');
    return v;
  }

  // ── Ciudad / destino ─────────────────────────────────────────────────
  static String city(String raw) {
    final v = _strip(raw.trim());
    if (v.isEmpty)             throw _err('El destino no puede estar vacío.');
    if (v.length > maxCityLength) throw _err('Nombre de ciudad demasiado largo.');
    return v;
  }

  // ── Nota / descripción libre ─────────────────────────────────────────
  static String note(String raw) {
    final v = raw.trim();
    if (v.length > maxNoteLength) throw _err('Nota demasiado larga (máx $maxNoteLength car.)');
    return _strip(v);
  }

  // ── Eliminar caracteres peligrosos ───────────────────────────────────
  static String _strip(String v) => v.replaceAll(_unsafeChars, '');

  static ArgumentError _err(String msg) => ArgumentError(msg);
}
