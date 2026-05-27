import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales.
/// Cubre: mensajes nuevos + viajes próximos.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelMessages = AndroidNotificationChannel(
    'tr_messages',
    'Mensajes',
    description: 'Notificaciones de mensajes nuevos',
    importance: Importance.high,
  );

  static const _channelTrips = AndroidNotificationChannel(
    'tr_trips',
    'Viajes',
    description: 'Recordatorios de viajes próximos',
    importance: Importance.defaultImportance,
  );

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Crear canales Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channelMessages);
    await androidPlugin?.createNotificationChannel(_channelTrips);

    // Pedir permiso en Android 13+
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Notificación de mensaje nuevo.
  /// [senderName] — nombre del remitente.
  /// [text] — texto del mensaje.
  Future<void> showMessageNotification({
    required String senderName,
    required String text,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tr_messages',
      'Mensajes',
      channelDescription: 'Notificaciones de mensajes nuevos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      senderName.hashCode,
      senderName,
      text,
      details,
    );
  }

  /// Notificación de viaje próximo.
  /// [tripName] — nombre del viaje.
  /// [destination] — destino.
  /// [daysLeft] — días restantes.
  Future<void> showTripReminder({
    required String tripName,
    required String destination,
    required int daysLeft,
  }) async {
    final body = daysLeft == 0
        ? '¡Tu viaje a $destination empieza hoy!'
        : daysLeft == 1
            ? '¡Mañana viajes a $destination! ¿Tenés todo listo?'
            : 'Faltan $daysLeft días para tu viaje a $destination.';

    const androidDetails = AndroidNotificationDetails(
      'tr_trips',
      'Viajes',
      channelDescription: 'Recordatorios de viajes próximos',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      tripName.hashCode,
      '✈️ $tripName',
      body,
      details,
    );
  }
}
