import 'package:equatable/equatable.dart';

/// Tipos de transporte soportados.
enum TransportType { plane, train, bus, car, ship, other }

/// Tipos de viaje para personalizar templates de equipaje.
enum TripType { beach, mountain, city, business, adventure, other }

/// Entidad pura de dominio: Viaje.
class Trip extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransportType> transport;
  final TripType tripType;
  final List<String> activities;
  final int progress; // 0–100
  final DateTime createdAt;
  final String? notes;

  const Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.transport = const [],
    this.tripType = TripType.city,
    this.activities = const [],
    this.progress = 0,
    required this.createdAt,
    this.notes,
  });

  /// Número de días del viaje.
  int get durationDays => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<TransportType>? transport,
    TripType? tripType,
    List<String>? activities,
    int? progress,
    DateTime? createdAt,
    String? notes,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transport: transport ?? this.transport,
      tripType: tripType ?? this.tripType,
      activities: activities ?? this.activities,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, destination, startDate, endDate];
}
