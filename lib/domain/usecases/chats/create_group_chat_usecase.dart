import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/chat.dart';
import '../../repositories/chats_repository.dart';

/// Caso de uso: Crear un chat de grupo con nombre y participantes.
class CreateGroupChatUseCase {
  final ChatsRepository _repo;
  CreateGroupChatUseCase(this._repo);

  Future<Either<Failure, Chat>> call({
    required String creatorId,
    required String groupName,
    required List<String> memberIds,
  }) =>
      _repo.createGroupChat(
        creatorId: creatorId,
        groupName: groupName,
        memberIds: memberIds,
      );
}
