/// Categorías provider-neutral para descubrimiento de lugares.
/// Los gateways mapean sus tipos concretos (p. ej. Places types) a estas.
enum PlaceCategory { monument, museum, food, nature, nightlife, shopping, hotel, other }

/// Etiquetas en español para la UI (ficheros l10n fuera de superficie).
const Map<PlaceCategory, String> placeCategoryLabels = {
  PlaceCategory.monument: 'Monumentos',
  PlaceCategory.museum: 'Museos',
  PlaceCategory.food: 'Comida',
  PlaceCategory.nature: 'Naturaleza',
  PlaceCategory.nightlife: 'Ocio nocturno',
  PlaceCategory.shopping: 'Compras',
  PlaceCategory.hotel: 'Hoteles',
  PlaceCategory.other: 'Otros',
};
