/// Rate limiter del lado cliente.
/// Evita spam de peticiones desde la UI (doble tap, automatización básica).
/// Firebase Auth ya tiene su propio rate limiting server-side.
class ClientRateLimiter {
  final Map<String, _BucketState> _buckets = {};

  /// Comprueba si la acción [key] está permitida.
  /// [maxCalls]: peticiones permitidas en [windowSeconds].
  bool allow(String key, {int maxCalls = 5, int windowSeconds = 60}) {
    final now = DateTime.now();
    final state = _buckets[key];

    if (state == null || now.difference(state.windowStart).inSeconds >= windowSeconds) {
      // Ventana nueva
      _buckets[key] = _BucketState(count: 1, windowStart: now);
      return true;
    }

    if (state.count >= maxCalls) return false;

    state.count++;
    return true;
  }

  /// Resetea la ventana de una clave (p.ej. tras logout).
  void reset(String key) => _buckets.remove(key);

  /// Resetea todo (logout global).
  void resetAll() => _buckets.clear();
}

class _BucketState {
  int count;
  final DateTime windowStart;
  _BucketState({required this.count, required this.windowStart});
}

/// Claves predefinidas para operaciones sensibles.
abstract final class RateLimitKey {
  static const String login       = 'auth_login';
  static const String register    = 'auth_register';
  static const String resetPass   = 'auth_reset';
  static const String createTrip  = 'trip_create';
  static const String createList  = 'list_create';
  static const String addItem     = 'item_add';
  static const String googleLogin = 'auth_google';
}
