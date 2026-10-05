/// Categorías provider-neutral para descubrimiento de lugares.
/// Los gateways mapean sus tipos concretos (p. ej. Places types) a estas.
///
/// Las etiquetas visibles viven en la capa de presentación
/// (`placeCategoryLabel`), porque dependen del idioma activo.
enum PlaceCategory { monument, museum, food, nature, nightlife, shopping, hotel, other }
