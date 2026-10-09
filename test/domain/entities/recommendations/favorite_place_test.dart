import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/domain/entities/recommendations/favorite_place.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';

void main() {
  const result = PlaceResult(
    providerId: 'prov-1',
    photoReference: 'photo-1',
    name: 'Museo Nacional del Prado',
    category: PlaceCategory.museum,
    address: 'C. de Ruiz de Alarcón 23, Madrid',
    latitude: 40.4138,
    longitude: -3.6921,
    websiteUri: 'https://www.museodelprado.es',
    openingHoursText: 'L–S 10:00–20:00',
    priceLevelLabel: '€€',
    shortDescription: 'Pinacoteca estatal.',
  );
  final createdAt = DateTime.utc(2026, 10, 9, 12);

  test('keeps the key and every provider-neutral field', () {
    final favorite =
        FavoritePlace.fromRecommended(RecommendedPlace.from(result), createdAt: createdAt);

    expect(favorite.key, placeKeyOf(result));
    expect(favorite.name, result.name);
    expect(favorite.category, PlaceCategory.museum);
    expect(favorite.address, result.address);
    expect(favorite.latitude, 40.4138);
    expect(favorite.longitude, -3.6921);
    expect(favorite.websiteUri, result.websiteUri);
    expect(favorite.openingHoursText, result.openingHoursText);
    expect(favorite.priceLevelLabel, '€€');
    expect(favorite.createdAt, createdAt);
  });

  test('toPlaceResult rebuilds a display result without provider data', () {
    final shown = FavoritePlace.fromRecommended(RecommendedPlace.from(result),
            createdAt: createdAt)
        .toPlaceResult();

    expect(shown.providerId, isNull);
    expect(shown.photoReference, isNull);
    expect(shown.shortDescription, isNull,
        reason: 'provider description is not retained');
    expect(shown.name, result.name);
    expect(shown.category, PlaceCategory.museum);
    expect(shown.websiteUri, result.websiteUri);
    expect(shown.toSnapshot(), result.toSnapshot());
  });
}
