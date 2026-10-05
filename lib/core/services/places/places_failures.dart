import '../../errors/failures.dart';

/// Fallos específicos de proveedores de lugares/mapas.
/// Viven en este paquete (no en core/errors) para mantener la
/// frontera provider-neutral autocontenida.

/// El proveedor no está configurado (sin clave, sin billing, etc.).
/// La UI debe mostrar el estado `unavailable`, no un error genérico.
class PlacesConfigFailure extends Failure {
  const PlacesConfigFailure(super.message);
}

/// Cuota/límite del proveedor excedido (429, OVER_QUERY_LIMIT...).
/// La UI puede diferenciarlo de un error de red para sugerir
/// reintento más tarde o modo offline.
class PlacesQuotaFailure extends Failure {
  const PlacesQuotaFailure(super.message);
}

/// El proveedor respondió con datos inválidos/incompletos.
class PlacesParseFailure extends Failure {
  const PlacesParseFailure(super.message);
}
