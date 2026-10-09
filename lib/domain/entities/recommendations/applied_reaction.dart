import 'package:equatable/equatable.dart';

import 'recommended_place.dart';

/// What the traveller did with a card. Right swipe is [like], left is [dislike].
enum PlaceReaction { like, dislike }

/// A reaction that was persisted, kept in memory so the last swipe can be
/// undone in a single step.
class AppliedReaction extends Equatable {
  final RecommendedPlace place;
  final PlaceReaction reaction;

  const AppliedReaction({required this.place, required this.reaction});

  @override
  List<Object?> get props => [place, reaction];
}
