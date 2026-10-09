part of 'recommendations_bloc.dart';

sealed class RecommendationsEvent extends Equatable {
  const RecommendationsEvent();
  @override
  List<Object?> get props => [];
}

/// Opens (or re-opens) the feed. [destination] is the trip destination, used as
/// the pre-filled location until the traveller types another city.
final class FeedStarted extends RecommendationsEvent {
  final String? destination;
  const FeedStarted({this.destination});
  @override
  List<Object?> get props => [destination];
}

final class FeedFilterChanged extends RecommendationsEvent {
  final RecommendationFilter filter;
  const FeedFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

/// The traveller typed a city. Blank falls back to the trip destination.
final class FeedLocationChanged extends RecommendationsEvent {
  final String text;
  const FeedLocationChanged(this.text);
  @override
  List<Object?> get props => [text];
}

final class FeedRetried extends RecommendationsEvent {
  const FeedRetried();
}

/// A swipe or a button press on a card. Carries the card's [key] so a stale or
/// duplicated event can never react to the card that came up next.
final class FeedCardReacted extends RecommendationsEvent {
  final String key;
  final PlaceReaction reaction;
  const FeedCardReacted({required this.key, required this.reaction});
  @override
  List<Object?> get props => [key, reaction];
}

final class FeedUndoRequested extends RecommendationsEvent {
  const FeedUndoRequested();
}

/// Clears every dislike. The confirmation lives in the UI.
final class FeedDislikesResetRequested extends RecommendationsEvent {
  const FeedDislikesResetRequested();
}
