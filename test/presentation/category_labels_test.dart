import 'package:flutter_test/flutter_test.dart';

import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/presentation/pages/itinerary/itinerary_page.dart';

/// Las páginas resuelven la etiqueta con un respaldo, así que un valor nuevo
/// del enum ya no puede romper la pantalla. Lo que sí puede pasar es que quede
/// sin texto propio: esta guarda falla en ese caso en lugar de dejar que la UI
/// muestre una etiqueta genérica sin que nadie se entere.
void main() {
  test('toda categoría de lugar tiene etiqueta propia', () {
    for (final category in PlaceCategory.values) {
      expect(placeCategoryLabels[category], isNotNull,
          reason: '$category se agregó al enum y le falta etiqueta');
    }
  });

  test('toda categoría de itinerario tiene etiqueta propia', () {
    for (final category in ItineraryCategory.values) {
      expect(itineraryCategoryLabels[category], isNotNull,
          reason: '$category se agregó al enum y le falta etiqueta');
    }
  });

  test('ninguna etiqueta está vacía', () {
    expect(placeCategoryLabels.values.every((v) => v.trim().isNotEmpty), isTrue);
    expect(
        itineraryCategoryLabels.values.every((v) => v.trim().isNotEmpty), isTrue);
  });
}
