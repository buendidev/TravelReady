part of 'trips_bloc.dart';

sealed class TripsEvent extends Equatable {
  const TripsEvent();
  @override List<Object?> get props => [];
}

final class TripsLoaded extends TripsEvent {
  final String userId;
  const TripsLoaded({required this.userId});
  @override List<Object> get props => [userId];
}

final class TripCreated extends TripsEvent {
  final String userId, name, destination;
  final DateTime startDate, endDate;
  final TripType tripType;
  final List<TransportType> transport;
  final List<String> activities;
  const TripCreated({
    required this.userId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.tripType = TripType.city,
    this.transport = const [],
    this.activities = const [],
  });
  @override List<Object> get props => [userId, name, destination, startDate];
}

final class TripDeleted extends TripsEvent {
  final String tripId, userId;
  const TripDeleted({required this.tripId, required this.userId});
  @override List<Object> get props => [tripId];
}

final class TripUpdated extends TripsEvent {
  final Trip trip;
  final String userId;
  const TripUpdated({required this.trip, required this.userId});
  @override List<Object> get props => [trip.id];
}
