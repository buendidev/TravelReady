import 'package:equatable/equatable.dart';

import '../../../core/services/places/place_result.dart';
import 'place_key.dart';

/// A venue offered by the feed: the transient gateway result plus its
/// provider-neutral [key].
///
/// The [place] may carry provider-only fields (provider id, photo reference,
/// short description). They live in memory for the session and are never
/// persisted: reactions store only what [FavoritePlace] and a bare key keep.
class RecommendedPlace extends Equatable {
  final String key;
  final PlaceResult place;

  const RecommendedPlace({required this.key, required this.place});

  factory RecommendedPlace.from(PlaceResult place) =>
      RecommendedPlace(key: placeKeyOf(place), place: place);

  @override
  List<Object?> get props => [key, place];
}
