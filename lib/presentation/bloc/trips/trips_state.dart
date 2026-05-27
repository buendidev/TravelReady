part of 'trips_bloc.dart';

sealed class TripsState extends Equatable {
  const TripsState();
  @override List<Object?> get props => [];
}

final class TripsInitial extends TripsState {
  const TripsInitial();
}
final class TripsLoading extends TripsState {
  const TripsLoading();
}
final class TripsReady extends TripsState {
  final List<Trip> trips;
  const TripsReady(this.trips);
  @override List<Object> get props => [trips];
}
final class TripsError extends TripsState {
  final String message;
  const TripsError(this.message);
  @override List<Object> get props => [message];
}
