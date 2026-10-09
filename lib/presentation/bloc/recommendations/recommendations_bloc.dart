import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/services/places/places_failures.dart';
import '../../../domain/entities/recommendations/applied_reaction.dart';
import '../../../domain/entities/recommendations/recommendation_filter.dart';
import '../../../domain/entities/recommendations/recommended_place.dart';
import '../../../domain/usecases/recommendations/compose_feed.dart';
import '../../../domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import '../../../domain/usecases/recommendations/react_to_place_usecase.dart';
import '../../../domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';
import '../../../domain/usecases/recommendations/reset_dislikes_usecase.dart';
import '../../../domain/usecases/recommendations/undo_reaction_usecase.dart';

part 'recommendations_event.dart';
part 'recommendations_state.dart';

/// Drives the swipe feed.
///
/// A reaction is applied to the deck first and persisted after (same optimistic
/// shape as PackingBloc), and put back if the write fails. That also makes a
/// double dispatch harmless: the second event names a card that is no longer on
/// top and is ignored.
///
/// The seed is injected so the order is reproducible in tests.
class RecommendationsBloc
    extends Bloc<RecommendationsEvent, RecommendationsState> {
  final GetRecommendationFeedUseCase _getFeed;
  final RefillRecommendationFeedUseCase _refill;
  final ReactToPlaceUseCase _react;
  final UndoReactionUseCase _undo;
  final ResetDislikesUseCase _resetDislikes;
  final int Function() _seedProvider;

  RecommendationFilter _filter = RecommendationFilter.all;
  String? _defaultDestination;
  String? _typedLocation;
  int _seed = 0;
  int _revision = 0;
  int _loadToken = 0;
  bool _providerExhausted = false;

  /// Every key offered this session, so a refill cannot resurrect a card.
  final Set<String> _seen = {};

  RecommendationsBloc({
    required GetRecommendationFeedUseCase getFeed,
    required RefillRecommendationFeedUseCase refill,
    required ReactToPlaceUseCase react,
    required UndoReactionUseCase undo,
    required ResetDislikesUseCase resetDislikes,
    int Function()? seedProvider,
  })  : _getFeed = getFeed,
        _refill = refill,
        _react = react,
        _undo = undo,
        _resetDislikes = resetDislikes,
        _seedProvider =
            seedProvider ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(const RecommendationsState()) {
    on<FeedStarted>(_onStarted);
    on<FeedFilterChanged>(_onFilterChanged);
    on<FeedLocationChanged>(_onLocationChanged);
    on<FeedRetried>((_, emit) => _load(emit));
    on<FeedCardReacted>(_onReacted);
    on<FeedUndoRequested>(_onUndo);
    on<FeedDislikesResetRequested>(_onReset);
  }

  String? get _location {
    final typed = _typedLocation;
    return typed != null && typed.isNotEmpty ? typed : _defaultDestination;
  }

  // ── Loading ─────────────────────────────────────────────────────────────

  Future<void> _onStarted(
      FeedStarted e, Emitter<RecommendationsState> emit) async {
    _defaultDestination = e.destination;
    await _load(emit);
  }

  Future<void> _onFilterChanged(
      FeedFilterChanged e, Emitter<RecommendationsState> emit) async {
    _filter = e.filter;
    await _load(emit);
  }

  Future<void> _onLocationChanged(
      FeedLocationChanged e, Emitter<RecommendationsState> emit) async {
    _typedLocation = e.text.trim();
    await _load(emit);
  }

  RecommendationsState _snapshot(
    FeedStatus status, {
    List<RecommendedPlace> cards = const [],
    FeedNotice? notice,
    String? errorMessage,
  }) =>
      RecommendationsState(
        status: status,
        filter: _filter,
        destinationHint: _location,
        cards: cards,
        notice: notice,
        revision: notice == null ? _revision : ++_revision,
        errorMessage: errorMessage,
      );

  Future<void> _load(Emitter<RecommendationsState> emit,
      {FeedNotice? notice}) async {
    final token = ++_loadToken;
    _seen.clear();
    _providerExhausted = false;
    _seed = _seedProvider();
    emit(_snapshot(FeedStatus.loading));

    final result = await _getFeed(
      filter: _filter,
      destinationHint: _location,
      seed: _seed,
    );
    if (token != _loadToken) return;

    FeedComposition? page;
    final failure = result.fold<Failure?>((f) => f, (p) {
      page = p;
      return null;
    });
    if (failure != null) {
      emit(failure is PlacesConfigFailure
          ? _snapshot(FeedStatus.unavailable, notice: notice)
          : _snapshot(FeedStatus.error,
              notice: notice, errorMessage: failure.message));
      return;
    }

    var cards = page!.cards;
    _seen.addAll(cards.map((c) => c.key));
    if (page!.eligibleCount == 0) {
      emit(_snapshot(FeedStatus.empty, notice: notice));
      return;
    }

    cards = [...cards, ...await _topUp(cards.length, token)];
    if (token != _loadToken) return;
    emit(_snapshot(cards.isEmpty ? FeedStatus.exhausted : FeedStatus.ready,
        cards: cards, notice: notice));
  }

  /// Asks for more cards when the deck is running low. Returns only new ones.
  /// A provider that has nothing new is remembered, so later swipes do not
  /// repeat the request.
  Future<List<RecommendedPlace>> _topUp(int remaining, int token) async {
    if (_providerExhausted || remaining >= feedRefillThreshold) return const [];
    final result = await _refill(
      filter: _filter,
      destinationHint: _location,
      seed: _seed,
      seenKeys: Set.of(_seen),
      remaining: remaining,
    );
    if (token != _loadToken) return const [];
    return result.fold((_) => const [], (added) {
      if (added.isEmpty) _providerExhausted = true;
      _seen.addAll(added.map((c) => c.key));
      return added;
    });
  }

  // ── Reactions ───────────────────────────────────────────────────────────

  Future<void> _onReacted(
      FeedCardReacted e, Emitter<RecommendationsState> emit) async {
    final deck = state.cards;
    if (state.status != FeedStatus.ready ||
        deck.isEmpty ||
        deck.first.key != e.key) {
      return;
    }
    final card = deck.first;
    final previous = state.lastReaction;
    final rest = deck.sublist(1);
    final token = _loadToken;
    final willTopUp = !_providerExhausted && rest.length < feedRefillThreshold;

    emit(state.copyWith(
      status: rest.isEmpty
          ? (willTopUp ? FeedStatus.loading : FeedStatus.exhausted)
          : FeedStatus.ready,
      cards: rest,
      lastReaction: AppliedReaction(place: card, reaction: e.reaction),
      revision: ++_revision,
    ));

    final result = await _react(card, e.reaction);
    if (token != _loadToken) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
        status: FeedStatus.ready,
        cards: [card, ...state.cards],
        lastReaction: previous,
        clearLastReaction: previous == null,
        notice: FeedNotice.reactionFailed,
        revision: ++_revision,
      ));
      return;
    }

    final added = await _topUp(state.cards.length, token);
    if (token != _loadToken) return;
    final current = state.cards.map((c) => c.key).toSet();
    final merged = [
      ...state.cards,
      ...added.where((c) => !current.contains(c.key)),
    ];
    emit(state.copyWith(
      status: merged.isEmpty ? FeedStatus.exhausted : FeedStatus.ready,
      cards: merged,
    ));
  }

  Future<void> _onUndo(
      FeedUndoRequested e, Emitter<RecommendationsState> emit) async {
    final applied = state.lastReaction;
    if (applied == null) return;

    final result = await _undo(applied);
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
          notice: FeedNotice.undoFailed, revision: ++_revision));
      return;
    }
    emit(state.copyWith(
      status: FeedStatus.ready,
      cards: [
        applied.place,
        ...state.cards.where((c) => c.key != applied.place.key),
      ],
      clearLastReaction: true,
      revision: ++_revision,
    ));
  }

  Future<void> _onReset(FeedDislikesResetRequested e,
      Emitter<RecommendationsState> emit) async {
    final result = await _resetDislikes();
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
          notice: FeedNotice.resetFailed, revision: ++_revision));
      return;
    }
    await _load(emit, notice: FeedNotice.resetDone);
  }
}
