import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/domain/entities/trip.dart';

import '../../helpers/fake_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Trip entity', () {
    test('durationDays: 1 jul → 8 jul = 8 días', () {
      expect(tTrip.durationDays, 8);
    });

    test('durationDays: mismo día = 1', () {
      final oneDay = tTrip.copyWith(
        startDate: DateTime(2026, 7, 1),
        endDate:   DateTime(2026, 7, 1),
      );
      expect(oneDay.durationDays, 1);
    });

    test('equatable — trips con mismo id son iguales', () {
      final t1 = tTrip;
      final t2 = tTrip.copyWith(notes: 'diferente nota');
      expect(t1, equals(t2)); // notes no está en props
    });

    test('equatable — trips con distinto id son distintos', () {
      final t1 = tTrip;
      final t2 = tTrip.copyWith(id: 'otro_id');
      expect(t1, isNot(equals(t2)));
    });

    test('copyWith actualiza solo los campos indicados', () {
      final updated = tTrip.copyWith(name: 'Roma', progress: 75);
      expect(updated.name,     'Roma');
      expect(updated.progress, 75);
      expect(updated.id,       tTrip.id);
      expect(updated.userId,   tTrip.userId);
    });

    test('tripType por defecto es city', () {
      final t = Trip(
        id: 'x', userId: 'u', name: 'n', destination: 'd',
        startDate: DateTime(2026), endDate: DateTime(2026),
        createdAt: DateTime(2026),
      );
      expect(t.tripType, TripType.city);
    });

    test('transport por defecto está vacío', () {
      final t = Trip(
        id: 'x', userId: 'u', name: 'n', destination: 'd',
        startDate: DateTime(2026), endDate: DateTime(2026),
        createdAt: DateTime(2026),
      );
      expect(t.transport, isEmpty);
    });

    test('tTrip tiene transport=[plane]', () {
      expect(tTrip.transport, contains(TransportType.plane));
    });

    test('tTrip2 tiene tripType=beach', () {
      expect(tTrip2.tripType, TripType.beach);
    });
  });
}
