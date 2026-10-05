import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/data/datasources/local/itinerary/itinerary_local_datasource.dart';
import 'package:travel_ready/data/models/itinerary/itinerary_item_model.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/entities/itinerary/place_snapshot.dart';

void main() {
  late Database db;
  late ItineraryLocalDataSource dataSource;

  ItineraryItemModel item({
    String id = 'it-1',
    String tripId = 'trip-001',
    String day = '2025-07-15',
    int start = 600,
    int? end,
    String title = 'Visita',
    ItineraryCategory category = ItineraryCategory.sightseeing,
    int order = 0,
    PlaceSnapshot? place,
  }) =>
      ItineraryItemModel(
        id: id,
        tripId: tripId,
        day: DateTime.parse(day),
        startMinutes: start,
        endMinutes: end,
        title: title,
        category: category,
        orderIndex: order,
        place: place,
      );

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Base en memoria por test: cero residuo entre ejecuciones y
    // sin contención sobre el fichero travelready.db compartido.
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dataSource = ItineraryLocalDataSource(openDatabase: () async => db);
  });

  tearDown(() async {
    dataSource.dispose();
    await db.close();
  });

  test('creates the table lazily and persists an item round-trip', () async {
    await dataSource.createItem(item(end: 720, title: 'Museo del Prado'));
    final items = await dataSource.getItems('trip-001');
    expect(items, hasLength(1));
    expect(items.single.title, 'Museo del Prado');
    expect(items.single.startMinutes, 600);
    expect(items.single.endMinutes, 720);
    expect(items.single.category, ItineraryCategory.sightseeing);
  });

  test('orders by day, then start time, then order index', () async {
    await dataSource.createItem(item(id: 'a', day: '2025-07-16', start: 540));
    await dataSource.createItem(item(id: 'b', day: '2025-07-15', start: 700));
    await dataSource.createItem(
        item(id: 'c', day: '2025-07-15', start: 600, order: 1));
    await dataSource.createItem(
        item(id: 'd', day: '2025-07-15', start: 600, order: 0));

    final items = await dataSource.getItems('trip-001');
    expect(items.map((i) => i.id), ['d', 'c', 'b', 'a']);
  });

  test('isolates items per trip', () async {
    await dataSource.createItem(item(id: 'a', tripId: 'trip-001'));
    await dataSource.createItem(item(id: 'b', tripId: 'trip-002'));
    expect((await dataSource.getItems('trip-001')).map((i) => i.id), ['a']);
    expect((await dataSource.getItems('trip-002')).map((i) => i.id), ['b']);
  });

  test('updates and deletes items', () async {
    await dataSource.createItem(item(id: 'a', title: 'Antes'));
    await dataSource.updateItem(item(id: 'a', title: 'Después'));
    expect((await dataSource.getItems('trip-001')).single.title, 'Después');

    await dataSource.deleteItem('a');
    expect(await dataSource.getItems('trip-001'), isEmpty);
  });

  test('drops provider identifiers and photo references from snapshots',
      () async {
    const place = PlaceSnapshot(
      providerId: 'prov-1',
      photoReference: 'photo-ref-1',
      name: 'Museo del Prado',
      address: 'Madrid',
      websiteUri: 'https://www.museodelprado.es',
      openingHoursText: 'L–S 10:00–20:00',
      priceLevelLabel: '€€',
    );
    await dataSource.createItem(item(id: 'a', place: place));
    final saved = (await dataSource.getItems('trip-001')).single.place!;
    expect(saved.providerId, isNull);
    expect(saved.photoReference, isNull);
    expect(saved.name, place.name);
    expect(saved.websiteUri, place.websiteUri);
  });

  test('reorderItems persists order_index for the day', () async {
    await dataSource.createItem(item(id: 'a', order: 0));
    await dataSource.createItem(item(id: 'b', order: 1));
    await dataSource.createItem(item(id: 'c', order: 2));

    await dataSource.reorderItems('trip-001', ['c', 'a', 'b']);

    final items = await dataSource.getItems('trip-001');
    expect(items.map((i) => i.id), ['c', 'a', 'b']);
  });

  test('watchItems emits on create and delete', () async {
    final snapshots = StreamIterator(dataSource.watchItems('trip-001'));
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext().timeout(const Duration(seconds: 2)),
        isTrue);
    expect(snapshots.current, isEmpty);

    await dataSource.createItem(item(id: 'a'));
    expect(await snapshots.moveNext().timeout(const Duration(seconds: 2)),
        isTrue);
    expect(snapshots.current.single.id, 'a');

    await dataSource.deleteItem('a');
    expect(await snapshots.moveNext().timeout(const Duration(seconds: 2)),
        isTrue);
    expect(snapshots.current, isEmpty);
  });
}
