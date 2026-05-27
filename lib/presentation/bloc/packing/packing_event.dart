part of 'packing_bloc.dart';

sealed class PackingEvent extends Equatable {
  const PackingEvent();
  @override List<Object?> get props => [];
}

final class PackingListsLoaded extends PackingEvent {
  final String tripId;
  const PackingListsLoaded({required this.tripId});
  @override List<Object> get props => [tripId];
}

final class PackingListCreated extends PackingEvent {
  final String tripId, name;
  const PackingListCreated({required this.tripId, required this.name});
  @override List<Object> get props => [tripId, name];
}

final class PackingListDeleted extends PackingEvent {
  final String listId, tripId;
  const PackingListDeleted({required this.listId, required this.tripId});
  @override List<Object> get props => [listId];
}

final class PackingItemAdded extends PackingEvent {
  final String listId, tripId, name;
  final PackingCategory category;
  final int quantity;
  const PackingItemAdded({
    required this.listId, required this.tripId, required this.name,
    this.category = PackingCategory.other, this.quantity = 1,
  });
  @override List<Object> get props => [listId, name, category];
}

final class PackingItemToggled extends PackingEvent {
  final PackingItem item;
  const PackingItemToggled(this.item);
  @override List<Object> get props => [item.id];
}

/// Usa el item completo (necesita tripId + listId para Firestore).
final class PackingItemDeleted extends PackingEvent {
  final PackingItem item;
  const PackingItemDeleted(this.item);
  @override List<Object> get props => [item.id];
}

