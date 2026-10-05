import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/itinerary_repository.dart';

/// Caso de uso: persistir el orden de las entradas de un día.
class ReorderItineraryItemsUseCase {
  final ItineraryRepository _repository;

  ReorderItineraryItemsUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String tripId, List<String> orderedIds) =>
      _repository.reorderItems(tripId, orderedIds);
}
