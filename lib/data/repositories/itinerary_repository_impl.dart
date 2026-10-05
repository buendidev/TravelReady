import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../../core/security/crypto_service.dart';
import '../../domain/entities/itinerary/itinerary_item.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/local/itinerary/itinerary_local_datasource.dart';
import '../models/itinerary/itinerary_item_model.dart';

/// Implementación del repositorio de itinerarios sobre SQLite local.
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryLocalDataSource _local;

  ItineraryRepositoryImpl({required ItineraryLocalDataSource local})
      : _local = local;

  @override
  Future<Either<Failure, List<ItineraryItem>>> getItems(String tripId) async {
    try {
      return Right(await _local.getItems(tripId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ItineraryItem>>> watchItems(String tripId) =>
      _local.watchItems(tripId).map<Either<Failure, List<ItineraryItem>>>(
          (items) => Right(items));

  @override
  Future<Either<Failure, ItineraryItem>> addItem(ItineraryItem item) async {
    try {
      final id = CryptoService.generateUuid();
      final created =
          await _local.createItem(ItineraryItemModel.fromEntity(item)
              .copyWith(id: id));
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ItineraryItem>> updateItem(ItineraryItem item) async {
    try {
      final updated =
          await _local.updateItem(ItineraryItemModel.fromEntity(item));
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(String itemId) async {
    try {
      await _local.deleteItem(itemId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderItems(
      String tripId, List<String> orderedIds) async {
    try {
      await _local.reorderItems(tripId, orderedIds);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
