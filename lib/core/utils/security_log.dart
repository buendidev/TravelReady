/// Security logger.
/// Loguea: auth fallidos, rate limit excedido, inputs rechazados.
/// NUNCA loguea: contraseñas, tokens, datos personales sensibles.
abstract final class SecurityLog {

  static const _tag = '[SECURITY]';

  /// Auth fallido — log sin contraseña ni token.
  static void authFailed(String emailHash, String reason) {
    _log('AUTH_FAIL', 'email_hash=$emailHash reason=$reason');
  }

  /// Rate limit excedido.
  static void rateLimitExceeded(String key, int attempts) {
    _log('RATE_LIMIT', 'key=$key attempts=$attempts');
  }

  /// Input rechazado por validación.
  static void inputRejected(String field, String reason) {
    _log('INPUT_REJECT', 'field=$field reason=$reason');
  }

  /// Evento de sesión (login OK, logout). Sin PII.
  ///
  /// El id puede ser más corto que el prefijo que se registra, así que se
  /// recorta de forma segura: un id corto no debe tumbar la operación.
  static void sessionEvent(String event, String userId) {
    final prefix = userId.length > 6 ? '${userId.substring(0, 6)}...' : userId;
    _log('SESSION', 'event=$event uid_prefix=$prefix');
  }

  static void _log(String type, String detail) {
    // En producción: sustituir por servicio de logging remoto (Crashlytics, etc.)
    // En debug: print al console (no a logs persistentes)
    assert(() {
      // ignore: avoid_print
      print('$_tag [$type] ${DateTime.now().toIso8601String()} $detail');
      return true;
    }());
  }
}

/// Hash simple de email para logging sin exponer PII.
String hashEmail(String email) {
  final clean = email.trim().toLowerCase();
  final code  = clean.codeUnits.fold(0, (a, b) => a ^ b);
  return code.toRadixString(16).padLeft(4, '0');
}
