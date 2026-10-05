import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';
import 'package:travel_ready/data/models/packing_item_model.dart';
import 'package:travel_ready/data/models/trip_model.dart';
import 'package:travel_ready/domain/entities/packing_item.dart';
import 'package:travel_ready/domain/entities/trip.dart';

const _userId = 'user-001';
const _tripId = 'trip-001';
const _listId = 'list-001';
const _itemId = 'item-004';
final _createdAt = DateTime.utc(2026, 4, 14);

Future<void> insertPackingListFixture({
  required DatabaseHelper database,
  required TripsLocalDataSource dataSource,
  bool includeItem = false,
}) async {
  await database.insert(DatabaseHelper.tableUsers, {
    'id': _userId,
    'name': 'Test User',
    'email': 'user-001@example.test',
  });
  await dataSource.createTrip(TripModel(
    id: _tripId,
    userId: _userId,
    name: 'Test trip',
    destination: 'Test destination',
    startDate: _createdAt,
    endDate: _createdAt.add(const Duration(days: 1)),
    tripType: TripType.city,
    createdAt: _createdAt,
  ));
  await dataSource.createPackingList(PackingListModel(
    id: _listId,
    tripId: _tripId,
    userId: _userId,
    name: 'Test packing list',
    createdAt: _createdAt,
    items: includeItem
        ? const [
            PackingItemModel(
              id: _itemId,
              listId: _listId,
              tripId: _tripId,
              userId: _userId,
              name: 'Test item',
              category: PackingCategory.other,
            ),
          ]
        : const [],
  ));
}
