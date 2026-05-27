import 'package:fpdart/fpdart.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/packing_item.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/security/crypto_service.dart';
import '../datasources/local/trips_local_datasource.dart';
import '../models/trip_model.dart';
import '../models/packing_item_model.dart';

/// Implementación del repositorio de viajes con SQLite local.
/// Reemplaza Firestore + Hive por una única base de datos SQL.
class TripsRepositoryImpl implements TripsRepository {
  final TripsLocalDataSource _local;

  TripsRepositoryImpl({
    required TripsLocalDataSource local,
  })  : _local = local;

  // ── TRIPS ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Trip>>> getTrips(String userId) async {
    try {
      final trips = await _local.getTrips(userId);
      return Right(trips);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Stream<Either<Failure, List<Trip>>> watchTrips(String userId) =>
      _local.watchTrips(userId).map<Either<Failure, List<Trip>>>((trips) {
        return Right<Failure, List<Trip>>(trips);
      });

  @override
  Future<Either<Failure, Trip>> getTripById(String tripId) async {
    try { return Right(await _local.getTripById(tripId)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Trip>> createTrip(Trip trip) async {
    try {
      final tripId = CryptoService.generateUuid();
      final tripWithId = TripModel.fromEntity(trip).copyWith(id: tripId);
      final created = await _local.createTrip(tripWithId);
      return Right(created);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Trip>> updateTrip(Trip trip) async {
    try {
      final updated = await _local.updateTrip(TripModel.fromEntity(trip));
      return Right(updated);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> deleteTrip(String tripId) async {
    try {
      await _local.deleteTrip(tripId);
      return const Right(unit);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }
}

// ── PackingRepositoryImpl ─────────────────────────────────────────────────────

class PackingRepositoryImpl implements PackingRepository {
  final TripsLocalDataSource _local;
  PackingRepositoryImpl({required TripsLocalDataSource local})
      : _local = local;

  @override
  Future<Either<Failure, List<PackingList>>> getLists(String tripId) async {
    try { return Right(await _local.getPackingLists(tripId)); }
    on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PackingList>> getListById(String listId) async {
    // En SQLite buscamos en todas las listas
    try {
      final lists = await _local.getPackingLists(''); // No filtra por trip
      final list = lists.firstWhere((l) => l.id == listId, orElse: () => throw const ServerException('Lista no encontrada'));
      return Right(list);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PackingList>> createList(PackingList list) async {
    try {
      final listId = CryptoService.generateUuid();
      final listWithId = PackingListModel.fromEntity(list).copyWith(id: listId);
      final m = await _local.createPackingList(listWithId);
      return Right(m);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PackingList>> updateList(PackingList list) async {
    try {
      final m = await _local.updatePackingList(PackingListModel.fromEntity(list));
      return Right(m);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> deleteList(String listId) async {
    try {
      await _local.deletePackingList(listId);
      return const Right(unit);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PackingItem>> addItem(PackingItem item) async {
    try {
      final itemId = CryptoService.generateUuid();
      final itemWithId = PackingItemModel.fromEntity(item).copyWith(id: itemId);
      final added = await _local.createPackingItem(itemWithId);
      return Right(added);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PackingItem>> updateItem(PackingItem item) async {
    try {
      final updated = await _local.updatePackingItem(PackingItemModel.fromEntity(item));
      return Right(updated);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(String itemId) async {
    try {
      await _local.deletePackingItem(itemId);
      return const Right(unit);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }

}
