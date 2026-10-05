part of 'itinerary_bloc.dart';

sealed class ItineraryState extends Equatable {
  const ItineraryState();
  @override
  List<Object?> get props => [];
}

final class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

final class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

final class ItineraryReady extends ItineraryState {
  final List<ItineraryItem> items;
  final String tripId;
  const ItineraryReady({required this.items, required this.tripId});
  @override
  List<Object?> get props => [items, tripId];
}

/// Confirma una mutación persistida para flujos que no observan la lista.
final class ItineraryMutationSucceeded extends ItineraryState {
  const ItineraryMutationSucceeded();
}

final class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);
  @override
  List<Object?> get props => [message];
}
