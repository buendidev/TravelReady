import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/pages/itinerary/itinerary_page.dart';
import 'package:travel_ready/presentation/widgets/discovery/place_category_labels.dart';

/// Guarda de traducciones: ninguna categoría puede quedarse sin etiqueta y las
/// etiquetas tienen que existir en los dos idiomas.
///
/// Las funciones resuelven la etiqueta con un `switch` sobre el enum cerrado,
/// así que añadir una categoría rompe la compilación en lugar de la pantalla.
/// Lo que el compilador no puede comprobar es que la clave de l10n de cada
/// idioma tenga texto, y eso es lo que se afirma aquí.
void main() {
  for (final locale in const [Locale('es'), Locale('en')]) {
    test('toda categoría tiene etiqueta en ${locale.languageCode}', () async {
      final l10n = await AppLocalizations.delegate.load(locale);

      for (final category in PlaceCategory.values) {
        expect(placeCategoryLabel(l10n, category).trim(), isNotEmpty,
            reason: 'categoría de lugar $category sin etiqueta');
      }
      for (final category in ItineraryCategory.values) {
        expect(itineraryCategoryLabel(l10n, category).trim(), isNotEmpty,
            reason: 'categoría de itinerario $category sin etiqueta');
      }
    });
  }

  test('las etiquetas cambian de idioma de verdad', () async {
    final es = await AppLocalizations.delegate.load(const Locale('es'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(placeCategoryLabel(es, PlaceCategory.museum), 'Museos');
    expect(placeCategoryLabel(en, PlaceCategory.museum), 'Museums');
    expect(placeCategoryLabel(es, PlaceCategory.other), 'Otros');
    expect(placeCategoryLabel(en, PlaceCategory.other), 'Other');

    expect(itineraryCategoryLabel(es, ItineraryCategory.sightseeing), 'Visita');
    expect(
        itineraryCategoryLabel(en, ItineraryCategory.sightseeing), 'Sightseeing');
    expect(itineraryCategoryLabel(es, ItineraryCategory.other), 'Otro');
    expect(itineraryCategoryLabel(en, ItineraryCategory.other), 'Other');
  });
}
