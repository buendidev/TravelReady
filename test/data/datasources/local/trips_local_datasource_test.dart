import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';

import '../../../helpers/packing_list_fixture.dart';

void main() {
  late DatabaseHelper database;
  late TripsLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = DatabaseHelper();
    await database.deleteDatabase();
    dataSource = TripsLocalDataSource(database: database);
  });

  tearDown(() async {
    dataSource.dispose();
    await database.close();
    await database.deleteDatabase();
  });

  test('looks up a packing list by ID without requiring its trip ID', () async {
    await insertPackingListFixture(
      database: database,
      dataSource: dataSource,
    );

    final list = await dataSource.getPackingListById('list-001');

    expect(list.id, 'list-001');
    expect(list.tripId, 'trip-001');
    expect(dataSource.getPackingListById('unknown-list'),
        throwsA(isA<ServerException>()));
  });

  test('toggling an item emits its trip packing lists with the updated item',
      () async {
    await insertPackingListFixture(
      database: database,
      dataSource: dataSource,
      includeItem: true,
    );
    final snapshots = StreamIterator(dataSource.watchPackingLists('trip-001'));
    addTearDown(snapshots.cancel);

    expect(
        await snapshots.moveNext().timeout(const Duration(seconds: 1)), isTrue);
    final initialItem = snapshots.current
        .firstWhere((list) => list.id == 'list-001')
        .items
        .firstWhere((item) => item.id == 'item-004');
    expect(initialItem.isPacked, isFalse);

    await dataSource.toggleItemPacked('item-004', true);

    expect(
        await snapshots.moveNext().timeout(const Duration(seconds: 1)), isTrue);
    final updatedItem = snapshots.current
        .firstWhere((list) => list.id == 'list-001')
        .items
        .firstWhere((item) => item.id == 'item-004');
    expect(updatedItem.isPacked, isTrue);
  });
}
