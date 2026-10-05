import 'package:fpdart/fpdart.dart';

import '../../errors/failures.dart';
import 'place_category.dart';
import 'place_result.dart';
import 'places_gateway.dart';

/// Gateway de demostración: devuelve fixtures locales deterministas.
///
/// - No usa red ni claves. `availability` es [PlacesAvailability.demo]
///   para que la UI etiquete los resultados como datos de ejemplo.
/// - Las URLs son sitios oficiales públicos conocidos (handoff externo).
/// - Simula un pequeño retardo para ejercitar el estado de loading.
class DemoPlacesGateway implements PlacesGateway {
  /// Retardo artificial de "búsqueda" (0 en tests si se desea inmediatez).
  final Duration latency;

  const DemoPlacesGateway({this.latency = const Duration(milliseconds: 350)});

  @override
  PlacesAvailability get availability => PlacesAvailability.demo;

  /// Los fixtures locales no requieren atribución de proveedor.
  @override
  String? get attributionText => null;

  @override
  Future<Either<Failure, List<PlaceResult>>> search({
    required String query,
    PlaceCategory? category,
    String? destinationHint,
    int limit = 20,
  }) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    final q = query.trim().toLowerCase();
    final results = _fixtures.where((p) {
      final matchQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.address ?? '').toLowerCase().contains(q) ||
          (destinationHint != null &&
              (p.address ?? '')
                  .toLowerCase()
                  .contains(destinationHint.toLowerCase()));
      final matchCategory = category == null || p.category == category;
      return matchQuery && matchCategory;
    }).toList();
    return Right(results.take(limit).toList());
  }

  /// Fixtures locales — lugares turísticos españoles con datos públicos
  /// aproximados. NO son resultados de un proveedor en vivo.
  static const _fixtures = <PlaceResult>[
    PlaceResult(
      providerId: 'demo-prado',
      name: 'Museo Nacional del Prado',
      category: PlaceCategory.museum,
      address: 'C. de Ruiz de Alarcón 23, Madrid',
      latitude: 40.4138, longitude: -3.6921,
      websiteUri: 'https://www.museodelprado.es',
      openingHoursText: 'L–S 10:00–20:00 · D 10:00–19:00',
      priceLevelLabel: '€€',
      shortDescription:
          'Pinacoteca estatal con Velázquez, Goya y El Bosco.',
    ),
    PlaceResult(
      providerId: 'demo-sagrada',
      name: 'Basílica de la Sagrada Família',
      category: PlaceCategory.monument,
      address: 'C. de Mallorca 401, Barcelona',
      latitude: 41.4036, longitude: 2.1744,
      websiteUri: 'https://sagradafamilia.org',
      openingHoursText: 'Todos los días 9:00–20:00',
      priceLevelLabel: '€€€',
      shortDescription: 'Obra maestra inacabada de Antoni Gaudí.',
    ),
    PlaceResult(
      providerId: 'demo-retiro',
      name: 'Parque de El Retiro',
      category: PlaceCategory.nature,
      address: 'Plaza de la Independencia 7, Madrid',
      latitude: 40.4153, longitude: -3.6845,
      websiteUri: 'https://www.madrid.es',
      openingHoursText: 'Todos los días 6:00–24:00',
      priceLevelLabel: 'Gratis',
      shortDescription:
          'Gran pulmón verde con el Estanque y el Palacio de Cristal.',
    ),
    PlaceResult(
      providerId: 'demo-alhambra',
      name: 'La Alhambra',
      category: PlaceCategory.monument,
      address: 'C. Real de la Alhambra, Granada',
      latitude: 37.1761, longitude: -3.5881,
      websiteUri: 'https://www.alhambra-patronato.es',
      openingHoursText: 'Todos los días 8:30–20:00',
      priceLevelLabel: '€€',
      shortDescription: 'Conjunto palaciego nazarí, Patrimonio UNESCO.',
    ),
    PlaceResult(
      providerId: 'demo-mercado',
      name: 'Mercado de San Miguel',
      category: PlaceCategory.food,
      address: 'Pl. de San Miguel, Madrid',
      latitude: 40.4154, longitude: -3.7090,
      websiteUri: 'https://mercadodesanmiguel.es',
      openingHoursText: 'Todos los días 10:00–0:00',
      priceLevelLabel: '€€',
      shortDescription: 'Mercado gourmet histórico junto a Plaza Mayor.',
    ),
    PlaceResult(
      providerId: 'demo-guggenheim',
      name: 'Museo Guggenheim Bilbao',
      category: PlaceCategory.museum,
      address: 'Abandoibarra Etorb. 2, Bilbao',
      latitude: 43.2687, longitude: -2.9340,
      websiteUri: 'https://www.guggenheim-bilbao.eus',
      openingHoursText: 'Ma–D 10:00–20:00 (L cerrado)',
      priceLevelLabel: '€€',
      shortDescription: 'Icono de titanio de Frank Gehry en la ría.',
    ),
    PlaceResult(
      providerId: 'demo-tapas',
      name: 'Casa Bonay — Barra',
      category: PlaceCategory.nightlife,
      address: 'Gran Via de les Corts Catalanes 700, Barcelona',
      latitude: 41.3955, longitude: 2.1640,
      websiteUri: 'https://www.hotelcasabonay.com',
      openingHoursText: 'Todos los días 18:00–1:00',
      priceLevelLabel: '€€',
      shortDescription: 'Vermuts y tapas de autor en el Eixample.',
    ),
    PlaceResult(
      providerId: 'demo-granada-hostal',
      name: 'Hostal Rodri',
      category: PlaceCategory.hotel,
      address: 'C. de la Cabeza 10, Granada',
      latitude: 37.1720, longitude: -3.5990,
      openingHoursText: 'Recepción 24 h',
      priceLevelLabel: '€',
      shortDescription: 'Hostal céntrico junto a la Catedral.',
    ),
  ];
}
