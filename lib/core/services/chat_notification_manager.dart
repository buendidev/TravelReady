import 'dart:async';

import '../../domain/entities/chat.dart';
import '../../domain/repositories/chats_repository.dart';
import 'notification_service.dart';

/// Manager global de notificaciones de mensajes nuevos.
///
/// - Se inicia al autenticarse el usuario.
/// - Escucha el stream de chats del usuario.
/// - Cuando un chat tiene un [lastMessage] más reciente que el registrado
///   previamente y el remitente no es el propio usuario, dispara notificación.
/// - Si el usuario está dentro de ese chat (activeChatId), no notifica.
class ChatNotificationManager {
  static final ChatNotificationManager _instance = ChatNotificationManager._();
  factory ChatNotificationManager() => _instance;
  ChatNotificationManager._();

  StreamSubscription<List<ChatSummary>>? _sub;

  // chatId → última fecha de mensaje conocida
  final Map<String, DateTime> _lastSeen = {};

  bool _initialized = false;

  /// ID del chat actualmente abierto en pantalla (null = ninguno).
  String? activeChatId;

  String? _currentUserId;

  void start({
    required ChatsRepository repo,
    required String userId,
  }) {
    if (_initialized && _currentUserId == userId) return;

    _sub?.cancel();
    _lastSeen.clear();
    _initialized    = true;
    _currentUserId  = userId;

    _sub = repo.watchChats(userId).listen((chats) {
      for (final chat in chats) {
        final lastAt = chat.lastMessageAt;
        if (lastAt == null) continue;

        final prev = _lastSeen[chat.chatId];

        if (prev == null) {
          // Primera vez que vemos este chat → solo registrar, sin notificar
          _lastSeen[chat.chatId] = lastAt;
          continue;
        }

        if (lastAt.isAfter(prev)) {
          _lastSeen[chat.chatId] = lastAt;

          // No notificar si el usuario está dentro del chat activo
          if (activeChatId == chat.chatId) continue;

          NotificationService().showMessageNotification(
            senderName: chat.name.isNotEmpty ? chat.name : 'Mensaje nuevo',
            text: chat.lastMessage ?? '',
          );
        }
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _lastSeen.clear();
    _initialized   = false;
    _currentUserId = null;
  }
}
