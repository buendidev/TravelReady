import 'package:equatable/equatable.dart';

import 'place_snapshot.dart';

/// Categorías de una entrada de itinerario.
enum ItineraryCategory { sightseeing, food, transport, lodging, activity, other }

/// Entidad pura de dominio: entrada de itinerario de un viaje.
///
/// [day] se normaliza a medianoche local. Las horas se guardan como
/// minutos desde medianoche ([startMinutes], [endMinutes]) para no
/// depender de Flutter ni de zonas horarias en la capa de dominio.
class ItineraryItem extends Equatable {
  final String id;
  final String tripId;

  /// Día de la entrada (fecha sin hora).
  final DateTime day;

  /// Minutos desde medianoche (0–1439).
  final int startMinutes;
  final int? endMinutes;

  final String title;
  final ItineraryCategory category;
  final String? notes;

  /// Orden dentro del día.
  final int orderIndex;

  /// Snapshot provider-neutral del lugar asociado, si existe.
  final PlaceSnapshot? place;

  const ItineraryItem({
    required this.id,
    required this.tripId,
    required this.day,
    required this.startMinutes,
    this.endMinutes,
    required this.title,
    this.category = ItineraryCategory.other,
    this.notes,
    this.orderIndex = 0,
    this.place,
  });

  ItineraryItem copyWith({
    String? id,
    String? tripId,
    DateTime? day,
    int? startMinutes,
    int? endMinutes,
    String? title,
    ItineraryCategory? category,
    String? notes,
    int? orderIndex,
    PlaceSnapshot? place,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      day: day ?? this.day,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      title: title ?? this.title,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      place: place ?? this.place,
    );
  }

  @override
  List<Object?> get props =>
      [id, tripId, day, startMinutes, endMinutes, title, category, orderIndex];
}
