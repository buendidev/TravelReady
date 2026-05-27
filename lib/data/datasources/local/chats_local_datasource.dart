import 'dart:async';

import '../../../core/database/database_helper.dart';
import '../../../core/security/crypto_service.dart';
import '../../../domain/entities/chat.dart';
import '../../models/chat_model.dart';

/// DataSource local para chats y mensajes usando SQLite.
class ChatsLocalDataSource {
  final DatabaseHelper _db;

  final Map<String, StreamController<List<MessageModel>>> _msgControllers = {};
  final Map<String, StreamController<List<ChatSummary>>> _chatControllers = {};

  ChatsLocalDataSource({required DatabaseHelper database}) : _db = database;

  // ── Change Notifications ───────────────────────────────────────────────────

  Future<void> _notifyMessagesChanged(String chatId) async {
    final ctrl = _msgControllers[chatId];
    if (ctrl == null || ctrl.isClosed) return;
    try {
      ctrl.add(await getMessages(chatId));
    } catch (e) {
      ctrl.addError(e);
    }
  }

  Future<void> _notifyChatsChanged(String userId) async {
    final ctrl = _chatControllers[userId];
    if (ctrl == null || ctrl.isClosed) return;
    try {
      ctrl.add(await getChats(userId));
    } catch (e) {
      ctrl.addError(e);
    }
  }

  // ── Chats ─────────────────────────────────────────────────────────────────

  Future<List<ChatSummary>> getChats(String userId) async {
    // 1. Obtener chats donde el usuario es miembro
    final chatRows = await _db.rawQuery('''
      SELECT c.id, c.type, c.name, c.created_at
      FROM ${DatabaseHelper.tableChats} c
      JOIN ${DatabaseHelper.tableChatMembers} cm ON c.id = cm.chat_id
      WHERE cm.user_id = ?
      ORDER BY c.created_at DESC
    ''', [userId]);

    final summaries = <ChatSummary>[];
    for (final row in chatRows) {
      final chatId = row['id'] as String;
      final type = _parseType(row['type'] as String);

      // Último mensaje
      final lastMsgRows = await _db.rawQuery('''
        SELECT text, created_at FROM ${DatabaseHelper.tableMessages}
        WHERE chat_id = ? ORDER BY created_at DESC LIMIT 1
      ''', [chatId]);
      final lastMsg = lastMsgRows.isNotEmpty ? lastMsgRows.first : null;

      // Para privados: nombre del otro usuario
      String name = row['name'] as String? ?? '';
      if (type == ChatType.private && name.isEmpty) {
        final otherRows = await _db.rawQuery('''
          SELECT u.name FROM ${DatabaseHelper.tableUsers} u
          JOIN ${DatabaseHelper.tableChatMembers} cm ON u.id = cm.user_id
          WHERE cm.chat_id = ? AND u.id != ?
          LIMIT 1
        ''', [chatId, userId]);
        if (otherRows.isNotEmpty) {
          name = otherRows.first['name'] as String? ?? 'Usuario';
        }
      }

      summaries.add(ChatSummary(
        chatId: chatId,
        type: type,
        name: name,
        lastMessage: lastMsg?['text'] as String?,
        lastMessageAt: lastMsg != null
            ? DateTime.parse(lastMsg['created_at'] as String)
            : null,
        unreadCount: 0, // TODO: contar mensajes no leídos
      ));
    }
    return summaries;
  }

  Stream<List<ChatSummary>> watchChats(String userId) {
    final ctrl = _chatControllers.putIfAbsent(
      userId,
      () => StreamController<List<ChatSummary>>.broadcast(),
    );
    Future.microtask(() => _notifyChatsChanged(userId));
    return ctrl.stream;
  }

  Future<ChatModel?> findPrivateChat(String userA, String userB) async {
    final rows = await _db.rawQuery('''
      SELECT c.id, c.type, c.name, c.created_at
      FROM ${DatabaseHelper.tableChats} c
      JOIN ${DatabaseHelper.tableChatMembers} cm1 ON c.id = cm1.chat_id AND cm1.user_id = ?
      JOIN ${DatabaseHelper.tableChatMembers} cm2 ON c.id = cm2.chat_id AND cm2.user_id = ?
      WHERE c.type = 'private'
      LIMIT 1
    ''', [userA, userB]);
    if (rows.isEmpty) return null;
    return ChatModel.fromMap(rows.first);
  }

  Future<ChatModel> createPrivateChat(String userA, String userB) async {
    final chatId = CryptoService.generateUuid();
    final now = DateTime.now().toIso8601String();

    await _db.transaction((txn) async {
      await txn.insert(DatabaseHelper.tableChats, {
        'id': chatId,
        'type': 'private',
        'name': null,
        'created_at': now,
      });
      await txn.insert(DatabaseHelper.tableChatMembers, {
        'chat_id': chatId,
        'user_id': userA,
        'joined_at': now,
      });
      await txn.insert(DatabaseHelper.tableChatMembers, {
        'chat_id': chatId,
        'user_id': userB,
        'joined_at': now,
      });
    });

    return ChatModel(
      id: chatId,
      type: ChatType.private,
      createdAt: DateTime.parse(now),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages(String chatId) async {
    final rows = await _db.query(
      DatabaseHelper.tableMessages,
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    final ctrl = _msgControllers.putIfAbsent(
      chatId,
      () => StreamController<List<MessageModel>>.broadcast(),
    );
    Future.microtask(() => _notifyMessagesChanged(chatId));
    return ctrl.stream;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert(DatabaseHelper.tableMessages, {
      'id': CryptoService.generateUuid(),
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'created_at': now,
      'is_read': 0,
    });
    await _notifyMessagesChanged(chatId);
    // También notificar cambios en la lista de chats
    await _notifyChatsChanged(senderId);
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsersExcept(String excludeUserId) async {
    return await _db.query(
      DatabaseHelper.tableUsers,
      columns: ['id', 'name', 'email'],
      where: 'id != ?',
      whereArgs: [excludeUserId],
      orderBy: 'name ASC',
    );
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

  static ChatType _parseType(String v) {
    switch (v) {
      case 'support': return ChatType.support;
      case 'ai': return ChatType.ai;
      case 'group': return ChatType.group;
      default: return ChatType.private;
    }
  }

  void dispose() {
    for (final c in _msgControllers.values) { c.close(); }
    for (final c in _chatControllers.values) { c.close(); }
    _msgControllers.clear();
    _chatControllers.clear();
  }
}
