import 'package:fpdart/fpdart.dart';

import '../../errors/failures.dart';
import 'place_category.dart';
import 'place_result.dart';

/// Disponibilidad del proveedor de lugares.
enum PlacesAvailability {
  /// Proveedor configurado y operativo (futuro: Google Places).
  configured,

  /// Datos de ejemplo locales — la UI debe etiquetarlos como demo.
  demo,

  /// Sin proveedor utilizable (sin clave, sin red permitida, etc.).
  unavailable,
}

/// Frontera de proveedores de lugares (búsqueda/descubrimiento).
///
/// Nada de credenciales entra aquí: la configuración de claves es
/// responsabilidad del owner fuera del código (ver docs/).
/// Las implementaciones deben exponer [availability] de forma honesta —
/// la UI nunca simula resultados en vivo si el proveedor no está
/// configurado.
abstract class PlacesGateway {
  /// Estado actual del proveedor.
  PlacesAvailability get availability;

  /// Texto de atribución exigido por los ToS del proveedor
  /// (p. ej. "Powered by Google"). Null si no aplica.
  /// La UI DEBE mostrarlo cuando exista.
  String? get attributionText;

  /// Busca lugares por texto libre y categoría opcional.
  /// Debe devolver `Left(Failure)` en error (red, cuota, config) —
  /// nunca lanzar excepciones ni devolver datos ficticios como reales.
  Future<Either<Failure, List<PlaceResult>>> search({
    required String query,
    PlaceCategory? category,
    String? destinationHint,
    int limit = 20,
  });
}
