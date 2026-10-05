import 'package:equatable/equatable.dart';

/// Snapshot de lugar provider-neutral para itinerarios.
///
/// Solo almacena campos neutros que el usuario ve y elige guardar
/// (nombre, dirección, web oficial). Las referencias de proveedor
/// (`providerId`, `photoReference`) quedan aisladas aquí para poder
/// revisar políticas de retención/atribución antes de persistir datos
/// de un proveedor concreto (p. ej. Google Places).
class PlaceSnapshot extends Equatable {
  /// Identificador opaco del proveedor (p. ej. Place ID). Nullable:
  /// los items creados manualmente no tienen proveedor.
  final String? providerId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photoReference;

  /// URL oficial del lugar — destino del handoff externo vía url_launcher.
  final String? websiteUri;

  /// Texto de horarios, indicativo. Puede estar incompleto o desactualizado.
  final String? openingHoursText;

  /// Etiqueta indicativa de nivel de precio (p. ej. '€€'). No es un precio.
  final String? priceLevelLabel;

  const PlaceSnapshot({
    this.providerId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.photoReference,
    this.websiteUri,
    this.openingHoursText,
    this.priceLevelLabel,
  });

  @override
  List<Object?> get props => [
        providerId,
        name,
        address,
        latitude,
        longitude,
        photoReference,
        websiteUri,
        openingHoursText,
        priceLevelLabel,
      ];
}
