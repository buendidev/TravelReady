part of 'chats_bloc.dart';

sealed class ChatsEvent extends Equatable {
  const ChatsEvent();
  @override List<Object?> get props => [];
}

final class ChatsLoadRequested extends ChatsEvent {
  final String userId;
  const ChatsLoadRequested(this.userId);
  @override List<Object?> get props => [userId];
}

final class _ChatsUpdated extends ChatsEvent {
  final List<ChatSummary> chats;
  const _ChatsUpdated(this.chats);
  @override List<Object?> get props => [chats];
}
