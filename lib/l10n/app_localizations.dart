import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'TravelReady!'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get name;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signInGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get signInGoogle;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get hasAccount;

  /// No description provided for @resetPassword.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get resetPassword;

  /// No description provided for @sendResetEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar email de recuperación'**
  String get sendResetEmail;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @myTrips.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get myTrips;

  /// No description provided for @packingLists.
  ///
  /// In es, this message translates to:
  /// **'Mis maletas'**
  String get packingLists;

  /// No description provided for @chats.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get chats;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @newTrip.
  ///
  /// In es, this message translates to:
  /// **'Nuevo viaje'**
  String get newTrip;

  /// No description provided for @destination.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get destination;

  /// No description provided for @startDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de salida'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de regreso'**
  String get endDate;

  /// No description provided for @tripType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de viaje'**
  String get tripType;

  /// No description provided for @transport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get transport;

  /// No description provided for @createTrip.
  ///
  /// In es, this message translates to:
  /// **'Crear viaje'**
  String get createTrip;

  /// No description provided for @deleteTrip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar viaje'**
  String get deleteTrip;

  /// No description provided for @noTrips.
  ///
  /// In es, this message translates to:
  /// **'Sin viajes planificados'**
  String get noTrips;

  /// No description provided for @days.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get days;

  /// No description provided for @newList.
  ///
  /// In es, this message translates to:
  /// **'Nueva maleta'**
  String get newList;

  /// No description provided for @templates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas'**
  String get templates;

  /// No description provided for @addItem.
  ///
  /// In es, this message translates to:
  /// **'Añadir artículo'**
  String get addItem;

  /// No description provided for @itemName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del artículo'**
  String get itemName;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// No description provided for @packed.
  ///
  /// In es, this message translates to:
  /// **'Empaquetado'**
  String get packed;

  /// No description provided for @itemPacked.
  ///
  /// In es, this message translates to:
  /// **'Preparado'**
  String get itemPacked;

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'completado'**
  String get progress;

  /// No description provided for @generateAI.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get generateAI;

  /// No description provided for @messages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get messages;

  /// No description provided for @newMessage.
  ///
  /// In es, this message translates to:
  /// **'Nuevo mensaje'**
  String get newMessage;

  /// No description provided for @createGroup.
  ///
  /// In es, this message translates to:
  /// **'Crear grupo'**
  String get createGroup;

  /// No description provided for @groupName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del grupo'**
  String get groupName;

  /// No description provided for @typeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get typeMessage;

  /// No description provided for @aiAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente de viaje'**
  String get aiAssistant;

  /// No description provided for @support.
  ///
  /// In es, this message translates to:
  /// **'Soporte técnico'**
  String get support;

  /// No description provided for @noConversations.
  ///
  /// In es, this message translates to:
  /// **'Sin conversaciones'**
  String get noConversations;

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo claro'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get english;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @help.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get help;

  /// No description provided for @premium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @goPremium.
  ///
  /// In es, this message translates to:
  /// **'Hazte Premium'**
  String get goPremium;

  /// No description provided for @freePlan.
  ///
  /// In es, this message translates to:
  /// **'Plan Gratuito'**
  String get freePlan;

  /// No description provided for @premiumPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan Premium'**
  String get premiumPlan;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @errorEmptyField.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get errorEmptyField;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email no válido.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get errorWeakPassword;

  /// No description provided for @errorPasswordMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get errorPasswordMatch;

  /// No description provided for @errorGeneral.
  ///
  /// In es, this message translates to:
  /// **'Algo ha ido mal. Inténtalo de nuevo.'**
  String get errorGeneral;

  /// No description provided for @weatherIn.
  ///
  /// In es, this message translates to:
  /// **'Clima en {city}'**
  String weatherIn(String city);

  /// No description provided for @tripsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin viajes} =1{1 viaje} other{{count} viajes}}'**
  String tripsCount(int count);

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @newPackingList.
  ///
  /// In es, this message translates to:
  /// **'Nueva maleta'**
  String get newPackingList;

  /// No description provided for @deletePackingList.
  ///
  /// In es, this message translates to:
  /// **'Eliminar maleta'**
  String get deletePackingList;

  /// No description provided for @deleteTripTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar viaje'**
  String get deleteTripTitle;

  /// No description provided for @deleteTripConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"? Esta acción no se puede deshacer.'**
  String deleteTripConfirm(String name);

  /// No description provided for @deleteListConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"?'**
  String deleteListConfirm(String name);

  /// No description provided for @clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get clearFilters;

  /// No description provided for @inProgress.
  ///
  /// In es, this message translates to:
  /// **'EN CURSO'**
  String get inProgress;

  /// No description provided for @searchCity.
  ///
  /// In es, this message translates to:
  /// **'Consultar ciudad'**
  String get searchCity;

  /// No description provided for @cityHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Barcelona, París...'**
  String get cityHint;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @weather.
  ///
  /// In es, this message translates to:
  /// **'Clima'**
  String get weather;

  /// No description provided for @weatherSetup.
  ///
  /// In es, this message translates to:
  /// **'Configura OPENWEATHER_API_KEY en .env'**
  String get weatherSetup;

  /// No description provided for @goPremiumTitle.
  ///
  /// In es, this message translates to:
  /// **'Hazte Premium'**
  String get goPremiumTitle;

  /// No description provided for @premiumDesc.
  ///
  /// In es, this message translates to:
  /// **'Listas ilimitadas + IA + sin anuncios'**
  String get premiumDesc;

  /// No description provided for @logoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cerrar sesión?'**
  String get logoutConfirm;

  /// No description provided for @listNotFound.
  ///
  /// In es, this message translates to:
  /// **'Lista no encontrada'**
  String get listNotFound;

  /// No description provided for @emptyList.
  ///
  /// In es, this message translates to:
  /// **'Lista vacía'**
  String get emptyList;

  /// No description provided for @addItemsHint.
  ///
  /// In es, this message translates to:
  /// **'Añade artículos con el botón +'**
  String get addItemsHint;

  /// No description provided for @activeSubscription.
  ///
  /// In es, this message translates to:
  /// **'Suscripción activa'**
  String get activeSubscription;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @tryAnotherFilter.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro filtro o búsqueda'**
  String get tryAnotherFilter;

  /// No description provided for @noTripsPlanned.
  ///
  /// In es, this message translates to:
  /// **'Sin viajes planificados'**
  String get noTripsPlanned;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameLabel;

  /// No description provided for @listNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Maleta verano, Mochila fin de semana...'**
  String get listNameHint;

  /// No description provided for @packingList.
  ///
  /// In es, this message translates to:
  /// **'Lista de equipaje'**
  String get packingList;

  /// No description provided for @packingListsForTrip.
  ///
  /// In es, this message translates to:
  /// **'Listas de equipaje'**
  String get packingListsForTrip;

  /// No description provided for @categoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoryLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad:'**
  String get quantityLabel;

  /// No description provided for @itemsCount.
  ///
  /// In es, this message translates to:
  /// **'{packed}/{total} artículos'**
  String itemsCount(int packed, int total);

  /// No description provided for @itemsCountOf.
  ///
  /// In es, this message translates to:
  /// **'{packed} de {total} artículos'**
  String itemsCountOf(int packed, int total);

  /// No description provided for @progressPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent}% completado'**
  String progressPercent(int percent);

  /// No description provided for @templatesAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count} disponibles'**
  String templatesAvailable(int count);

  /// No description provided for @noListsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin listas todavía'**
  String get noListsYet;

  /// No description provided for @createListHint.
  ///
  /// In es, this message translates to:
  /// **'Crea una nueva lista para organizar tu equipaje según el tipo de viaje'**
  String get createListHint;

  /// No description provided for @recentTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes recientes'**
  String get recentTrips;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get seeAll;

  /// No description provided for @weatherNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Clima no disponible'**
  String get weatherNotAvailable;

  /// No description provided for @daysLeft.
  ///
  /// In es, this message translates to:
  /// **'Faltan {days} días'**
  String daysLeft(int days);

  /// No description provided for @luggagePrep.
  ///
  /// In es, this message translates to:
  /// **'Preparación de equipaje'**
  String get luggagePrep;

  /// No description provided for @noTripsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes viajes'**
  String get noTripsYet;

  /// No description provided for @noTripsHint.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer viaje y organiza tu equipaje al instante'**
  String get noTripsHint;

  /// No description provided for @createTripBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear viaje'**
  String get createTripBtn;

  /// No description provided for @userDefault.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get userDefault;

  /// No description provided for @statsTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get statsTrips;

  /// No description provided for @supportChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Soporte técnico'**
  String get supportChatTitle;

  /// No description provided for @assistantChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente de viaje'**
  String get assistantChatTitle;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoon;

  /// No description provided for @greetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get greetingEvening;

  /// No description provided for @tripActive.
  ///
  /// In es, this message translates to:
  /// **'Viaje activo'**
  String get tripActive;

  /// No description provided for @tripUpcoming.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin viajes próximos} =1{1 viaje próximo} other{{count} viajes próximos}}'**
  String tripUpcoming(int count);

  /// No description provided for @tripReady.
  ///
  /// In es, this message translates to:
  /// **'¡Listo para viajar!'**
  String get tripReady;

  /// No description provided for @statsUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get statsUpcoming;

  /// No description provided for @statsActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get statsActive;

  /// No description provided for @quickAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido'**
  String get quickAccess;

  /// No description provided for @newBagQuick.
  ///
  /// In es, this message translates to:
  /// **'Nueva maleta'**
  String get newBagQuick;

  /// No description provided for @newTripQuick.
  ///
  /// In es, this message translates to:
  /// **'Nuevo viaje'**
  String get newTripQuick;

  /// No description provided for @assistantQuick.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get assistantQuick;

  /// No description provided for @todayTrip.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayTrip;

  /// No description provided for @dayLeft.
  ///
  /// In es, this message translates to:
  /// **'Falta 1 día'**
  String get dayLeft;

  /// No description provided for @welcomeFirstTime.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a TravelReady! 🌟'**
  String get welcomeFirstTime;

  /// No description provided for @subtitleFirstTime.
  ///
  /// In es, this message translates to:
  /// **'La primera vez que organizás un viaje de verdad'**
  String get subtitleFirstTime;

  /// No description provided for @welcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get welcomeBack;

  /// No description provided for @subtitleLogin.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para seguir planificando tus viajes'**
  String get subtitleLogin;

  /// No description provided for @accountCreatedBanner.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada correctamente'**
  String get accountCreatedBanner;

  /// No description provided for @or.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get or;

  /// No description provided for @accountCreatedSnack.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta creada! Inicia sesión para continuar'**
  String get accountCreatedSnack;

  /// No description provided for @subtitleRegister.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta y empieza a organizar tus viajes'**
  String get subtitleRegister;

  /// No description provided for @hintName.
  ///
  /// In es, this message translates to:
  /// **'Juan Pérez'**
  String get hintName;

  /// No description provided for @hintEmail.
  ///
  /// In es, this message translates to:
  /// **'email@ejemplo.com'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In es, this message translates to:
  /// **'••••••'**
  String get hintPassword;

  /// No description provided for @hintConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'••••••'**
  String get hintConfirmPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get resetPasswordTitle;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordQuestion;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email y te enviaremos un enlace para restablecerla.'**
  String get forgotPasswordDesc;

  /// No description provided for @sendLink.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get sendLink;

  /// No description provided for @emailSentTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Email enviado!'**
  String get emailSentTitle;

  /// No description provided for @emailSentDesc.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un enlace de recuperación a\n{email}'**
  String emailSentDesc(String email);

  /// No description provided for @backToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio de sesión'**
  String get backToLogin;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio.'**
  String get requiredField;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Email no válido.'**
  String get emailInvalid;

  /// No description provided for @myTripsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get myTripsTitle;

  /// No description provided for @searchTripHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar viaje o destino...'**
  String get searchTripHint;

  /// No description provided for @tripName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del viaje'**
  String get tripName;

  /// No description provided for @tripNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: París 2026'**
  String get tripNameHint;

  /// No description provided for @destinationHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: París, Francia'**
  String get destinationHint;

  /// No description provided for @departureDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha salida'**
  String get departureDate;

  /// No description provided for @returnDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha regreso'**
  String get returnDate;

  /// No description provided for @tripTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de viaje'**
  String get tripTypeLabel;

  /// No description provided for @transportLabel.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get transportLabel;

  /// No description provided for @createTripLabel.
  ///
  /// In es, this message translates to:
  /// **'Crear viaje'**
  String get createTripLabel;

  /// No description provided for @daysCount.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String daysCount(int count);

  /// No description provided for @noTripsHintSub.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer viaje y organiza\ntu equipaje al instante'**
  String get noTripsHintSub;

  /// No description provided for @messagesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get messagesTitle;

  /// No description provided for @newChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo chat'**
  String get newChatTitle;

  /// No description provided for @noOtherUsers.
  ///
  /// In es, this message translates to:
  /// **'No hay otros usuarios registrados'**
  String get noOtherUsers;

  /// No description provided for @conversationsLabel.
  ///
  /// In es, this message translates to:
  /// **'Conversaciones'**
  String get conversationsLabel;

  /// No description provided for @noPrivateChats.
  ///
  /// In es, this message translates to:
  /// **'No tienes chats privados aún\nToca + para iniciar uno'**
  String get noPrivateChats;

  /// No description provided for @noMessages.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes aún'**
  String get noMessages;

  /// No description provided for @errorPrefix.
  ///
  /// In es, this message translates to:
  /// **'Error: {msg}'**
  String errorPrefix(String msg);

  /// No description provided for @signInRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get signInRequired;

  /// No description provided for @noMessagesYet.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes aún'**
  String get noMessagesYet;

  /// No description provided for @essentialsTitle.
  ///
  /// In es, this message translates to:
  /// **'Artículos esenciales'**
  String get essentialsTitle;

  /// No description provided for @essentialsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cosas que nunca deben faltar en ningún viaje'**
  String get essentialsSubtitle;

  /// No description provided for @useTemplate.
  ///
  /// In es, this message translates to:
  /// **'Usar esta plantilla'**
  String get useTemplate;

  /// No description provided for @addEssentials.
  ///
  /// In es, this message translates to:
  /// **'Añadir {count} esenciales'**
  String addEssentials(int count);

  /// No description provided for @essentialsAdded.
  ///
  /// In es, this message translates to:
  /// **'{count} esenciales añadidos a \"{name}\"'**
  String essentialsAdded(int count, String name);

  /// No description provided for @creatingTemplate.
  ///
  /// In es, this message translates to:
  /// **'Creando \"{name}\"... ✓'**
  String creatingTemplate(String name);

  /// No description provided for @creatingEssentialsList.
  ///
  /// In es, this message translates to:
  /// **'Creando lista de esenciales...'**
  String get creatingEssentialsList;

  /// No description provided for @retryLabel.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retryLabel;

  /// No description provided for @templateItemsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} artículos incluidos'**
  String templateItemsCount(int count);

  /// No description provided for @aiWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! 👋 Soy tu asistente de viaje.\n\nPuedo ayudarte con:\n• 🧳 Qué llevar según tu destino\n• 🌡️ Ropa según el clima\n• ✈️ Consejos para volar\n• 📋 Plantillas de equipaje\n\n¿Adónde vas? ¿Qué necesitas?'**
  String get aiWelcome;

  /// No description provided for @aiReplyBeach.
  ///
  /// In es, this message translates to:
  /// **'☀️ **Playa / Verano:**\n\n👙 Bañador ×2 · ☀️ Crema FPS50+\n🕶️ Gafas UV · 👡 Chanclas · 🏖️ Toalla microfibra\n💧 Botella reutilizable · 👒 Sombrero\n\n💡 Líquidos en bolsa 100ml si vuelas.'**
  String get aiReplyBeach;

  /// No description provided for @aiReplyMountain.
  ///
  /// In es, this message translates to:
  /// **'⛰️ **Montaña:**\n\n🥾 Botas impermeables · 🧥 Chubasquero\n🧣 Bufanda+gorro+guantes · 🧱 Ropa térmica\n🎒 Mochila 20-30L · 💊 Botiquín · 🔦 Linterna'**
  String get aiReplyMountain;

  /// No description provided for @aiReplyCity.
  ///
  /// In es, this message translates to:
  /// **'🏙️ **City Break:**\n\n👟 Zapatillas cómodas · 🎒 Mochila antirrobo\n📱 Cargador+power bank · 💳 Tarjeta sin comisiones\n☔ Paraguas compacto · 📄 Copia digitalizada DNI/Pasaporte'**
  String get aiReplyCity;

  /// No description provided for @aiReplyBusiness.
  ///
  /// In es, this message translates to:
  /// **'💼 **Negocios:**\n\n👔 Ropa formal ×extra · 💻 Portátil+cargador\n🔌 Adaptador enchufes · 🎧 Auriculares ANC\n🖊️ Tarjetas de visita'**
  String get aiReplyBusiness;

  /// No description provided for @aiReplyFlight.
  ///
  /// In es, this message translates to:
  /// **'✈️ **Para volar:**\n\n💧 Líquidos: máx 100ml en bolsa ZIP 1L\n⚖️ Pesa la maleta antes (evita cargos)\n😴 Almohada de viaje + antifaz\n🥤 Botella vacía para llenar tras seguridad\n\n💡 Llega 2h antes (3h en vuelos internacionales).'**
  String get aiReplyFlight;

  /// No description provided for @aiReplyMedicine.
  ///
  /// In es, this message translates to:
  /// **'💊 **Botiquín de viaje:**\n\n🤕 Ibuprofeno/paracetamol · 🤢 Antinauseas\n🩹 Tiritas · 🧴 Desinfectante · 💊 Antihistamínico\n💉 Medicación habitual (en equipaje de mano)\n\n⚠️ Receta médica para medicación controlada.'**
  String get aiReplyMedicine;

  /// No description provided for @aiReplyDocuments.
  ///
  /// In es, this message translates to:
  /// **'📄 **Documentos:**\n\n🛂 Pasaporte (vigencia mín. 6 meses)\n🪪 DNI para Europa · 🏥 Tarjeta sanitaria UE\n🏦 2 tarjetas bancarias · 📋 Seguro de viaje\n\n💡 Copia digital en Google Drive.'**
  String get aiReplyDocuments;

  /// No description provided for @aiReplyDays.
  ///
  /// In es, this message translates to:
  /// **'🗓️ **Ropa por días:**\n\n📅 1-3 días → mochila cabina\n📅 4-7 días → maleta mediana\n📅 +7 días → reutiliza y lava\n\n👕 1 camiseta/día+1 extra · 👖 1 pantalón/3 días\n🧦 1 par/día+1 extra'**
  String get aiReplyDays;

  /// No description provided for @aiReplyHello.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! 😊 ¿A dónde vas a viajar?\nDime el destino y te ayudo a preparar tu equipaje.'**
  String get aiReplyHello;

  /// No description provided for @aiReplyThanks.
  ///
  /// In es, this message translates to:
  /// **'¡De nada! 😊 ¡Buen viaje! ✈️🌍'**
  String get aiReplyThanks;

  /// No description provided for @aiReplyFallback.
  ///
  /// In es, this message translates to:
  /// **'🤔 Puedo ayudarte con:\n\n• Destino (playa, montaña, ciudad, negocios)\n• Consejos para volar · Botiquín\n• Documentos · Cuánta ropa llevar\n\nSolo dime tu destino 🌍'**
  String get aiReplyFallback;

  /// No description provided for @supportHowCanWeHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo podemos ayudarte?'**
  String get supportHowCanWeHelp;

  /// No description provided for @supportAvailability.
  ///
  /// In es, this message translates to:
  /// **'Estamos disponibles de Lunes a Viernes\nde 9:00 a 18:00 (CET)'**
  String get supportAvailability;

  /// No description provided for @supportEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get supportEmailTitle;

  /// No description provided for @supportEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'soporte@travelready.app'**
  String get supportEmailSubtitle;

  /// No description provided for @supportHelpCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de ayuda'**
  String get supportHelpCenter;

  /// No description provided for @supportHelpCenterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes y guías'**
  String get supportHelpCenterSubtitle;

  /// No description provided for @supportReportProblem.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get supportReportProblem;

  /// No description provided for @supportReportProblemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué ha fallado'**
  String get supportReportProblemSubtitle;

  /// No description provided for @tripFilterAll.
  ///
  /// In es, this message translates to:
  /// **'🗓 Todos'**
  String get tripFilterAll;

  /// No description provided for @tripFilterUpcoming.
  ///
  /// In es, this message translates to:
  /// **'✈️ Próximos'**
  String get tripFilterUpcoming;

  /// No description provided for @tripFilterActive.
  ///
  /// In es, this message translates to:
  /// **'🟢 En curso'**
  String get tripFilterActive;

  /// No description provided for @tripFilterPast.
  ///
  /// In es, this message translates to:
  /// **'📁 Pasados'**
  String get tripFilterPast;

  /// No description provided for @catClothing.
  ///
  /// In es, this message translates to:
  /// **'Ropa'**
  String get catClothing;

  /// No description provided for @catElectronics.
  ///
  /// In es, this message translates to:
  /// **'Electrónica'**
  String get catElectronics;

  /// No description provided for @catDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get catDocuments;

  /// No description provided for @catHygiene.
  ///
  /// In es, this message translates to:
  /// **'Higiene'**
  String get catHygiene;

  /// No description provided for @catMedicine.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get catMedicine;

  /// No description provided for @catFood.
  ///
  /// In es, this message translates to:
  /// **'Alimentación'**
  String get catFood;

  /// No description provided for @catAccessories.
  ///
  /// In es, this message translates to:
  /// **'Accesorios'**
  String get catAccessories;

  /// No description provided for @catSports.
  ///
  /// In es, this message translates to:
  /// **'Deporte'**
  String get catSports;

  /// No description provided for @catOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get catOther;

  /// No description provided for @essentialPassport.
  ///
  /// In es, this message translates to:
  /// **'DNI / Pasaporte'**
  String get essentialPassport;

  /// No description provided for @essentialBankCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta bancaria'**
  String get essentialBankCard;

  /// No description provided for @essentialTravelInsurance.
  ///
  /// In es, this message translates to:
  /// **'Seguro de viaje'**
  String get essentialTravelInsurance;

  /// No description provided for @essentialPrintedReservations.
  ///
  /// In es, this message translates to:
  /// **'Reservas impresas'**
  String get essentialPrintedReservations;

  /// No description provided for @essentialToiletryBag.
  ///
  /// In es, this message translates to:
  /// **'Neceser'**
  String get essentialToiletryBag;

  /// No description provided for @essentialToothbrush.
  ///
  /// In es, this message translates to:
  /// **'Cepillo y pasta dientes'**
  String get essentialToothbrush;

  /// No description provided for @essentialDeodorant.
  ///
  /// In es, this message translates to:
  /// **'Desodorante'**
  String get essentialDeodorant;

  /// No description provided for @essentialPhoneCharger.
  ///
  /// In es, this message translates to:
  /// **'Cargador móvil'**
  String get essentialPhoneCharger;

  /// No description provided for @essentialRegularMedication.
  ///
  /// In es, this message translates to:
  /// **'Medicación habitual'**
  String get essentialRegularMedication;

  /// No description provided for @essentialUnderwear.
  ///
  /// In es, this message translates to:
  /// **'Ropa interior'**
  String get essentialUnderwear;

  /// No description provided for @essentialExtraSocks.
  ///
  /// In es, this message translates to:
  /// **'Calcetines extra'**
  String get essentialExtraSocks;

  /// No description provided for @essentialHeadphones.
  ///
  /// In es, this message translates to:
  /// **'Auriculares'**
  String get essentialHeadphones;

  /// No description provided for @essentialWaterBottle.
  ///
  /// In es, this message translates to:
  /// **'Botella de agua'**
  String get essentialWaterBottle;

  /// No description provided for @essentialTravelSnacks.
  ///
  /// In es, this message translates to:
  /// **'Snacks para el viaje'**
  String get essentialTravelSnacks;

  /// No description provided for @templateBeach.
  ///
  /// In es, this message translates to:
  /// **'Playa / Verano'**
  String get templateBeach;

  /// No description provided for @templateMountain.
  ///
  /// In es, this message translates to:
  /// **'Montaña / Senderismo'**
  String get templateMountain;

  /// No description provided for @templateCity.
  ///
  /// In es, this message translates to:
  /// **'City Break'**
  String get templateCity;

  /// No description provided for @templateBusiness.
  ///
  /// In es, this message translates to:
  /// **'Negocios'**
  String get templateBusiness;

  /// No description provided for @templateWeekend.
  ///
  /// In es, this message translates to:
  /// **'Fin de semana'**
  String get templateWeekend;

  /// No description provided for @templateLongFlight.
  ///
  /// In es, this message translates to:
  /// **'Vuelo largo'**
  String get templateLongFlight;

  /// No description provided for @itemSwimsuit.
  ///
  /// In es, this message translates to:
  /// **'Bañador'**
  String get itemSwimsuit;

  /// No description provided for @itemSunscreen.
  ///
  /// In es, this message translates to:
  /// **'Crema solar FPS 50'**
  String get itemSunscreen;

  /// No description provided for @itemSunglasses.
  ///
  /// In es, this message translates to:
  /// **'Gafas de sol'**
  String get itemSunglasses;

  /// No description provided for @itemFlipFlops.
  ///
  /// In es, this message translates to:
  /// **'Chanclas'**
  String get itemFlipFlops;

  /// No description provided for @itemBeachTowel.
  ///
  /// In es, this message translates to:
  /// **'Toalla de playa'**
  String get itemBeachTowel;

  /// No description provided for @itemHat.
  ///
  /// In es, this message translates to:
  /// **'Sombrero / Gorra'**
  String get itemHat;

  /// No description provided for @itemHikingBoots.
  ///
  /// In es, this message translates to:
  /// **'Botas de montaña'**
  String get itemHikingBoots;

  /// No description provided for @itemRainJacket.
  ///
  /// In es, this message translates to:
  /// **'Chubasquero'**
  String get itemRainJacket;

  /// No description provided for @itemThermalClothing.
  ///
  /// In es, this message translates to:
  /// **'Ropa térmica'**
  String get itemThermalClothing;

  /// No description provided for @itemBackpack20to30L.
  ///
  /// In es, this message translates to:
  /// **'Mochila 20-30L'**
  String get itemBackpack20to30L;

  /// No description provided for @itemTrekkingPoles.
  ///
  /// In es, this message translates to:
  /// **'Bastones'**
  String get itemTrekkingPoles;

  /// No description provided for @itemHeadlamp.
  ///
  /// In es, this message translates to:
  /// **'Linterna frontal'**
  String get itemHeadlamp;

  /// No description provided for @itemFirstAidKit.
  ///
  /// In es, this message translates to:
  /// **'Botiquín básico'**
  String get itemFirstAidKit;

  /// No description provided for @itemComfortableSneakers.
  ///
  /// In es, this message translates to:
  /// **'Zapatillas cómodas'**
  String get itemComfortableSneakers;

  /// No description provided for @itemUrbanBackpack.
  ///
  /// In es, this message translates to:
  /// **'Mochila urbana'**
  String get itemUrbanBackpack;

  /// No description provided for @itemPowerBank.
  ///
  /// In es, this message translates to:
  /// **'Power bank'**
  String get itemPowerBank;

  /// No description provided for @itemCompactUmbrella.
  ///
  /// In es, this message translates to:
  /// **'Paraguas compacto'**
  String get itemCompactUmbrella;

  /// No description provided for @itemTravelGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía de viaje'**
  String get itemTravelGuide;

  /// No description provided for @itemLaptopCharger.
  ///
  /// In es, this message translates to:
  /// **'Portátil + cargador'**
  String get itemLaptopCharger;

  /// No description provided for @itemFormalWear.
  ///
  /// In es, this message translates to:
  /// **'Traje / Ropa formal'**
  String get itemFormalWear;

  /// No description provided for @itemBusinessCards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas de visita'**
  String get itemBusinessCards;

  /// No description provided for @itemPlugAdapter.
  ///
  /// In es, this message translates to:
  /// **'Adaptador enchufes'**
  String get itemPlugAdapter;

  /// No description provided for @itemAncHeadphones.
  ///
  /// In es, this message translates to:
  /// **'Auriculares ANC'**
  String get itemAncHeadphones;

  /// No description provided for @itemClothes2to3Days.
  ///
  /// In es, this message translates to:
  /// **'Ropa 2-3 días'**
  String get itemClothes2to3Days;

  /// No description provided for @itemBasicToiletryBag.
  ///
  /// In es, this message translates to:
  /// **'Neceser básico'**
  String get itemBasicToiletryBag;

  /// No description provided for @itemTravelPillow.
  ///
  /// In es, this message translates to:
  /// **'Almohada de viaje'**
  String get itemTravelPillow;

  /// No description provided for @itemSleepMask.
  ///
  /// In es, this message translates to:
  /// **'Antifaz'**
  String get itemSleepMask;

  /// No description provided for @itemEarplugs.
  ///
  /// In es, this message translates to:
  /// **'Tapones para oídos'**
  String get itemEarplugs;

  /// No description provided for @itemLiquidsBag100ml.
  ///
  /// In es, this message translates to:
  /// **'Bolsa líquidos 100ml'**
  String get itemLiquidsBag100ml;

  /// No description provided for @itemWarmClothing.
  ///
  /// In es, this message translates to:
  /// **'Ropa de abrigo'**
  String get itemWarmClothing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
