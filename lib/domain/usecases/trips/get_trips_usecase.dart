import 'package:fpdart/fpdart.dart';

import '../../entities/trip.dart';
import '../../repositories/trips_repository.dart';
import '../../../core/errors/failures.dart';

/// Caso de uso: Obtener todos los viajes de un usuario.
class GetTripsUseCase {
  final TripsRepository _repository;

  GetTripsUseCase(this._repository);

  Future<Either<Failure, List<Trip>>> call(String userId) {
    return _repository.getTrips(userId);
  }
}
