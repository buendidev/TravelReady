part of 'chat_detail_bloc.dart';

sealed class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();
  @override List<Object?> get props => [];
}

final class ChatMessagesLoadRequested extends ChatDetailEvent {
  final String chatId;
  const ChatMessagesLoadRequested(this.chatId);
  @override List<Object?> get props => [chatId];
}

final class ChatMessagesUpdated extends ChatDetailEvent {
  final List<Message> messages;
  const ChatMessagesUpdated(this.messages);
  @override List<Object?> get props => [messages];
}

final class ChatMessageSent extends ChatDetailEvent {
  final String chatId;
  final String senderId;
  final String text;
  const ChatMessageSent({
    required this.chatId,
    required this.senderId,
    required this.text,
  });
  @override List<Object?> get props => [chatId, senderId, text];
}

final class ChatMarkedAsRead extends ChatDetailEvent {
  final String chatId;
  const ChatMarkedAsRead(this.chatId);
  @override List<Object?> get props => [chatId];
}
