import '../../domain/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.destination,
    required super.startDate,
    required super.endDate,
    super.transport,
    super.tripType,
    super.activities,
    super.progress,
    required super.createdAt,
    super.notes,
  });

  // ── SQLite (fromMap/toMap) ──────────────────────────────────────────────

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id:          map['id']          as String,
      userId:      map['user_id']     as String? ?? '',
      name:        map['name']        as String? ?? '',
      destination: map['destination'] as String? ?? '',
      startDate:   DateTime.parse(map['start_date'] as String),
      endDate:     DateTime.parse(map['end_date']   as String),
      transport:   const [],  // Se carga separadamente
      tripType:    _parseTripType(map['trip_type']   as String?),
      activities:  const [],  // Se carga separadamente
      progress:    map['progress']    as int? ?? 0,
      createdAt:   map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      notes:       map['notes']       as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'user_id':     userId,
    'name':        name,
    'destination': destination,
    'start_date':  startDate.toIso8601String(),
    'end_date':    endDate.toIso8601String(),
    'trip_type':   tripType.name,
    'progress':    progress,
    'created_at':  createdAt.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  // ── Legacy: mantener compatibilidad temporal ───────────────────────────
  factory TripModel.fromMapWithRelations(
    Map<String, dynamic> map, {
    List<TransportType> transport = const [],
    List<String> activities = const [],
  }) {
    return TripModel(
      id:          map['id']          as String,
      userId:      map['user_id']     as String? ?? '',
      name:        map['name']        as String? ?? '',
      destination: map['destination'] as String? ?? '',
      startDate:   DateTime.parse(map['start_date'] as String),
      endDate:     DateTime.parse(map['end_date']   as String),
      transport:   transport,
      tripType:    _parseTripType(map['trip_type']   as String?),
      activities:  activities,
      progress:    map['progress']    as int? ?? 0,
      createdAt:   map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      notes:       map['notes']       as String?,
    );
  }

  static TripModel fromEntity(Trip trip) => TripModel(
    id:          trip.id,
    userId:      trip.userId,
    name:        trip.name,
    destination: trip.destination,
    startDate:   trip.startDate,
    endDate:     trip.endDate,
    transport:   trip.transport,
    tripType:    trip.tripType,
    activities:  trip.activities,
    progress:    trip.progress,
    createdAt:   trip.createdAt,
    notes:       trip.notes,
  );

  /// Override necesario para que createTrip pueda copiar con nuevo id.
  @override
  TripModel copyWith({
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
  }) => TripModel(
    id:          id          ?? this.id,
    userId:      userId      ?? this.userId,
    name:        name        ?? this.name,
    destination: destination ?? this.destination,
    startDate:   startDate   ?? this.startDate,
    endDate:     endDate     ?? this.endDate,
    transport:   transport   ?? this.transport,
    tripType:    tripType    ?? this.tripType,
    activities:  activities  ?? this.activities,
    progress:    progress    ?? this.progress,
    createdAt:   createdAt   ?? this.createdAt,
    notes:       notes       ?? this.notes,
  );

  // ── Helpers ───────────────────────────────────────────────────────────

  static TripType _parseTripType(String? value) =>
      TripType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => TripType.city,
      );
}
