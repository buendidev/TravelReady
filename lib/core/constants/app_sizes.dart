/// Constantes de espaciado, radios y tamaños de TravelReady!
/// Sistema de diseño: "The Curated Navigator"
abstract final class AppSizes {
  // ── Espaciado base (múltiplos de 4) ───────────────────────────────────
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Radios de borde ────────────────────────────────────────────────────
  /// Inputs y elementos pequeños
  static const double radiusDefault = 16.0;   // 1rem
  /// Cards y contenedores
  static const double radiusLg      = 24.0;   // 2rem (lg)
  /// Botones CTA — completamente redondeados (StadiumBorder)
  static const double radiusFull    = 999.0;

  // ── Altura de componentes ──────────────────────────────────────────────
  static const double buttonHeight    = 52.0;
  static const double inputHeight     = 52.0;
  static const double bottomNavHeight = 72.0;
  static const double appBarHeight    = 56.0;

  // ── Tamaños de iconos ──────────────────────────────────────────────────
  static const double iconSm  = 16.0;
  static const double iconMd  = 24.0;
  static const double iconLg  = 32.0;
  static const double iconXl  = 48.0;

  // ── Padding de pantalla ────────────────────────────────────────────────
  static const double screenPaddingH = 20.0;
  static const double screenPaddingV = 24.0;

  // ── Sombra ambient estándar ────────────────────────────────────────────
  /// offset: 0px 12px 32px, on_surface al 6% de opacidad
  static const double shadowBlur   = 32.0;
  static const double shadowOffset = 12.0;
}
