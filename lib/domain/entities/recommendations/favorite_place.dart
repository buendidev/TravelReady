import 'package:equatable/equatable.dart';

import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import 'recommended_place.dart';

/// A place the traveller liked, as it is retained on the device.
///
/// This is the retention boundary for the feed: there is intentionally no
/// provider id, no photo reference and no provider description here, so none of
/// them can reach local storage through this type.
class FavoritePlace extends Equatable {
  final String key;
  final String name;
  final PlaceCategory category;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? websiteUri;
  final String? openingHoursText;
  final String? priceLevelLabel;
  final DateTime createdAt;

  const FavoritePlace({
    required this.key,
    required this.name,
    required this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.websiteUri,
    this.openingHoursText,
    this.priceLevelLabel,
    required this.createdAt,
  });

  factory FavoritePlace.fromRecommended(
    RecommendedPlace card, {
    required DateTime createdAt,
  }) =>
      FavoritePlace(
        key: card.key,
        name: card.place.name,
        category: card.place.category,
        address: card.place.address,
        latitude: card.place.latitude,
        longitude: card.place.longitude,
        websiteUri: card.place.websiteUri,
        openingHoursText: card.place.openingHoursText,
        priceLevelLabel: card.place.priceLevelLabel,
        createdAt: createdAt,
      );

  /// A display result for the existing card and details sheet. Provider-only
  /// fields are absent by construction.
  PlaceResult toPlaceResult() => PlaceResult(
        name: name,
        category: category,
        address: address,
        latitude: latitude,
        longitude: longitude,
        websiteUri: websiteUri,
        openingHoursText: openingHoursText,
        priceLevelLabel: priceLevelLabel,
      );

  @override
  List<Object?> get props => [
        key,
        name,
        category,
        address,
        latitude,
        longitude,
        websiteUri,
        openingHoursText,
        priceLevelLabel,
        createdAt,
      ];
}
