import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';

void main() {
  group('normalizePlaceText', () {
    test('trims, collapses inner whitespace and casefolds', () {
      expect(normalizePlaceText('  Museo   NACIONAL\tdel\nPrado  '),
          'museo nacional del prado');
    });

    test('strips accents and diacritics', () {
      expect(normalizePlaceText('Basílica de la Sagrada Família'),
          'basilica de la sagrada familia');
      expect(normalizePlaceText('ÁÉÍÓÚ üñç'), 'aeiou unc');
    });

    test('strips combining marks from decomposed input', () {
      expect(normalizePlaceText('Alarco\u0301n'), normalizePlaceText('Alarcón'));
    });

    test('folds sharp s and ligatures', () {
      expect(normalizePlaceText('Straße'), 'strasse');
      expect(normalizePlaceText('Œuvre Æ'), 'oeuvre ae');
    });
  });

  group('placeKey', () {
    String key({
      String name = 'Museo Nacional del Prado',
      String? address = 'C. de Ruiz de Alarcón 23, Madrid',
      double? latitude,
      double? longitude,
    }) =>
        placeKey(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude);

    test('is a lowercase sha256 hex digest', () {
      expect(key(), matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('is stable across case, accents and extra spaces', () {
      final reference = key();
      expect(
          key(
              name: '  MUSEO nacional   del PRADO ',
              address: 'c. de ruiz de alarcon 23,   MADRID'),
          reference);
    });

    test('differs when the name differs', () {
      expect(key(name: 'Museo Reina Sofía'), isNot(key()));
    });

    test('differs when the address differs', () {
      expect(key(address: 'Otra calle 1, Madrid'), isNot(key()));
    });

    test('uses the address and ignores coordinates when an address exists', () {
      expect(key(latitude: 40.4138, longitude: -3.6921),
          key(latitude: 10, longitude: 10));
    });

    test('falls back to rounded coordinates when the address is missing', () {
      final a = key(address: null, latitude: 40.41381, longitude: -3.69211);
      final b = key(address: null, latitude: 40.41384, longitude: -3.69214);
      expect(a, b, reason: 'both round to 40.4138,-3.6921');
      expect(key(address: null, latitude: 40.4139, longitude: -3.6921), isNot(a));
    });

    test('treats a blank address as missing', () {
      expect(key(address: '   ', latitude: 40.4138, longitude: -3.6921),
          key(address: null, latitude: 40.4138, longitude: -3.6921));
    });

    test('does not mix the address form with the coordinate form', () {
      expect(key(address: null, latitude: 40.4138, longitude: -3.6921),
          isNot(key(address: 'x', latitude: 40.4138, longitude: -3.6921)));
    });

    test('needs both coordinates, otherwise only the name is keyed', () {
      final nameOnly = key(address: null);
      expect(key(address: null, latitude: 40.4138), nameOnly);
      expect(key(address: null, longitude: -3.6921), nameOnly);
      expect(key(address: null, latitude: double.nan, longitude: 1), nameOnly);
    });

    test('does not split a place on a negative zero coordinate', () {
      expect(key(address: null, latitude: -0.00001, longitude: 2.0),
          key(address: null, latitude: 0.00001, longitude: 2.0));
    });

    test('documents the collision: same name and address are the same place',
        () {
      expect(key(name: 'Café Central', address: 'Plaza 1'),
          key(name: 'cafe  central', address: 'plaza   1'));
    });
  });

  group('placeKeyOf', () {
    test('ignores provider id and photo reference', () {
      const a = PlaceResult(
          providerId: 'prov-a',
          photoReference: 'photo-a',
          name: 'La Alhambra',
          category: PlaceCategory.monument,
          address: 'C. Real de la Alhambra, Granada');
      const b = PlaceResult(
          providerId: 'prov-b',
          photoReference: 'photo-b',
          name: 'La Alhambra',
          category: PlaceCategory.monument,
          address: 'C. Real de la Alhambra, Granada');
      expect(placeKeyOf(a), placeKeyOf(b));
    });
  });
}
