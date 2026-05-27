import 'package:fpdart/fpdart.dart';

import '../../domain/entities/chat.dart';
import '../../domain/repositories/chats_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/firestore_chats_datasource.dart';

/// Implementación del repositorio de chats con Firestore (tiempo real entre dispositivos).
class ChatsRepositoryImpl implements ChatsRepository {
  final FirestoreChatsDataSource _remote;

  ChatsRepositoryImpl({required FirestoreChatsDataSource remote}) : _remote = remote;

  @override
  Future<Either<Failure, List<ChatSummary>>> getChats(String userId) async {
    try { return Right(await _remote.getChats(userId)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Stream<List<ChatSummary>> watchChats(String userId) =>
      _remote.watchChats(userId);

  @override
  Future<Either<Failure, Chat?>> findPrivateChat(String userA, String userB) async {
    try { return Right(await _remote.findPrivateChat(userA, userB)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Chat>> createPrivateChat(String userA, String userB) async {
    try { return Right(await _remote.createPrivateChat(userA, userB)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    return _remote.watchMessages(chatId);
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _remote.sendMessage(chatId: chatId, senderId: senderId, text: text);
      return const Right(unit);
    } catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Chat>> createGroupChat({
    required String creatorId,
    required String groupName,
    required List<String> memberIds,
  }) async {
    try {
      return Right(await _remote.createGroupChat(
        creatorId: creatorId,
        groupName: groupName,
        memberIds: memberIds,
      ));
    } catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUsersExcept(
      String excludeUserId) async {
    try { return Right(await _remote.getUsersExcept(excludeUserId)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchUsersExcept(String excludeUserId) =>
      _remote.watchUsersExcept(excludeUserId);

  @override
  Future<Either<Failure, Map<String, dynamic>?>> findUserByEmail(
      String email) async {
    try { return Right(await _remote.findUserByEmail(email)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> markChatAsRead(String chatId, String userId) async {
    try {
      await _remote.markChatAsRead(chatId, userId);
      return const Right(unit);
    } catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }
}
