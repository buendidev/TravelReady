import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/chats_repository.dart';

part 'chat_detail_event.dart';
part 'chat_detail_state.dart';

/// BLoC que gestiona los mensajes de un chat específico en tiempo real.
class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatsRepository _repo;
  final String currentUserId;
  final String chatName;
  StreamSubscription? _msgSub;

  ChatDetailBloc({
    required ChatsRepository repo,
    required this.currentUserId,
    required this.chatName,
  })  : _repo = repo,
        super(const ChatDetailInitial()) {
    on<ChatMessagesLoadRequested>(_onLoad);
    on<ChatMessagesUpdated>(_onUpdated);
    on<ChatMessageSent>(_onSend);
    on<ChatMarkedAsRead>(_onMarkRead);
  }

  Future<void> _onLoad(
      ChatMessagesLoadRequested e, Emitter<ChatDetailState> emit) async {
    emit(const ChatDetailLoading());
    await _msgSub?.cancel();
    _msgSub = _repo.watchMessages(e.chatId).listen(
      (msgs) => add(ChatMessagesUpdated(msgs)),
      onError: (_) => emit(const ChatDetailError()),
    );
    // Marcar como leído al entrar al chat
    add(ChatMarkedAsRead(e.chatId));
  }

  void _onUpdated(ChatMessagesUpdated e, Emitter<ChatDetailState> emit) {
    emit(ChatDetailReady(e.messages));
  }

  Future<void> _onSend(
      ChatMessageSent e, Emitter<ChatDetailState> emit) async {
    if (e.text.trim().isEmpty) return;
    final result = await _repo.sendMessage(
      chatId: e.chatId,
      senderId: e.senderId,
      text: e.text.trim(),
    );
    result.fold(
      (f) => emit(ChatDetailError(f.toString())),
      (_) => null, // El stream se encarga de actualizar la UI
    );
  }

  Future<void> _onMarkRead(
      ChatMarkedAsRead e, Emitter<ChatDetailState> emit) async {
    await _repo.markChatAsRead(e.chatId, currentUserId);
  }

  @override
  Future<void> close() {
    _msgSub?.cancel();
    return super.close();
  }
}
