import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../entities/itinerary/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Caso de uso: añadir una entrada al itinerario de un viaje.
class AddItineraryItemUseCase {
  final ItineraryRepository _repository;

  AddItineraryItemUseCase(this._repository);

  Future<Either<Failure, ItineraryItem>> call(ItineraryItem item) =>
      _repository.addItem(item);
}
