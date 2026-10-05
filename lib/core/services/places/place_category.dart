/// Categorías provider-neutral para descubrimiento de lugares.
/// Los gateways mapean sus tipos concretos (p. ej. Places types) a estas.
enum PlaceCategory { monument, museum, food, nature, nightlife, shopping, hotel, other }

/// Etiquetas en español para la UI (ficheros l10n fuera de superficie).
/// Etiqueta genérica para una categoría que no tenga texto propio.
const String placeCategoryFallbackLabel = 'Otros';

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

/// Etiqueta visible de [category].
///
/// El mapa cubre hoy todas las categorías, pero la búsqueda no debe depender
/// de eso: si se añade un valor al enum, esto devuelve la etiqueta genérica en
/// lugar de reventar la pantalla.
String placeCategoryLabel(PlaceCategory category) =>
    placeCategoryLabels[category] ?? placeCategoryFallbackLabel;
