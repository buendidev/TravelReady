import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';

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

  test('toggling an item emits its trip packing lists with the updated item', () async {
    final snapshots = StreamIterator(dataSource.watchPackingLists('trip-001'));
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext().timeout(const Duration(seconds: 1)), isTrue);
    final initialItem = snapshots.current
        .firstWhere((list) => list.id == 'list-001')
        .items
        .firstWhere((item) => item.id == 'item-004');
    expect(initialItem.isPacked, isFalse);

    await dataSource.toggleItemPacked('item-004', true);

    expect(await snapshots.moveNext().timeout(const Duration(seconds: 1)), isTrue);
    final updatedItem = snapshots.current
        .firstWhere((list) => list.id == 'list-001')
        .items
        .firstWhere((item) => item.id == 'item-004');
    expect(updatedItem.isPacked, isTrue);
  });
}
