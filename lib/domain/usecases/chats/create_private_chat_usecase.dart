import 'package:fpdart/fpdart.dart';

import '../../entities/chat.dart';
import '../../repositories/chats_repository.dart';
import '../../../core/errors/failures.dart';

/// Caso de uso: Crear (o reutilizar) un chat privado entre dos usuarios.
class CreatePrivateChatUseCase {
  final ChatsRepository _repo;

  CreatePrivateChatUseCase(this._repo);

  Future<Either<Failure, Chat>> call(String userA, String userB) async {
    // Si ya existe, lo devolvemos
    final existing = await _repo.findPrivateChat(userA, userB);
    return existing.fold(
      (f) => Left(f),
      (chat) async {
        if (chat != null) return Right(chat);
        return await _repo.createPrivateChat(userA, userB);
      },
    );
  }
}
