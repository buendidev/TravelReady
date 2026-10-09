import 'package:fpdart/fpdart.dart';

import '../entities/trip.dart';
import '../entities/packing_item.dart';
import '../../core/errors/failures.dart';

/// Contrato del repositorio de viajes.
abstract class TripsRepository {
  /// Obtiene todos los viajes del usuario (offline-first con SQLite local).
  Future<Either<Failure, List<Trip>>> getTrips(String userId);

  /// Stream de viajes en tiempo real (Firestore).
  Stream<Either<Failure, List<Trip>>> watchTrips(String userId);

  /// Obtiene un viaje por su ID.
  Future<Either<Failure, Trip>> getTripById(String tripId);

  /// Crea un nuevo viaje.
  Future<Either<Failure, Trip>> createTrip(Trip trip);

  /// Actualiza un viaje existente.
  Future<Either<Failure, Trip>> updateTrip(Trip trip);

  /// Elimina un viaje.
  Future<Either<Failure, Unit>> deleteTrip(String tripId);
}

/// Contrato del repositorio de listas de equipaje.
abstract class PackingRepository {
  /// Obtiene todas las listas de un viaje.
  Future<Either<Failure, List<PackingList>>> getLists(String tripId);

  /// Obtiene una lista por su ID.
  Future<Either<Failure, PackingList>> getListById(String listId);

  /// Crea una nueva lista de equipaje.
  Future<Either<Failure, PackingList>> createList(PackingList list);

  /// Actualiza una lista.
  Future<Either<Failure, PackingList>> updateList(PackingList list);

  /// Elimina una lista.
  Future<Either<Failure, Unit>> deleteList(String listId);

  /// Añade un artículo a la lista.
  Future<Either<Failure, PackingItem>> addItem(PackingItem item);

  /// Actualiza (o marca/desmarca) un artículo.
  Future<Either<Failure, PackingItem>> updateItem(PackingItem item);

  /// Elimina un artículo.
  Future<Either<Failure, Unit>> deleteItem(String itemId);

}
