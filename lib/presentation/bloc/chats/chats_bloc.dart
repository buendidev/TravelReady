import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/chats_repository.dart';

part 'chats_event.dart';
part 'chats_state.dart';

/// BLoC que gestiona la lista de conversaciones del usuario en tiempo real.
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ChatsRepository _repo;
  StreamSubscription<List<ChatSummary>>? _chatsSub;

  ChatsBloc({required ChatsRepository repo})
      : _repo = repo,
        super(const ChatsInitial()) {
    on<ChatsLoadRequested>(_onLoad);
    on<_ChatsUpdated>(_onUpdated);
  }

  Future<void> _onLoad(ChatsLoadRequested e, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    await _chatsSub?.cancel();
    _chatsSub = _repo.watchChats(e.userId).listen(
      (chats) => add(_ChatsUpdated(chats)),
      onError: (err) => emit(ChatsError(err.toString())),
    );
  }

  void _onUpdated(_ChatsUpdated e, Emitter<ChatsState> emit) {
    emit(ChatsReady(e.chats));
  }

  @override
  Future<void> close() {
    _chatsSub?.cancel();
    return super.close();
  }
}
