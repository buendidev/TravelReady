import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/itinerary/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Caso de uso: actualizar una entrada de itinerario.
class UpdateItineraryItemUseCase {
  final ItineraryRepository _repository;

  UpdateItineraryItemUseCase(this._repository);

  Future<Either<Failure, ItineraryItem>> call(ItineraryItem item) =>
      _repository.updateItem(item);
}
