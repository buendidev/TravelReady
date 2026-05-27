import '../../domain/entities/chat.dart';

/// Modelo de datos para Chat (persistencia SQLite).
class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.type,
    super.name,
    required super.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] as String,
      type: _parseType(map['type'] as String? ?? 'private'),
      name: map['name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatModel.fromEntity(Chat chat) {
    return ChatModel(
      id: chat.id,
      type: chat.type,
      name: chat.name,
      createdAt: chat.createdAt,
    );
  }

  static ChatType _parseType(String v) {
    switch (v) {
      case 'support': return ChatType.support;
      case 'ai': return ChatType.ai;
      case 'group': return ChatType.group;
      default: return ChatType.private;
    }
  }
}

/// Modelo de datos para Message (persistencia SQLite).
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.text,
    required super.createdAt,
    super.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      senderId: map['sender_id'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory MessageModel.fromEntity(Message msg) {
    return MessageModel(
      id: msg.id,
      chatId: msg.chatId,
      senderId: msg.senderId,
      text: msg.text,
      createdAt: msg.createdAt,
      isRead: msg.isRead,
    );
  }
}
