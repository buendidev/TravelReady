part of 'recommendations_bloc.dart';

enum FeedStatus {
  initial,
  loading,
  ready,

  /// The provider had nothing for this filter and location.
  empty,

  /// There were places, but the traveller has reacted to all of them.
  exhausted,

  /// No provider is configured; never a simulated result.
  unavailable,
  error,
}

/// One-shot messages for the UI. Delivered through [RecommendationsState.revision].
enum FeedNotice { reactionFailed, undoFailed, resetDone, resetFailed }

class RecommendationsState extends Equatable {
  final FeedStatus status;
  final RecommendationFilter filter;

  /// The location context in effect: the typed city or the trip destination.
  final String? destinationHint;

  /// The deck, top card first.
  final List<RecommendedPlace> cards;

  /// The last persisted swipe, kept so it can be undone in one step.
  final AppliedReaction? lastReaction;
  final FeedNotice? notice;

  /// Bumps whenever the UI must react (a swipe, an undo, a notice), so
  /// listeners can tell a new event from an unrelated rebuild.
  final int revision;
  final String? errorMessage;

  const RecommendationsState({
    this.status = FeedStatus.initial,
    this.filter = RecommendationFilter.all,
    this.destinationHint,
    this.cards = const [],
    this.lastReaction,
    this.notice,
    this.revision = 0,
    this.errorMessage,
  });

  /// [notice] is never carried over: it is set only when explicitly passed.
  RecommendationsState copyWith({
    FeedStatus? status,
    List<RecommendedPlace>? cards,
    AppliedReaction? lastReaction,
    bool clearLastReaction = false,
    FeedNotice? notice,
    int? revision,
  }) =>
      RecommendationsState(
        status: status ?? this.status,
        filter: filter,
        destinationHint: destinationHint,
        cards: cards ?? this.cards,
        lastReaction: clearLastReaction ? null : lastReaction ?? this.lastReaction,
        notice: notice,
        revision: revision ?? this.revision,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        filter,
        destinationHint,
        cards,
        lastReaction,
        notice,
        revision,
        errorMessage,
      ];
}
