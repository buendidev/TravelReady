import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/itinerary_repository.dart';

/// Caso de uso: eliminar una entrada de itinerario.
class DeleteItineraryItemUseCase {
  final ItineraryRepository _repository;

  DeleteItineraryItemUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String itemId) =>
      _repository.deleteItem(itemId);
}
