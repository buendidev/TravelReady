import '../../../core/services/places/place_category.dart';
import '../../../l10n/app_localizations.dart';

/// Etiqueta visible de [category] en el idioma activo.
///
/// Un `switch` sobre este enum cerrado hace que añadir una categoría rompa la
/// compilación en lugar de la pantalla, que es lo que pasaba con el mapa y su
/// `!` anteriores.
String placeCategoryLabel(AppLocalizations l10n, PlaceCategory category) {
  switch (category) {
    case PlaceCategory.monument:
      return l10n.placeCategoryMonument;
    case PlaceCategory.museum:
      return l10n.placeCategoryMuseum;
    case PlaceCategory.food:
      return l10n.placeCategoryFood;
    case PlaceCategory.nature:
      return l10n.placeCategoryNature;
    case PlaceCategory.nightlife:
      return l10n.placeCategoryNightlife;
    case PlaceCategory.shopping:
      return l10n.placeCategoryShopping;
    case PlaceCategory.hotel:
      return l10n.placeCategoryHotel;
    case PlaceCategory.other:
      return l10n.catOther;
  }
}
