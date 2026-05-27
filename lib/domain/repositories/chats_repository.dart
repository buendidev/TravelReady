import 'package:fpdart/fpdart.dart';

import '../entities/chat.dart';
import '../../core/errors/failures.dart';

/// Contrato del repositorio de chats.
abstract class ChatsRepository {
  /// Obtiene todos los chats de un usuario con resumen (último mensaje, nombre).
  Future<Either<Failure, List<ChatSummary>>> getChats(String userId);

  /// Stream en tiempo real de chats del usuario (lista actualizada automáticamente).
  Stream<List<ChatSummary>> watchChats(String userId);

  /// Busca un chat privado existente entre dos usuarios.
  Future<Either<Failure, Chat?>> findPrivateChat(String userA, String userB);

  /// Crea un chat privado entre dos usuarios.
  Future<Either<Failure, Chat>> createPrivateChat(String userA, String userB);

  /// Crea un chat de grupo con nombre y lista de participantes.
  Future<Either<Failure, Chat>> createGroupChat({
    required String creatorId,
    required String groupName,
    required List<String> memberIds,
  });

  /// Stream de mensajes de un chat en tiempo real.
  Stream<List<Message>> watchMessages(String chatId);

  /// Envía un mensaje en un chat.
  Future<Either<Failure, Unit>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  });

  /// Obtiene todos los usuarios registrados (excluyendo uno).
  Future<Either<Failure, List<Map<String, dynamic>>>> getUsersExcept(
      String excludeUserId);

  /// Stream en tiempo real de usuarios registrados (se actualiza automáticamente).
  Stream<List<Map<String, dynamic>>> watchUsersExcept(String excludeUserId);

  /// Busca un usuario por email exacto en Firestore. Retorna null si no existe.
  Future<Either<Failure, Map<String, dynamic>?>> findUserByEmail(String email);

  /// Marca todos los mensajes de un chat como leídos para el usuario indicado.
  Future<Either<Failure, Unit>> markChatAsRead(String chatId, String userId);
}
