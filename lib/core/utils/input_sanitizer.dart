/// Sanitización y validación de inputs — anti-inyección para TravelReady!
/// Valida y sanitiza TODO input antes de procesarlo.
abstract final class InputSanitizer {

  // ── Sanitización básica ────────────────────────────────────────────────

  /// Elimina caracteres peligrosos. No escapa para HTML (Flutter no lo necesita).
  static String sanitize(String input) =>
      input.trim().replaceAll(RegExp(r'[<>"\x00]'), '');

  /// Sanitiza y recorta a maxLength.
  static String sanitizeTruncate(String input, int maxLength) =>
      sanitize(input).substring(0, sanitize(input).length.clamp(0, maxLength));

  // ── Validadores ────────────────────────────────────────────────────────

  static bool isValidEmail(String v) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());

  static bool isValidPassword(String v) => v.length >= 6;

  static bool isValidName(String v) {
    final s = v.trim();
    return s.length >= 2 && s.length <= 60 && !RegExp(r'[<>{}\[\]]').hasMatch(s);
  }

  static bool isValidTripName(String v) {
    final s = v.trim();
    return s.isNotEmpty && s.length <= 80;
  }

  static bool isValidDestination(String v) {
    final s = v.trim();
    return s.isNotEmpty && s.length <= 100;
  }

  static bool isValidItemName(String v) {
    final s = v.trim();
    return s.isNotEmpty && s.length <= 80;
  }

  // ── Validadores de formulario (retornan String? para Form.validator) ──

  static String? emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Campo obligatorio.';
    if (!isValidEmail(v)) return 'Email no válido.';
    return null;
  }

  static String? passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Campo obligatorio.';
    if (!isValidPassword(v)) return 'Mínimo 6 caracteres.';
    return null;
  }

  static String? nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio.';
    if (!isValidName(v)) return 'Nombre inválido (2-60 caracteres).';
    return null;
  }

  static String? requiredField(String? v, {int maxLen = 100}) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio.';
    if (v.trim().length > maxLen) return 'Máximo $maxLen caracteres.';
    return null;
  }
}
