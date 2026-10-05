part of 'itinerary_bloc.dart';

sealed class ItineraryEvent extends Equatable {
  const ItineraryEvent();
  @override
  List<Object?> get props => [];
}

/// Suscribe al itinerario de un viaje.
final class ItineraryLoaded extends ItineraryEvent {
  final String tripId;
  const ItineraryLoaded({required this.tripId});
  @override
  List<Object?> get props => [tripId];
}

/// Añade una entrada (el bloc sanitiza; el id lo asigna el repo).
final class ItineraryItemAdded extends ItineraryEvent {
  final String tripId;
  final DateTime day;
  final int startMinutes;
  final int? endMinutes;
  final String title;
  final ItineraryCategory category;
  final String? notes;
  final PlaceSnapshot? place;

  const ItineraryItemAdded({
    required this.tripId,
    required this.day,
    required this.startMinutes,
    this.endMinutes,
    required this.title,
    this.category = ItineraryCategory.other,
    this.notes,
    this.place,
  });

  @override
  List<Object?> get props =>
      [tripId, day, startMinutes, endMinutes, title, category];
}

/// Actualiza una entrada existente.
final class ItineraryItemUpdated extends ItineraryEvent {
  final ItineraryItem item;
  const ItineraryItemUpdated({required this.item});
  @override
  List<Object?> get props => [item];
}

/// Elimina una entrada.
final class ItineraryItemDeleted extends ItineraryEvent {
  final String itemId;
  const ItineraryItemDeleted({required this.itemId});
  @override
  List<Object?> get props => [itemId];
}

/// Persiste el orden de las entradas de un día.
final class ItineraryItemsReordered extends ItineraryEvent {
  final String tripId;
  final List<String> orderedIds;
  const ItineraryItemsReordered(
      {required this.tripId, required this.orderedIds});
  @override
  List<Object?> get props => [tripId, orderedIds];
}
