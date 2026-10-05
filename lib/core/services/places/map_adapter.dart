import 'package:flutter/widgets.dart';

import 'place_result.dart';
import 'places_gateway.dart';

/// Frontera provider-neutral para mapas.
///
/// NO existe implementación todavía: google_maps_flutter requiere
/// claves, billing y configuración del owner (ver
/// `docs/places-integration.md`). Esta interfaz fija el contrato
/// para que la UI de descubrimiento/itinerario pueda adoptar un mapa
/// sin conocer el SDK concreto.
abstract class MapAdapter {
  /// Disponibilidad del mapa. Sin configuración nativa (clave
  /// restringida por app en el manifest) debe ser `unavailable`.
  PlacesAvailability get availability;

  /// Texto de atribución obligatorio del proveedor (p. ej.
  /// "Powered by Google"). Null si no aplica. La UI DEBE
  /// renderizarlo cuando exista — es requisito legal de los ToS.
  String? get attributionText;

  /// Viewport de mapa con marcadores provider-neutral.
  ///
  /// El adapter decide cómo renderizar cada [PlaceResult]
  /// (icono por categoría, info window, etc.). Las coordenadas
  /// son lat/lng WGS84 planos — sin tipos del SDK en la firma.
  ///
  /// Si [availability] no es `configured`, la implementación debe
  /// devolver un placeholder honesto (sin tiles falsos).
  Widget buildViewport({
    required List<PlaceResult> places,
    double? initialLatitude,
    double? initialLongitude,
    double zoom = 12,
    void Function(PlaceResult place)? onMarkerTap,
    bool interactive = true,
  });
}
