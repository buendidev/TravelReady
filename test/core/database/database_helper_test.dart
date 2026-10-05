import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/data/datasources/local/weather_cache_datasource.dart';
import 'package:travel_ready/data/models/weather_model.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabase db;
  late List<String> statements;
  setUp(() {
    db = MockDatabase();
    statements = [];
    when(() => db.execute(any())).thenAnswer((invocation) async {
      statements.add(invocation.positionalArguments.first as String);
    });
  });

  test(
      'v1 to v2 only adds keyed weather table without altering existing tables',
      () async {
    await DatabaseHelper.upgradeSchema(db, 1, 2);
    expect(statements, hasLength(1));
    final sql = statements.single.toLowerCase();
    expect(sql, contains('create table ${DatabaseHelper.tableWeatherCache}'));
    expect(sql, contains('location_key text primary key'));
    expect(sql, contains('weather_json text not null'));
    expect(sql, contains('retrieved_at text not null'));
    expect(sql, isNot(contains('drop ')));
    expect(sql, isNot(contains('alter ')));
  });

  test('upgrade crossing v2 still creates only the cache table', () async {
    await DatabaseHelper.upgradeSchema(db, 1, 3);
    expect(statements, hasLength(1));
    expect(statements.single,
        contains('CREATE TABLE ${DatabaseHelper.tableWeatherCache}'));
  });

  test(
      'real v1 file upgrades to v2 preserving trip and packing rows, then reopens cached weather',
      () async {
    sqfliteFfiInit();
    // Keep test-generated files inside the authorized build directory.
    final directory =
        Directory('build/woc1_sqlite_${DateTime.now().microsecondsSinceEpoch}');
    await directory.create(recursive: true);
    final path = '${directory.path}/travelready.db';
    final factory = databaseFactoryFfi;

    // Reproduce the relevant v1 table definitions; no weather table exists yet.
    final v1 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute('''CREATE TABLE ${DatabaseHelper.tableTrips} (
        id VARCHAR(36) PRIMARY KEY, user_id VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL, destination VARCHAR(200) NOT NULL,
        start_date TEXT NOT NULL, end_date TEXT NOT NULL
      )''');
              await db
                  .execute('''CREATE TABLE ${DatabaseHelper.tablePackingItems} (
        id VARCHAR(36) PRIMARY KEY, list_id VARCHAR(36) NOT NULL,
        trip_id VARCHAR(36) NOT NULL, user_id VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL
      )''');
            }));
    await v1.insert(DatabaseHelper.tableTrips, {
      'id': 'trip-legacy',
      'user_id': 'usr-legacy',
      'name': 'Existing trip',
      'destination': 'Madrid',
      'start_date': '2026-04-01',
      'end_date': '2026-04-04',
    });
    await v1.insert(DatabaseHelper.tablePackingItems, {
      'id': 'item-legacy',
      'list_id': 'list-legacy',
      'trip_id': 'trip-legacy',
      'user_id': 'usr-legacy',
      'name': 'Passport',
    });
    await v1.close();

    Future<Database> openV2() => factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2, onUpgrade: DatabaseHelper.upgradeSchema));
    final upgraded = await openV2();
    expect(
        (await upgraded.rawQuery('PRAGMA user_version')).single['user_version'],
        2);
    expect((await upgraded.query(DatabaseHelper.tableTrips)).single['name'],
        'Existing trip');
    expect(
        (await upgraded.query(DatabaseHelper.tablePackingItems)).single['name'],
        'Passport');

    final cache = WeatherCacheDataSource(openDatabase: () async => upgraded);
    final retrievedAt = DateTime.utc(2026, 4, 2, 10, 30);
    const weather = WeatherModel(
      city: 'Madrid',
      country: 'ES',
      tempCelsius: 22.5,
      feelsLike: 21,
      tempMin: 18,
      tempMax: 25,
      description: 'clear',
      iconCode: '01d',
      humidity: 45,
      windSpeed: 3.2,
      visibility: 10000,
    );
    await cache.saveByCity('Madrid', weather, retrievedAt: retrievedAt);
    await upgraded.close();

    final reopened = await openV2();
    final persisted =
        WeatherCacheDataSource(openDatabase: () async => reopened);
    expect((await persisted.getByCity(' madrid '))?.weather.tempCelsius, 22.5);
    expect((await persisted.getByCity('MADRID'))?.retrievedAt, retrievedAt);
    expect(await persisted.getByCity('Barcelona'), isNull);
    expect((await reopened.query(DatabaseHelper.tableTrips)).single['name'],
        'Existing trip');
    expect(
        (await reopened.query(DatabaseHelper.tablePackingItems)).single['name'],
        'Passport');
    await reopened.close();
  });

  test('fresh production schema file contains tables but no seeded rows',
      () async {
    sqfliteFfiInit();
    final directory =
        Directory('build/prf2_sqlite_${DateTime.now().microsecondsSinceEpoch}');
    await directory.create(recursive: true);
    final path = '${directory.path}/travelready.db';
    final factory = databaseFactoryFfi;

    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: DatabaseHelper.createSchema,
      ),
    );

    final tables = [
      DatabaseHelper.tableUsers,
      DatabaseHelper.tableTrips,
      DatabaseHelper.tableTripTransport,
      DatabaseHelper.tableTripActivities,
      DatabaseHelper.tablePackingLists,
      DatabaseHelper.tablePackingItems,
      DatabaseHelper.tableChats,
      DatabaseHelper.tableChatMembers,
      DatabaseHelper.tableMessages,
      DatabaseHelper.tableSessions,
      DatabaseHelper.tableWeatherCache,
    ];
    for (final table in tables) {
      expect(await database.query(table), isEmpty,
          reason: '$table must start empty');
    }

    await database.close();
  });

  test('no migration runs when upgrade does not cross schema v2', () async {
    await DatabaseHelper.upgradeSchema(db, 2, 3);
    expect(statements, isEmpty);
  });
}
