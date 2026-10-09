part of 'recommendations_bloc.dart';

sealed class RecommendationsEvent extends Equatable {
  const RecommendationsEvent();
  @override
  List<Object?> get props => [];
}

/// Opens (or re-opens) the feed. [destination] is the trip destination, used as
/// the pre-filled location until the traveller types another city.
/// [accountId] is the signed-in account whose reactions this feed reads and
/// writes.
final class FeedStarted extends RecommendationsEvent {
  final String? destination;
  final String accountId;
  const FeedStarted({this.destination, required this.accountId});
  @override
  List<Object?> get props => [destination, accountId];
}

final class FeedFilterChanged extends RecommendationsEvent {
  final RecommendationFilter filter;
  final String accountId;
  const FeedFilterChanged(this.filter, {required this.accountId});
  @override
  List<Object?> get props => [filter, accountId];
}

/// The traveller typed a city. Blank falls back to the trip destination.
final class FeedLocationChanged extends RecommendationsEvent {
  final String text;
  final String accountId;
  const FeedLocationChanged(this.text, {required this.accountId});
  @override
  List<Object?> get props => [text, accountId];
}

final class FeedRetried extends RecommendationsEvent {
  final String accountId;
  const FeedRetried({required this.accountId});
  @override
  List<Object?> get props => [accountId];
}

/// A swipe or a button press on a card. Carries the card's [key] so a stale or
/// duplicated event can never react to the card that came up next.
final class FeedCardReacted extends RecommendationsEvent {
  final String key;
  final PlaceReaction reaction;
  final String accountId;
  const FeedCardReacted(
      {required this.key, required this.reaction, required this.accountId});
  @override
  List<Object?> get props => [key, reaction, accountId];
}

final class FeedUndoRequested extends RecommendationsEvent {
  final String accountId;
  const FeedUndoRequested({required this.accountId});
  @override
  List<Object?> get props => [accountId];
}

/// Clears every dislike of the signed-in account. The confirmation lives in
/// the UI.
final class FeedDislikesResetRequested extends RecommendationsEvent {
  final String accountId;
  const FeedDislikesResetRequested({required this.accountId});
  @override
  List<Object?> get props => [accountId];
}
