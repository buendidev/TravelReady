// Capa de seguridad de TravelReady!
// Aplica: rate limiting client-side, sanitización inputs, logging seguridad.

import 'dart:collection';

/// Rate limiter local — protege auth contra fuerza bruta en cliente.
/// Firebase Auth hace el heavy-lifting server-side; esto añade UX layer.
class RateLimiter {
  // key → lista de timestamps de intentos
  static final _windows = HashMap<String, List<DateTime>>();

  // Auth: 5 intentos / 15 min. Endpoints sensibles: 10 / 15 min.
  static const _authMax      = 5;
  static const _authWindow   = Duration(minutes: 15);
  static const _generalMax   = 100;
  static const _generalWindow = Duration(minutes: 15);

  /// Devuelve true si la acción está permitida. false = bloqueada.
  /// [maxAttempts] permite sobrescribir el máximo por defecto.
  static bool check(String key, {bool isAuth = false, int? maxAttempts}) {
    final max    = maxAttempts ?? (isAuth ? _authMax    : _generalMax);
    final window = isAuth ? _authWindow : _generalWindow;
    final now    = DateTime.now();
    final list   = _windows.putIfAbsent(key, () => []);

    // Limpiar intentos fuera de la ventana
    list.removeWhere((t) => now.difference(t) > window);

    if (list.length >= max) return false;
    list.add(now);
    return true;
  }

  /// Segundos restantes hasta que se libere la ventana.
  /// [maxAttempts] permite sobrescribir el máximo para cálculo correcto.
  static int secondsUntilReset(String key, {bool isAuth = false, int? maxAttempts}) {
    final window = isAuth ? _authWindow : _generalWindow;
    final list   = _windows[key];
    if (list == null || list.isEmpty) return 0;
    final oldest = list.first;
    final reset  = oldest.add(window);
    final diff   = reset.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  static void clear(String key) => _windows.remove(key);
}
