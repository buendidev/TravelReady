import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/data/datasources/local/trips_local_datasource.dart';
import 'package:travel_ready/data/repositories/trips_repository_impl.dart';

import '../../helpers/packing_list_fixture.dart';

void main() {
  late DatabaseHelper database;
  late TripsLocalDataSource dataSource;
  late PackingRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = DatabaseHelper();
    await database.deleteDatabase();
    dataSource = TripsLocalDataSource(database: database);
    repository = PackingRepositoryImpl(local: dataSource);
  });

  tearDown(() async {
    dataSource.dispose();
    await database.close();
    await database.deleteDatabase();
  });

  test('looks up a persisted packing list by ID regardless of its trip ID',
      () async {
    await insertPackingListFixture(
      database: database,
      dataSource: dataSource,
    );

    final found = await repository.getListById('list-001');
    final missing = await repository.getListById('unknown-list');

    expect(found.isRight(), isTrue);
    expect(found.getOrElse((_) => throw StateError('Expected packing list')).id,
        'list-001');
    expect(
        found
            .getOrElse((_) => throw StateError('Expected packing list'))
            .tripId,
        'trip-001');
    expect(missing.isLeft(), isTrue);
    expect(
        missing.swap().getOrElse((_) => throw StateError('Expected failure')),
        isA<ServerFailure>());
  });
}
