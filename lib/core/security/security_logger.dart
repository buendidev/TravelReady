/// Logger de seguridad.
/// Registra eventos relevantes SIN datos sensibles.
/// En producción se conectaría a Firebase Crashlytics o similar.
abstract final class SecurityLogger {
  static bool _verbose = false;

  static void setVerbose(bool v) => _verbose = v;

  // ── Auth events ───────────────────────────────────────────────────────
  static void loginAttempt(String email) =>
      _log('AUTH_ATTEMPT', 'email=${_mask(email)}');

  static void loginSuccess(String uid) =>
      _log('AUTH_SUCCESS', 'uid=${_shortUid(uid)}');

  static void loginFailed(String email, String reason) =>
      _log('AUTH_FAILED', 'email=${_mask(email)} reason=$reason');

  static void signUpAttempt(String email) =>
      _log('SIGNUP_ATTEMPT', 'email=${_mask(email)}');

  static void signUpFailed(String email, String reason) =>
      _log('SIGNUP_FAILED', 'email=${_mask(email)} reason=$reason');

  static void resetPasswordAttempt(String email) =>
      _log('RESET_ATTEMPT', 'email=${_mask(email)}');

  static void rateLimitHit(String key) =>
      _log('RATE_LIMIT', 'key=$key');

  static void invalidInput(String field, String reason) =>
      _log('INVALID_INPUT', 'field=$field reason=$reason');

  static void signOut(String uid) =>
      _log('SIGN_OUT', 'uid=${_shortUid(uid)}');

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Enmascara email: pa***@gmail.com
  static String _mask(String email) {
    if (email.length < 3) return '***';
    final atIdx = email.indexOf('@');
    if (atIdx < 2) return '***@${email.substring(atIdx + 1)}';
    return '${email.substring(0, 2)}***${email.substring(atIdx)}';
  }

  /// Acorta UID para logs: solo primeros 8 chars
  static String _shortUid(String uid) =>
      uid.length > 8 ? '${uid.substring(0, 8)}...' : uid;

  static void _log(String event, String detail) {
    // ignore: avoid_print — solo en debug
    if (_verbose) {
      final ts = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('[SECURITY $ts] $event | $detail');
    }
    // TODO (producción): enviar a Firebase Crashlytics / Analytics
    // FirebaseCrashlytics.instance.log('[$event] $detail');
  }
}
