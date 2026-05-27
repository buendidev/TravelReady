import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../entities/trip.dart';
import '../../repositories/trips_repository.dart';
import '../../../core/errors/failures.dart';

/// Parámetros para crear un viaje.
class CreateTripParams extends Equatable {
  final String userId;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final TripType tripType;
  final List<TransportType> transport;
  final List<String> activities;
  final String? notes;

  const CreateTripParams({
    required this.userId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.tripType = TripType.city,
    this.transport = const [],
    this.activities = const [],
    this.notes,
  });

  @override
  List<Object?> get props =>
      [userId, name, destination, startDate, endDate, tripType];
}

/// Caso de uso: Crear un nuevo viaje.
class CreateTripUseCase {
  final TripsRepository _repository;

  CreateTripUseCase(this._repository);

  Future<Either<Failure, Trip>> call(CreateTripParams params) {
    final trip = Trip(
      id: '', // El ID lo asigna Firestore
      userId: params.userId,
      name: params.name,
      destination: params.destination,
      startDate: params.startDate,
      endDate: params.endDate,
      tripType: params.tripType,
      transport: params.transport,
      activities: params.activities,
      notes: params.notes,
      createdAt: DateTime.now(),
    );
    return _repository.createTrip(trip);
  }
}
