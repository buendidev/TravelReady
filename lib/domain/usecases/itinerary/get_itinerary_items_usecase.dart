import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/itinerary/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Caso de uso: obtener las entradas de itinerario de un viaje.
class GetItineraryItemsUseCase {
  final ItineraryRepository _repository;

  GetItineraryItemsUseCase(this._repository);

  Future<Either<Failure, List<ItineraryItem>>> call(String tripId) =>
      _repository.getItems(tripId);
}
