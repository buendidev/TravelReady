/// Literales y textos de la app centralizados.
/// Permite futura internacionalización (i18n) sencilla.
abstract final class AppStrings {
  // ── General ──────────────────────────────────────────────────────────
  static const String appName    = 'TravelReady!';
  static const String appVersion = 'TravelReady 1.0';
  static const String appTagline = 'Tu viaje, perfectamente preparado.';

  // ── Autenticación ─────────────────────────────────────────────────────
  static const String login            = 'Iniciar sesión';
  static const String register         = 'Crear cuenta';
  static const String email            = 'Email';
  static const String password         = 'Contraseña';
  static const String confirmPassword  = 'Confirmar contraseña';
  static const String name             = 'Nombre completo';
  static const String forgotPassword   = '¿Olvidaste tu contraseña?';
  static const String noAccount        = '¿No tienes cuenta? ';
  static const String hasAccount       = '¿Ya tienes cuenta? ';
  static const String signInGoogle     = 'Continuar con Google';
  static const String resetPassword    = 'Restablecer contraseña';
  static const String logout           = 'Cerrar sesión';

  // ── Navegación ────────────────────────────────────────────────────────
  static const String navHome     = 'Inicio';
  static const String navPacking  = 'Equipaje';
  static const String navTrips    = 'Viajes';
  static const String navChats    = 'Chats';
  static const String navProfile  = 'Perfil';

  // ── Viajes ────────────────────────────────────────────────────────────
  static const String myTrips     = 'Mis viajes';
  static const String newTrip     = 'Nuevo viaje';
  static const String destination = 'Destino';
  static const String startDate   = 'Fecha de salida';
  static const String endDate     = 'Fecha de regreso';
  static const String tripName    = 'Nombre del viaje';

  // ── Listas de equipaje ────────────────────────────────────────────────
  static const String packingList    = 'Lista de equipaje';
  static const String myPackingLists = 'Mis listas';
  static const String newList        = 'Nueva lista';
  static const String addItem        = 'Añadir artículo';
  static const String itemPacked     = 'Empaquetado';
  static const String itemPending    = 'Pendiente';

  // ── Premium ───────────────────────────────────────────────────────────
  static const String goPremium       = 'Hazte Premium';
  static const String premiumMonthly  = '9,99 €/mes';
  static const String premiumYearly   = '89,99 €/año';
  static const String premiumSaving   = 'Ahorra un 25%';

  // ── Errores ───────────────────────────────────────────────────────────
  static const String errorGeneral     = 'Algo ha ido mal. Inténtalo de nuevo.';
  static const String errorNetwork     = 'Sin conexión a internet.';
  static const String errorInvalidEmail = 'Email no válido.';
  static const String errorWeakPassword = 'La contraseña debe tener al menos 6 caracteres.';
  static const String errorPasswordMatch = 'Las contraseñas no coinciden.';
  static const String errorEmptyField   = 'Este campo es obligatorio.';

  // ── Acciones generales ────────────────────────────────────────────────
  static const String save     = 'Guardar';
  static const String cancel   = 'Cancelar';
  static const String delete   = 'Eliminar';
  static const String edit     = 'Editar';
  static const String confirm  = 'Confirmar';
  static const String retry    = 'Reintentar';
  static const String loading  = 'Cargando...';
}
