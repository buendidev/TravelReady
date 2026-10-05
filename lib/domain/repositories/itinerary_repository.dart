import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/itinerary/itinerary_item.dart';

/// Contrato del repositorio de itinerarios (offline-first, SQLite).
abstract class ItineraryRepository {
  /// Obtiene todas las entradas de un viaje, ordenadas por día/hora/orden.
  Future<Either<Failure, List<ItineraryItem>>> getItems(String tripId);

  /// Stream reactivo de las entradas de un viaje.
  Stream<Either<Failure, List<ItineraryItem>>> watchItems(String tripId);

  /// Añade una entrada. El id lo asigna la capa de datos.
  Future<Either<Failure, ItineraryItem>> addItem(ItineraryItem item);

  /// Actualiza una entrada existente.
  Future<Either<Failure, ItineraryItem>> updateItem(ItineraryItem item);

  /// Elimina una entrada.
  Future<Either<Failure, Unit>> deleteItem(String itemId);

  /// Persiste el orden de las entradas de un día ([orderedIds]).
  Future<Either<Failure, Unit>> reorderItems(
      String tripId, List<String> orderedIds);
}
