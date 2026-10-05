import '../../../domain/entities/itinerary/itinerary_item.dart';
import '../../../domain/entities/itinerary/place_snapshot.dart';

/// Modelo SQLite de [ItineraryItem]. El snapshot de lugar se guarda
/// aplanado en columnas `place_*` — solo campos neutros.
class ItineraryItemModel extends ItineraryItem {
  const ItineraryItemModel({
    required super.id,
    required super.tripId,
    required super.day,
    required super.startMinutes,
    super.endMinutes,
    required super.title,
    super.category,
    super.notes,
    super.orderIndex,
    super.place,
  });

  factory ItineraryItemModel.fromEntity(ItineraryItem e) =>
      ItineraryItemModel(
        id: e.id,
        tripId: e.tripId,
        day: e.day,
        startMinutes: e.startMinutes,
        endMinutes: e.endMinutes,
        title: e.title,
        category: e.category,
        notes: e.notes,
        orderIndex: e.orderIndex,
        place: e.place,
      );

  factory ItineraryItemModel.fromMap(Map<String, dynamic> m) {
    final hasPlace = m['place_name'] != null;
    return ItineraryItemModel(
      id: m['id'] as String,
      tripId: m['trip_id'] as String,
      day: DateTime.parse(m['day'] as String),
      startMinutes: m['start_minutes'] as int,
      endMinutes: m['end_minutes'] as int?,
      title: m['title'] as String,
      category: ItineraryCategory.values.firstWhere(
        (c) => c.name == m['category'],
        orElse: () => ItineraryCategory.other,
      ),
      notes: m['notes'] as String?,
      orderIndex: m['order_index'] as int? ?? 0,
      place: hasPlace
          ? PlaceSnapshot(
              name: m['place_name'] as String,
              address: m['place_address'] as String?,
              latitude: (m['place_lat'] as num?)?.toDouble(),
              longitude: (m['place_lng'] as num?)?.toDouble(),
              websiteUri: m['place_website'] as String?,
              openingHoursText: m['place_hours'] as String?,
              priceLevelLabel: m['place_price_label'] as String?,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trip_id': tripId,
        'day': DateTime(day.year, day.month, day.day).toIso8601String(),
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
        'title': title,
        'category': category.name,
        'notes': notes,
        'order_index': orderIndex,
        'place_name': place?.name,
        'place_address': place?.address,
        'place_lat': place?.latitude,
        'place_lng': place?.longitude,
        'place_website': place?.websiteUri,
        'place_hours': place?.openingHoursText,
        'place_price_label': place?.priceLevelLabel,
      };

  @override
  ItineraryItemModel copyWith({
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
  }) =>
      ItineraryItemModel(
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
