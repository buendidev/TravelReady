import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/recommendations/applied_reaction.dart';
import '../../../domain/entities/recommendations/recommended_place.dart';
import '../../../l10n/app_localizations.dart';
import '../discovery/place_category_labels.dart';
import 'recommendation_card.dart';

/// Tinder-style deck: the top card follows the finger, two more sit partially
/// visible behind it, and two always-visible buttons do exactly what the swipe
/// does. The swipe is an enhancement; the buttons (and the semantic actions on
/// the card) are the way in for anyone who cannot or does not want to drag.
///
/// Right means like, left means dislike. A swipe commits at about 35 % of the
/// card width or on a fling faster than about 800 px/s; below that the card
/// springs back. The widget only reports the reaction through [onReact]; it is
/// up to the parent to take the card off [cards].
class SwipeCardDeck extends StatefulWidget {
  /// Top card first.
  final List<RecommendedPlace> cards;

  final void Function(RecommendedPlace card, PlaceReaction reaction) onReact;

  const SwipeCardDeck({super.key, required this.cards, required this.onReact});

  @override
  State<SwipeCardDeck> createState() => _SwipeCardDeckState();
}

class _SwipeCardDeckState extends State<SwipeCardDeck>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _flingVelocity = 800;
  static const double _radiansPerCardWidth = 0.5;
  static const int _cardsBehind = 2;

  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 350, ratio: 0.75);

  late final AnimationController _controller;

  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _cardWidth = 1;
  bool _inZone = false;
  bool _springing = false;

  /// True from the moment a reaction is chosen until the parent replaces the
  /// top card: the card stays off screen and the buttons are inert.
  bool _committing = false;
  PlaceReaction? _pending;

  double get _threshold => _cardWidth * _commitFraction;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(SwipeCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.cards.isEmpty ? null : oldWidget.cards.first.key;
    final now = widget.cards.isEmpty ? null : widget.cards.first.key;
    // A new top card starts centred. A refill that only appends cards leaves a
    // drag in progress alone.
    if (before != now) _resetDrag(notify: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Animation plumbing ──────────────────────────────────────────────────

  void _onTick() =>
      setState(() => _drag = Offset.lerp(_from, _to, _controller.value)!);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_pending != null) {
      _finishCommit();
    } else if (_springing) {
      setState(() {
        _springing = false;
        _drag = Offset.zero;
      });
    }
  }

  void _resetDrag({bool notify = true}) {
    _controller.stop();
    void reset() {
      _drag = Offset.zero;
      _committing = false;
      _springing = false;
      _inZone = false;
      _pending = null;
    }

    if (notify) {
      setState(reset);
    } else {
      reset();
    }
  }

  void _springBack() {
    _springing = true;
    _from = _drag;
    _to = Offset.zero;
    _controller.value = 0;
    _controller.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  void _commit(PlaceReaction reaction) {
    if (_committing || widget.cards.isEmpty) return;
    setState(() => _committing = true);
    _pending = reaction;
    _springing = false;
    final direction = reaction == PlaceReaction.like ? 1.0 : -1.0;
    _from = _drag;
    _to = Offset(direction * _cardWidth * 1.6, _drag.dy);
    _controller.value = 0;
    _controller.animateTo(1,
        duration: const Duration(milliseconds: 220), curve: Curves.easeIn);
  }

  void _finishCommit() {
    final reaction = _pending!;
    _pending = null;
    final snapshot = widget.cards;
    widget.onReact(snapshot.first, reaction);
    // Normally the parent swaps the top card within this frame. If it kept the
    // same deck, bring the card back instead of losing it off screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(widget.cards, snapshot)) _resetDrag();
    });
  }

  // ── Gestures ────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_committing) return;
    _controller.stop();
    _springing = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_committing) return;
    setState(() {
      _drag += details.delta;
      final inZone = _drag.dx.abs() >= _threshold;
      if (inZone && !_inZone) HapticFeedback.selectionClick();
      _inZone = inZone;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_committing) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    PlaceReaction? reaction;
    if (vx.abs() >= _flingVelocity) {
      reaction = vx > 0 ? PlaceReaction.like : PlaceReaction.dislike;
    } else if (_drag.dx.abs() >= _threshold) {
      reaction = _drag.dx > 0 ? PlaceReaction.like : PlaceReaction.dislike;
    }
    _inZone = false;
    reaction == null ? _springBack() : _commit(reaction);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH,
              AppSizes.sm, AppSizes.screenPaddingH, AppSizes.lg),
          child: LayoutBuilder(builder: (context, constraints) {
            _cardWidth = constraints.maxWidth;
            return Stack(clipBehavior: Clip.none, children: [
              for (var i = _cardsBehind; i >= 1; i--)
                if (i < cards.length) _behind(i, cards[i]),
              _top(context, cards.first),
            ]);
          }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH, 0,
            AppSizes.screenPaddingH, AppSizes.md),
        child: Row(children: [
          Expanded(
            child: _ReactionButton(
              label: l10n.feedDislikeAction,
              icon: Icons.close_rounded,
              color: AppColors.error,
              filled: false,
              onPressed: _committing
                  ? null
                  : () => _commit(PlaceReaction.dislike),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: _ReactionButton(
              label: l10n.feedLikeAction,
              icon: Icons.favorite_rounded,
              color: AppColors.primary,
              filled: true,
              onPressed:
                  _committing ? null : () => _commit(PlaceReaction.like),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _behind(int depth, RecommendedPlace card) => Positioned.fill(
        key: ValueKey('deck-behind-$depth'),
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, depth * 10.0),
              child: Transform.scale(
                scale: 1 - depth * 0.05,
                alignment: Alignment.bottomCenter,
                child: RecommendationCard(place: card.place),
              ),
            ),
          ),
        ),
      );

  Widget _top(BuildContext context, RecommendedPlace card) {
    final l10n = AppLocalizations.of(context);
    final angle = _drag.dx / _cardWidth * _radiansPerCardWidth;
    final showLike = _drag.dx >= _threshold;
    final showDislike = _drag.dx <= -_threshold;
    final categoryLabel = placeCategoryLabel(l10n, card.place.category);

    return Positioned.fill(
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: () {
          if (!_committing) _springBack();
        },
        child: Transform.translate(
          offset: _drag,
          child: Transform.rotate(
            key: const ValueKey('deck-top-rotation'),
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Semantics(
              container: true,
              label: [
                card.place.name,
                categoryLabel,
                if (card.place.address != null) card.place.address!,
              ].join('. '),
              hint: l10n.feedSwipeHint,
              customSemanticsActions: {
                CustomSemanticsAction(label: l10n.feedLikeAction): () =>
                    _commit(PlaceReaction.like),
                CustomSemanticsAction(label: l10n.feedDislikeAction): () =>
                    _commit(PlaceReaction.dislike),
              },
              child: Stack(
                key: const ValueKey('deck-top-card'),
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: RecommendationCard(place: card.place)),
                  if (showLike)
                    const Positioned(
                      top: AppSizes.lg,
                      left: AppSizes.lg,
                      child: _Badge(
                        key: ValueKey('swipe-like-badge'),
                        icon: Icons.favorite_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  if (showDislike)
                    const Positioned(
                      top: AppSizes.lg,
                      right: AppSizes.lg,
                      child: _Badge(
                        key: ValueKey('swipe-dislike-badge'),
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative "♥" / "✕" stamp shown once the commit threshold is crossed.
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Badge({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(icon, color: color, size: 40),
        ),
      );
}

/// A labelled button that is also one accessibility node: the label, the button
/// role, the enabled state and the tap action live on a single [Semantics].
class _ReactionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onPressed;

  const _ReactionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const size = Size(0, AppSizes.buttonHeight);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                  minimumSize: size, backgroundColor: color),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: color),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                minimumSize: size,
                side: BorderSide(color: color, width: 1.5),
              ),
            ),
    );
  }
}
