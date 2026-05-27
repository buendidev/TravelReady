import 'package:equatable/equatable.dart';

/// Tipos de chat disponibles.
enum ChatType { private, support, ai, group }

/// Entidad pura de dominio: Chat (conversación).
class Chat extends Equatable {
  final String id;
  final ChatType type;
  final String? name;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.type,
    this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, name, createdAt];
}

/// Entidad pura de dominio: Mensaje dentro de un chat.
class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, chatId, senderId, text, createdAt, isRead];
}

/// Resumen de un chat para la lista de conversaciones.
/// Incluye el último mensaje y el nombre del interlocutor.
class ChatSummary extends Equatable {
  final String chatId;
  final ChatType type;
  final String name; // Nombre del chat o del otro usuario
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatSummary({
    required this.chatId,
    required this.type,
    required this.name,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [chatId, type, name, lastMessage, lastMessageAt, unreadCount];
}
