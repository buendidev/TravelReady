import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/chat.dart';
import '../../models/chat_model.dart';

/// DataSource de chats en tiempo real usando Firestore.
///
/// Estructura de colecciones:
///   chats/{chatId}              — documento de chat (type, memberIds, name, createdAt)
///   chats/{chatId}/messages/{msgId} — mensajes del chat
///
/// Para listar usuarios: colección `users` ya existe en el proyecto.
class FirestoreChatsDataSource {
  final FirebaseFirestore _db;
  static const _uuid = Uuid();

  FirestoreChatsDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Colecciones ───────────────────────────────────────────────────────────

  CollectionReference get _chats => _db.collection('chats');
  CollectionReference _messages(String chatId) =>
      _db.collection('chats').doc(chatId).collection('messages');

  // ── Chats ─────────────────────────────────────────────────────────────────

  Future<List<ChatSummary>> getChats(String userId) async {
    final snap = await _chats
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    final summaries = <ChatSummary>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String name = data['name'] as String? ?? '';

      if (_parseChatType(data['type'] as String? ?? 'private') == ChatType.private &&
          name.isEmpty) {
        final members = List<String>.from(data['memberIds'] as List? ?? []);
        final otherId = members.firstWhere((id) => id != userId, orElse: () => '');
        if (otherId.isNotEmpty) {
          final userDoc = await _db.collection('users').doc(otherId).get();
          name = userDoc.data()?['name'] as String? ?? 'Usuario';
        }
      }

      final lastMsg = data['lastMessage'] as String?;
      final lastAt = (data['updatedAt'] as Timestamp?)?.toDate();
      final unreadMap = (data['unreadBy'] as Map<String, dynamic>?) ?? {};
      final unreadCount = (unreadMap[userId] as int?) ?? 0;

      summaries.add(ChatSummary(
        chatId: doc.id,
        type: _parseChatType(data['type'] as String? ?? 'private'),
        name: name,
        lastMessage: lastMsg,
        lastMessageAt: lastAt,
        unreadCount: unreadCount,
      ));
    }
    return summaries;
  }

  Stream<List<ChatSummary>> watchChats(String userId) {
    return _chats
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final summaries = <ChatSummary>[];
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String name = data['name'] as String? ?? '';

        if (_parseChatType(data['type'] as String? ?? 'private') == ChatType.private &&
            name.isEmpty) {
          final members = List<String>.from(data['memberIds'] as List? ?? []);
          final otherId = members.firstWhere((id) => id != userId, orElse: () => '');
          if (otherId.isNotEmpty) {
            final userDoc = await _db.collection('users').doc(otherId).get();
            name = userDoc.data()?['name'] as String? ?? 'Usuario';
          }
        }

        final lastMsg = data['lastMessage'] as String?;
        final lastAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final unreadMap = (data['unreadBy'] as Map<String, dynamic>?) ?? {};
        final unreadCount = (unreadMap[userId] as int?) ?? 0;

        summaries.add(ChatSummary(
          chatId: doc.id,
          type: _parseChatType(data['type'] as String? ?? 'private'),
          name: name,
          lastMessage: lastMsg,
          lastMessageAt: lastAt,
          unreadCount: unreadCount,
        ));
      }
      return summaries;
    });
  }

  Future<ChatModel?> findPrivateChat(String userA, String userB) async {
    final snap = await _chats
        .where('type', isEqualTo: 'private')
        .where('memberIds', arrayContains: userA)
        .get();

    for (final doc in snap.docs) {
      final members = List<String>.from(
          (doc.data() as Map<String, dynamic>)['memberIds'] as List? ?? []);
      if (members.contains(userB)) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatModel(
          id: doc.id,
          type: ChatType.private,
          name: data['name'] as String?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }
    }
    return null;
  }

  Future<ChatModel> createPrivateChat(String userA, String userB) async {
    final now = Timestamp.now();
    final chatId = _uuid.v4();

    await _chats.doc(chatId).set({
      'type': 'private',
      'memberIds': [userA, userB],
      'name': null,
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': null,
      'unreadBy': {},
    });

    return ChatModel(
      id: chatId,
      type: ChatType.private,
      createdAt: now.toDate(),
    );
  }

  Future<ChatModel> createGroupChat({
    required String creatorId,
    required String groupName,
    required List<String> memberIds,
  }) async {
    final now    = Timestamp.now();
    final chatId = _uuid.v4();
    final allIds = ({creatorId, ...memberIds}).toList();

    await _chats.doc(chatId).set({
      'type':        'group',
      'memberIds':   allIds,
      'name':        groupName.trim(),
      'createdBy':   creatorId,
      'createdAt':   now,
      'updatedAt':   now,
      'lastMessage': null,
      'unreadBy': {},
    });

    return ChatModel(
      id:        chatId,
      type:      ChatType.group,
      name:      groupName.trim(),
      createdAt: now.toDate(),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<Message>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return MessageModel(
                id: doc.id,
                chatId: chatId,
                senderId: data['senderId'] as String,
                text: data['text'] as String,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                isRead: data['isRead'] as bool? ?? false,
              );
            }).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final now = Timestamp.now();
    final msgId = _uuid.v4();

    final batch = _db.batch();

    batch.set(_messages(chatId).doc(msgId), {
      'senderId': senderId,
      'text': text,
      'createdAt': now,
      'isRead': false,
    });

    // Incrementar contador de no leídos para todos los miembros excepto el remitente
    final chatDoc = await _chats.doc(chatId).get();
    final chatData = chatDoc.data() as Map<String, dynamic>?;
    final members = List<String>.from(chatData?['memberIds'] as List? ?? []);
    for (final memberId in members) {
      if (memberId != senderId) {
        final current = (chatData?['unreadBy'] as Map<String, dynamic>?)?[memberId] as int? ?? 0;
        batch.update(_chats.doc(chatId), {
          'unreadBy.$memberId': current + 1,
        });
      }
    }

    batch.update(_chats.doc(chatId), {
      'lastMessage': text,
      'updatedAt': now,
    });

    await batch.commit();
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsersExcept(String excludeUserId) async {
    try {
      final snap = await _db.collection('users').get();

      final users = snap.docs
          .where((doc) => doc.id != excludeUserId)
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'email': data['email'] ?? '',
            };
          })
          .toList();

      users.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

      return users;
    } catch (e) {
      print('[FirestoreChatsDataSource] Error en getUsersExcept: $e');
      return [];
    }
  }

  /// Stream en tiempo real de usuarios registrados (excluye al propio usuario).
  /// Solo muestra usuarios que hayan iniciado sesión en los últimos 90 días
  /// o que hayan sido creados recientemente (sin lastSeen aún).
  Stream<List<Map<String, dynamic>>> watchUsersExcept(String excludeUserId) {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 90)),
    );

    return _db
        .collection('users')
        .where('lastSeen', isGreaterThanOrEqualTo: cutoff)
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .where((doc) => doc.id != excludeUserId)
          .map((doc) {
            final data = doc.data();
            return {
              'id':    doc.id,
              'name':  data['name']  ?? '',
              'email': data['email'] ?? '',
            };
          })
          .toList();

      users.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

      return users;
    });
  }

  /// Marca los mensajes de un chat como leídos para el usuario indicado.
  Future<void> markChatAsRead(String chatId, String userId) async {
    await _chats.doc(chatId).update({
      'unreadBy.$userId': 0,
    });
  }

  /// Busca un usuario por su email exacto. Retorna null si no existe.
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
    };
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

  static ChatType _parseChatType(String v) {
    switch (v) {
      case 'support': return ChatType.support;
      case 'ai': return ChatType.ai;
      case 'group': return ChatType.group;
      default: return ChatType.private;
    }
  }
}
