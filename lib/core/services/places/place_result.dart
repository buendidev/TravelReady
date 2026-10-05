import 'package:equatable/equatable.dart';

import '../../../domain/entities/itinerary/place_snapshot.dart';
import 'place_category.dart';

/// Resultado de búsqueda de un lugar, provider-neutral.
/// Es la frontera anti-corrupción entre un proveedor (Google Places,
/// fixtures, etc.) y el dominio: solo estos campos cruzan la barrera.
class PlaceResult extends Equatable {
  /// ID opaco del proveedor (nullable en fixtures/manuales).
  final String? providerId;
  final String name;
  final PlaceCategory category;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photoReference;

  /// URL oficial — destino del handoff externo con url_launcher.
  final String? websiteUri;

  /// Horarios en texto, indicativos (pueden estar incompletos).
  final String? openingHoursText;

  /// Etiqueta indicativa de precio (p. ej. '€€'). No es un precio real.
  final String? priceLevelLabel;

  /// Descripción corta mostrada en UI. NO se persiste en el snapshot
  /// (contenido del proveedor, retención por revisar).
  final String? shortDescription;

  const PlaceResult({
    this.providerId,
    required this.name,
    this.category = PlaceCategory.other,
    this.address,
    this.latitude,
    this.longitude,
    this.photoReference,
    this.websiteUri,
    this.openingHoursText,
    this.priceLevelLabel,
    this.shortDescription,
  });

  /// Convierte el resultado en el snapshot persistible.
  /// La frontera de retención se aplica aquí: los identificadores y
  /// referencias de fotos del proveedor, así como contenido sujeto a
  /// política de retención, nunca cruzan al almacenamiento local.
  PlaceSnapshot toSnapshot() => PlaceSnapshot(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        websiteUri: websiteUri,
        openingHoursText: openingHoursText,
        priceLevelLabel: priceLevelLabel,
      );

  @override
  List<Object?> get props => [
        providerId, name, category, address, latitude, longitude,
        photoReference, websiteUri, openingHoursText, priceLevelLabel,
      ];
}
