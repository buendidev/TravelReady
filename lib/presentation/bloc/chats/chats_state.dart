part of 'chats_bloc.dart';

sealed class ChatsState extends Equatable {
  const ChatsState();
  @override List<Object?> get props => [];
}

final class ChatsInitial extends ChatsState {
  const ChatsInitial();
}

final class ChatsLoading extends ChatsState {
  const ChatsLoading();
}

final class ChatsReady extends ChatsState {
  final List<ChatSummary> chats;
  const ChatsReady(this.chats);
  @override List<Object?> get props => [chats];
}

final class ChatsError extends ChatsState {
  final String message;
  const ChatsError(this.message);
  @override List<Object?> get props => [message];
}
