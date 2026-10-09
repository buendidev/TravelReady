// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'TravelReady!';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Crear cuenta';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get name => 'Nombre completo';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signInGoogle => 'Continuar con Google';

  @override
  String get noAccount => '¿No tienes cuenta? ';

  @override
  String get hasAccount => '¿Ya tienes cuenta? ';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get sendResetEmail => 'Enviar email de recuperación';

  @override
  String get home => 'Inicio';

  @override
  String get myTrips => 'Mis viajes';

  @override
  String get packingLists => 'Mis maletas';

  @override
  String get chats => 'Mensajes';

  @override
  String get profile => 'Perfil';

  @override
  String get newTrip => 'Nuevo viaje';

  @override
  String get destination => 'Destino';

  @override
  String get startDate => 'Fecha de salida';

  @override
  String get endDate => 'Fecha de regreso';

  @override
  String get tripType => 'Tipo de viaje';

  @override
  String get transport => 'Transporte';

  @override
  String get createTrip => 'Crear viaje';

  @override
  String get deleteTrip => 'Eliminar viaje';

  @override
  String get noTrips => 'Sin viajes planificados';

  @override
  String get days => 'días';

  @override
  String get newList => 'Nueva maleta';

  @override
  String get templates => 'Plantillas';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get itemName => 'Nombre del artículo';

  @override
  String get category => 'Categoría';

  @override
  String get quantity => 'Cantidad';

  @override
  String get packed => 'Empaquetado';

  @override
  String get itemPacked => 'Preparado';

  @override
  String get progress => 'completado';

  @override
  String get generateAI => 'Generar con IA';

  @override
  String get messages => 'Mensajes';

  @override
  String get newMessage => 'Nuevo mensaje';

  @override
  String get createGroup => 'Crear grupo';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String get typeMessage => 'Escribe un mensaje...';

  @override
  String get aiAssistant => 'Asistente de viaje';

  @override
  String get support => 'Soporte técnico';

  @override
  String get noConversations => 'Sin conversaciones';

  @override
  String get myProfile => 'Mi perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get help => 'Ayuda y soporte';

  @override
  String get premium => 'Premium';

  @override
  String get goPremium => 'Hazte Premium';

  @override
  String get freePlan => 'Plan Gratuito';

  @override
  String get premiumPlan => 'Plan Premium';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get errorEmptyField => 'Este campo es obligatorio.';

  @override
  String get errorInvalidEmail => 'Email no válido.';

  @override
  String get errorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get errorPasswordMatch => 'Las contraseñas no coinciden.';

  @override
  String get errorGeneral => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String weatherIn(String city) {
    return 'Clima en $city';
  }

  @override
  String tripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
      zero: 'Sin viajes',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Crear';

  @override
  String get newPackingList => 'Nueva maleta';

  @override
  String get deletePackingList => 'Eliminar maleta';

  @override
  String get deleteTripTitle => 'Eliminar viaje';

  @override
  String deleteTripConfirm(String name) {
    return '¿Eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String deleteListConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get inProgress => 'EN CURSO';

  @override
  String get searchCity => 'Consultar ciudad';

  @override
  String get cityHint => 'Ej: Barcelona, París...';

  @override
  String get search => 'Buscar';

  @override
  String get weather => 'Clima';

  @override
  String get weatherSetup => 'Configura OPENWEATHER_API_KEY en .env';

  @override
  String get goPremiumTitle => 'Hazte Premium';

  @override
  String get premiumDesc => 'Listas ilimitadas + IA + sin anuncios';

  @override
  String get logoutTitle => 'Cerrar sesión';

  @override
  String get logoutConfirm => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get listNotFound => 'Lista no encontrada';

  @override
  String get emptyList => 'Lista vacía';

  @override
  String get addItemsHint => 'Añade artículos con el botón +';

  @override
  String get activeSubscription => 'Suscripción activa';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get tryAnotherFilter => 'Prueba con otro filtro o búsqueda';

  @override
  String get noTripsPlanned => 'Sin viajes planificados';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get listNameHint => 'Ej: Maleta verano, Mochila fin de semana...';

  @override
  String get packingList => 'Lista de equipaje';

  @override
  String get packingListsForTrip => 'Listas de equipaje';

  @override
  String get tripPlanning => 'Planifica tu viaje';

  @override
  String get tripPlanningDescription =>
      'Organiza cada día y descubre lugares para visitar';

  @override
  String get itinerary => 'Itinerario';

  @override
  String get itineraryDescription => 'Organiza tu plan día a día';

  @override
  String get discoverDestinations => 'Descubrir destinos';

  @override
  String get discoverDestinationsDescription =>
      'Encuentra lugares para visitar';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get quantityLabel => 'Cantidad:';

  @override
  String itemsCount(int packed, int total) {
    return '$packed/$total artículos';
  }

  @override
  String itemsCountOf(int packed, int total) {
    return '$packed de $total artículos';
  }

  @override
  String progressPercent(int percent) {
    return '$percent% completado';
  }

  @override
  String templatesAvailable(int count) {
    return '$count disponibles';
  }

  @override
  String get noListsYet => 'Sin listas todavía';

  @override
  String get createListHint =>
      'Crea una nueva lista para organizar tu equipaje según el tipo de viaje';

  @override
  String get recentTrips => 'Viajes recientes';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get weatherNotAvailable => 'Clima no disponible';

  @override
  String weatherStaleAge(int minutes) {
    return 'Datos sin actualizar · hace $minutes min';
  }

  @override
  String daysLeft(int days) {
    return 'Faltan $days días';
  }

  @override
  String get luggagePrep => 'Preparación de equipaje';

  @override
  String get noTripsYet => 'Aún no tienes viajes';

  @override
  String get noTripsHint =>
      'Crea tu primer viaje y organiza tu equipaje al instante';

  @override
  String get createTripBtn => 'Crear viaje';

  @override
  String get userDefault => 'Usuario';

  @override
  String get statsTrips => 'Viajes';

  @override
  String get supportChatTitle => 'Soporte técnico';

  @override
  String get assistantChatTitle => 'Asistente de viaje';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get tripActive => 'Viaje activo';

  @override
  String tripUpcoming(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes próximos',
      one: '1 viaje próximo',
      zero: 'Sin viajes próximos',
    );
    return '$_temp0';
  }

  @override
  String get tripReady => '¡Listo para viajar!';

  @override
  String get statsUpcoming => 'Próximos';

  @override
  String get statsActive => 'Activos';

  @override
  String get quickAccess => 'Acceso rápido';

  @override
  String get newBagQuick => 'Nueva maleta';

  @override
  String get newTripQuick => 'Nuevo viaje';

  @override
  String get assistantQuick => 'Asistente';

  @override
  String get todayTrip => 'Hoy';

  @override
  String get dayLeft => 'Falta 1 día';

  @override
  String get welcomeFirstTime => '¡Bienvenido a TravelReady! 🌟';

  @override
  String get subtitleFirstTime =>
      'La primera vez que organizás un viaje de verdad';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get subtitleLogin =>
      'Inicia sesión para seguir planificando tus viajes';

  @override
  String get accountCreatedBanner => 'Cuenta creada correctamente';

  @override
  String get or => 'o';

  @override
  String get accountCreatedSnack =>
      '¡Cuenta creada! Inicia sesión para continuar';

  @override
  String get subtitleRegister =>
      'Crea tu cuenta y empieza a organizar tus viajes';

  @override
  String get hintName => 'Juan Pérez';

  @override
  String get hintEmail => 'email@ejemplo.com';

  @override
  String get hintPassword => '••••••';

  @override
  String get hintConfirmPassword => '••••••';

  @override
  String get resetPasswordTitle => 'Recuperar contraseña';

  @override
  String get forgotPasswordQuestion => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordDesc =>
      'Introduce tu email y te enviaremos un enlace para restablecerla.';

  @override
  String get sendLink => 'Enviar enlace';

  @override
  String get emailSentTitle => '¡Email enviado!';

  @override
  String emailSentDesc(String email) {
    return 'Hemos enviado un enlace de recuperación a\n$email';
  }

  @override
  String get backToLogin => 'Volver al inicio de sesión';

  @override
  String get requiredField => 'Campo obligatorio.';

  @override
  String get emailInvalid => 'Email no válido.';

  @override
  String get myTripsTitle => 'Mis viajes';

  @override
  String get searchTripHint => 'Buscar viaje o destino...';

  @override
  String get tripName => 'Nombre del viaje';

  @override
  String get tripNameHint => 'Ej: París 2026';

  @override
  String get destinationHint => 'Ej: París, Francia';

  @override
  String get departureDate => 'Fecha salida';

  @override
  String get returnDate => 'Fecha regreso';

  @override
  String get tripTypeLabel => 'Tipo de viaje';

  @override
  String get transportLabel => 'Transporte';

  @override
  String get createTripLabel => 'Crear viaje';

  @override
  String daysCount(int count) {
    return '$count días';
  }

  @override
  String get noTripsHintSub =>
      'Crea tu primer viaje y organiza\ntu equipaje al instante';

  @override
  String get messagesTitle => 'Mensajes';

  @override
  String get newChatTitle => 'Nuevo chat';

  @override
  String get noOtherUsers => 'No hay otros usuarios registrados';

  @override
  String get conversationsLabel => 'Conversaciones';

  @override
  String get noPrivateChats =>
      'No tienes chats privados aún\nToca + para iniciar uno';

  @override
  String get noMessages => 'Sin mensajes aún';

  @override
  String errorPrefix(String msg) {
    return 'Error: $msg';
  }

  @override
  String get signInRequired => 'Inicia sesión';

  @override
  String get noMessagesYet => 'Sin mensajes aún';

  @override
  String get essentialsTitle => 'Artículos esenciales';

  @override
  String get essentialsSubtitle =>
      'Cosas que nunca deben faltar en ningún viaje';

  @override
  String get useTemplate => 'Usar esta plantilla';

  @override
  String addEssentials(int count) {
    return 'Añadir $count esenciales';
  }

  @override
  String essentialsAdded(int count, String name) {
    return '$count esenciales añadidos a \"$name\"';
  }

  @override
  String creatingTemplate(String name) {
    return 'Creando \"$name\"... ✓';
  }

  @override
  String get creatingEssentialsList => 'Creando lista de esenciales...';

  @override
  String get retryLabel => 'Reintentar';

  @override
  String templateItemsCount(int count) {
    return '$count artículos incluidos';
  }

  @override
  String get aiWelcome =>
      '¡Hola! 👋 Soy tu asistente de viaje.\n\nPuedo ayudarte con:\n• 🧳 Qué llevar según tu destino\n• 🌡️ Ropa según el clima\n• ✈️ Consejos para volar\n• 📋 Plantillas de equipaje\n\n¿Adónde vas? ¿Qué necesitas?';

  @override
  String get aiReplyBeach =>
      '☀️ **Playa / Verano:**\n\n👙 Bañador ×2 · ☀️ Crema FPS50+\n🕶️ Gafas UV · 👡 Chanclas · 🏖️ Toalla microfibra\n💧 Botella reutilizable · 👒 Sombrero\n\n💡 Líquidos en bolsa 100ml si vuelas.';

  @override
  String get aiReplyMountain =>
      '⛰️ **Montaña:**\n\n🥾 Botas impermeables · 🧥 Chubasquero\n🧣 Bufanda+gorro+guantes · 🧱 Ropa térmica\n🎒 Mochila 20-30L · 💊 Botiquín · 🔦 Linterna';

  @override
  String get aiReplyCity =>
      '🏙️ **City Break:**\n\n👟 Zapatillas cómodas · 🎒 Mochila antirrobo\n📱 Cargador+power bank · 💳 Tarjeta sin comisiones\n☔ Paraguas compacto · 📄 Copia digitalizada DNI/Pasaporte';

  @override
  String get aiReplyBusiness =>
      '💼 **Negocios:**\n\n👔 Ropa formal ×extra · 💻 Portátil+cargador\n🔌 Adaptador enchufes · 🎧 Auriculares ANC\n🖊️ Tarjetas de visita';

  @override
  String get aiReplyFlight =>
      '✈️ **Para volar:**\n\n💧 Líquidos: máx 100ml en bolsa ZIP 1L\n⚖️ Pesa la maleta antes (evita cargos)\n😴 Almohada de viaje + antifaz\n🥤 Botella vacía para llenar tras seguridad\n\n💡 Llega 2h antes (3h en vuelos internacionales).';

  @override
  String get aiReplyMedicine =>
      '💊 **Botiquín de viaje:**\n\n🤕 Ibuprofeno/paracetamol · 🤢 Antinauseas\n🩹 Tiritas · 🧴 Desinfectante · 💊 Antihistamínico\n💉 Medicación habitual (en equipaje de mano)\n\n⚠️ Receta médica para medicación controlada.';

  @override
  String get aiReplyDocuments =>
      '📄 **Documentos:**\n\n🛂 Pasaporte (vigencia mín. 6 meses)\n🪪 DNI para Europa · 🏥 Tarjeta sanitaria UE\n🏦 2 tarjetas bancarias · 📋 Seguro de viaje\n\n💡 Copia digital en Google Drive.';

  @override
  String get aiReplyDays =>
      '🗓️ **Ropa por días:**\n\n📅 1-3 días → mochila cabina\n📅 4-7 días → maleta mediana\n📅 +7 días → reutiliza y lava\n\n👕 1 camiseta/día+1 extra · 👖 1 pantalón/3 días\n🧦 1 par/día+1 extra';

  @override
  String get aiReplyHello =>
      '¡Hola! 😊 ¿A dónde vas a viajar?\nDime el destino y te ayudo a preparar tu equipaje.';

  @override
  String get aiReplyThanks => '¡De nada! 😊 ¡Buen viaje! ✈️🌍';

  @override
  String get aiReplyFallback =>
      '🤔 Puedo ayudarte con:\n\n• Destino (playa, montaña, ciudad, negocios)\n• Consejos para volar · Botiquín\n• Documentos · Cuánta ropa llevar\n\nSolo dime tu destino 🌍';

  @override
  String get supportHowCanWeHelp => '¿Cómo podemos ayudarte?';

  @override
  String get supportAvailability =>
      'Estamos disponibles de Lunes a Viernes\nde 9:00 a 18:00 (CET)';

  @override
  String get supportEmailTitle => 'Email';

  @override
  String get supportEmailSubtitle => 'soporte@travelready.app';

  @override
  String get supportHelpCenter => 'Centro de ayuda';

  @override
  String get supportHelpCenterSubtitle => 'Preguntas frecuentes y guías';

  @override
  String get supportReportProblem => 'Reportar un problema';

  @override
  String get supportReportProblemSubtitle => 'Cuéntanos qué ha fallado';

  @override
  String get tripFilterAll => '🗓 Todos';

  @override
  String get tripFilterUpcoming => '✈️ Próximos';

  @override
  String get tripFilterActive => '🟢 En curso';

  @override
  String get tripFilterPast => '📁 Pasados';

  @override
  String get catClothing => 'Ropa';

  @override
  String get catElectronics => 'Electrónica';

  @override
  String get catDocuments => 'Documentos';

  @override
  String get catHygiene => 'Higiene';

  @override
  String get catMedicine => 'Medicamentos';

  @override
  String get catFood => 'Alimentación';

  @override
  String get catAccessories => 'Accesorios';

  @override
  String get catSports => 'Deporte';

  @override
  String get catOther => 'Otros';

  @override
  String get essentialPassport => 'DNI / Pasaporte';

  @override
  String get essentialBankCard => 'Tarjeta bancaria';

  @override
  String get essentialTravelInsurance => 'Seguro de viaje';

  @override
  String get essentialPrintedReservations => 'Reservas impresas';

  @override
  String get essentialToiletryBag => 'Neceser';

  @override
  String get essentialToothbrush => 'Cepillo y pasta dientes';

  @override
  String get essentialDeodorant => 'Desodorante';

  @override
  String get essentialPhoneCharger => 'Cargador móvil';

  @override
  String get essentialRegularMedication => 'Medicación habitual';

  @override
  String get essentialUnderwear => 'Ropa interior';

  @override
  String get essentialExtraSocks => 'Calcetines extra';

  @override
  String get essentialHeadphones => 'Auriculares';

  @override
  String get essentialWaterBottle => 'Botella de agua';

  @override
  String get essentialTravelSnacks => 'Snacks para el viaje';

  @override
  String get templateBeach => 'Playa / Verano';

  @override
  String get templateMountain => 'Montaña / Senderismo';

  @override
  String get templateCity => 'City Break';

  @override
  String get templateBusiness => 'Negocios';

  @override
  String get templateWeekend => 'Fin de semana';

  @override
  String get templateLongFlight => 'Vuelo largo';

  @override
  String get itemSwimsuit => 'Bañador';

  @override
  String get itemSunscreen => 'Crema solar FPS 50';

  @override
  String get itemSunglasses => 'Gafas de sol';

  @override
  String get itemFlipFlops => 'Chanclas';

  @override
  String get itemBeachTowel => 'Toalla de playa';

  @override
  String get itemHat => 'Sombrero / Gorra';

  @override
  String get itemHikingBoots => 'Botas de montaña';

  @override
  String get itemRainJacket => 'Chubasquero';

  @override
  String get itemThermalClothing => 'Ropa térmica';

  @override
  String get itemBackpack20to30L => 'Mochila 20-30L';

  @override
  String get itemTrekkingPoles => 'Bastones';

  @override
  String get itemHeadlamp => 'Linterna frontal';

  @override
  String get itemFirstAidKit => 'Botiquín básico';

  @override
  String get itemComfortableSneakers => 'Zapatillas cómodas';

  @override
  String get itemUrbanBackpack => 'Mochila urbana';

  @override
  String get itemPowerBank => 'Power bank';

  @override
  String get itemCompactUmbrella => 'Paraguas compacto';

  @override
  String get itemTravelGuide => 'Guía de viaje';

  @override
  String get itemLaptopCharger => 'Portátil + cargador';

  @override
  String get itemFormalWear => 'Traje / Ropa formal';

  @override
  String get itemBusinessCards => 'Tarjetas de visita';

  @override
  String get itemPlugAdapter => 'Adaptador enchufes';

  @override
  String get itemAncHeadphones => 'Auriculares ANC';

  @override
  String get itemClothes2to3Days => 'Ropa 2-3 días';

  @override
  String get itemBasicToiletryBag => 'Neceser básico';

  @override
  String get itemTravelPillow => 'Almohada de viaje';

  @override
  String get itemSleepMask => 'Antifaz';

  @override
  String get itemEarplugs => 'Tapones para oídos';

  @override
  String get itemLiquidsBag100ml => 'Bolsa líquidos 100ml';

  @override
  String get itemWarmClothing => 'Ropa de abrigo';

  @override
  String itineraryTitleWithTrip(String trip) {
    return 'Itinerario · $trip';
  }

  @override
  String get itineraryEmptyTitle => 'Aún no hay planes';

  @override
  String get itineraryEmptyBody =>
      'Añade tu primera visita, comida o actividad con día y hora.';

  @override
  String get itineraryAddPlan => 'Añadir plan';

  @override
  String get itineraryDeletePlan => 'Eliminar plan';

  @override
  String get itineraryNewPlan => 'Nuevo plan';

  @override
  String get itineraryEditPlan => 'Editar plan';

  @override
  String get itineraryFieldTitle => 'Título';

  @override
  String get itineraryFieldTitleHint => 'Museo, restaurante, actividad…';

  @override
  String get itineraryFieldNotes => 'Notas';

  @override
  String get itineraryFieldNotesHint => 'Opcional';

  @override
  String itineraryStartAt(String time) {
    return 'Inicio · $time';
  }

  @override
  String get itineraryEndOptional => 'Fin · opcional';

  @override
  String get itineraryAdd => 'Añadir';

  @override
  String get itineraryCategorySightseeing => 'Visita';

  @override
  String get itineraryCategoryFood => 'Comida';

  @override
  String get itineraryCategoryLodging => 'Alojamiento';

  @override
  String get itineraryCategoryActivity => 'Actividad';

  @override
  String get itineraryCategoryOther => 'Otro';

  @override
  String get discoveryTitle => 'Descubrir';

  @override
  String get discoverySearchHint => 'Buscar lugares, museos, restaurantes…';

  @override
  String get discoveryAllCategories => 'Todo';

  @override
  String get discoveryDemoData =>
      'Datos de ejemplo — sin proveedor configurado';

  @override
  String get discoveryProviderUnavailableTitle => 'Proveedor no disponible';

  @override
  String get discoveryProviderUnavailableBody =>
      'La búsqueda de lugares requiere configurar un proveedor (Maps/Places). Mientras tanto puedes añadir planes manualmente al itinerario.';

  @override
  String get discoverySearchErrorTitle => 'Error al buscar';

  @override
  String get discoveryNoResultsTitle => 'Sin resultados';

  @override
  String get discoveryExploreTitle => 'Explora tu destino';

  @override
  String get discoveryNoResultsBody => 'Prueba con otra búsqueda o categoría.';

  @override
  String get discoveryExploreBody =>
      'Busca museos, restaurantes o rincones del destino.';

  @override
  String discoveryHoursIndicative(String hours) {
    return 'Horario (indicativo): $hours';
  }

  @override
  String discoveryPriceIndicative(String price) {
    return 'Precio orientativo: $price';
  }

  @override
  String get discoveryOfficialSite => 'Sitio web oficial';

  @override
  String get discoveryAddToItinerary => 'Añadir al itinerario';

  @override
  String get discoveryAddedToItinerary => 'Añadido al itinerario';

  @override
  String discoveryAddPlaceWithName(String name) {
    return 'Añadir \"$name\"';
  }

  @override
  String get discoveryDayLabel => 'Día';

  @override
  String get placeCategoryMonument => 'Monumentos';

  @override
  String get placeCategoryMuseum => 'Museos';

  @override
  String get placeCategoryFood => 'Comida';

  @override
  String get placeCategoryNature => 'Naturaleza';

  @override
  String get placeCategoryNightlife => 'Ocio nocturno';

  @override
  String get placeCategoryShopping => 'Compras';

  @override
  String get placeCategoryHotel => 'Hoteles';

  @override
  String itineraryEndAt(String time) {
    return 'Fin · $time';
  }

  @override
  String discoveryTimeLabel(String time) {
    return 'Hora · $time';
  }

  @override
  String get saving => 'Guardando…';

  @override
  String get feedDislikeAction => 'No me interesa';

  @override
  String get feedLikeAction => 'Me gusta';

  @override
  String get feedSwipeHint =>
      'Desliza a la derecha para guardar o a la izquierda para descartar';
}
