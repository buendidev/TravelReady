import '../../../core/services/places/place_category.dart';
import '../../../domain/entities/recommendations/favorite_place.dart';

/// SQLite model of [FavoritePlace] (`place_favorites`).
class FavoritePlaceModel extends FavoritePlace {
  const FavoritePlaceModel({
    required super.key,
    required super.name,
    required super.category,
    super.address,
    super.latitude,
    super.longitude,
    super.websiteUri,
    super.openingHoursText,
    super.priceLevelLabel,
    required super.createdAt,
  });

  factory FavoritePlaceModel.fromEntity(FavoritePlace e) => FavoritePlaceModel(
        key: e.key,
        name: e.name,
        category: e.category,
        address: e.address,
        latitude: e.latitude,
        longitude: e.longitude,
        websiteUri: e.websiteUri,
        openingHoursText: e.openingHoursText,
        priceLevelLabel: e.priceLevelLabel,
        createdAt: e.createdAt,
      );

  factory FavoritePlaceModel.fromMap(Map<String, dynamic> m) =>
      FavoritePlaceModel(
        key: m['place_key'] as String,
        name: m['name'] as String,
        category: PlaceCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => PlaceCategory.other,
        ),
        address: m['address'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        websiteUri: m['website_uri'] as String?,
        openingHoursText: m['opening_hours_text'] as String?,
        priceLevelLabel: m['price_level_label'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'place_key': key,
        'name': name,
        'category': category.name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'website_uri': websiteUri,
        'opening_hours_text': openingHoursText,
        'price_level_label': priceLevelLabel,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
