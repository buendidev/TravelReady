part of 'chat_detail_bloc.dart';

sealed class ChatDetailState extends Equatable {
  const ChatDetailState();
  @override List<Object?> get props => [];
}

final class ChatDetailInitial extends ChatDetailState {
  const ChatDetailInitial();
}

final class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

final class ChatDetailReady extends ChatDetailState {
  final List<Message> messages;
  const ChatDetailReady(this.messages);
  @override List<Object?> get props => [messages];
}

final class ChatDetailError extends ChatDetailState {
  final String? message;
  const ChatDetailError([this.message]);
  @override List<Object?> get props => [message];
}
