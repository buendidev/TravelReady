import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/data/datasources/local/favorites_local_datasource.dart';
import 'package:travel_ready/data/models/recommendations/favorite_place_model.dart';

void main() {
  late Database db;
  late FavoritesLocalDataSource dataSource;

  FavoritePlaceModel favorite(
    String key, {
    String name = 'Museo del Prado',
    PlaceCategory category = PlaceCategory.museum,
    DateTime? createdAt,
  }) =>
      FavoritePlaceModel(
        key: key,
        name: name,
        category: category,
        address: 'C. de Ruiz de Alarcón 23, Madrid',
        latitude: 40.4138,
        longitude: -3.6921,
        websiteUri: 'https://www.museodelprado.es',
        openingHoursText: 'L–S 10:00–20:00',
        priceLevelLabel: '€€',
        createdAt: createdAt ?? DateTime.utc(2026, 10, 9, 12),
      );

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dataSource = FavoritesLocalDataSource(openDatabase: () async => db);
  });

  tearDown(() async {
    dataSource.dispose();
    if (db.isOpen) await db.close();
  });

  test('creates its tables lazily and round-trips every field', () async {
    final saved = favorite('k1');
    await dataSource.like(saved);

    final favorites = await dataSource.getFavorites();

    expect(favorites, hasLength(1));
    final loaded = favorites.single;
    expect(loaded.key, 'k1');
    expect(loaded.name, 'Museo del Prado');
    expect(loaded.category, PlaceCategory.museum);
    expect(loaded.address, saved.address);
    expect(loaded.latitude, 40.4138);
    expect(loaded.longitude, -3.6921);
    expect(loaded.websiteUri, saved.websiteUri);
    expect(loaded.openingHoursText, saved.openingHoursText);
    expect(loaded.priceLevelLabel, '€€');
    expect(loaded.createdAt, DateTime.utc(2026, 10, 9, 12));
  });

  test('coexists with a database that already has the central schema',
      () async {
    await DatabaseHelper.createReactionTables(db);

    await dataSource.like(favorite('k1'));

    expect(await dataSource.getFavorites(), hasLength(1));
  });

  test('lists favorites newest first', () async {
    await dataSource.like(favorite('old', createdAt: DateTime.utc(2026, 1, 1)));
    await dataSource.like(favorite('new', createdAt: DateTime.utc(2026, 6, 1)));
    await dataSource.like(favorite('mid', createdAt: DateTime.utc(2026, 3, 1)));

    expect((await dataSource.getFavorites()).map((f) => f.key),
        ['new', 'mid', 'old']);
  });

  test('breaks a same-instant tie by most recently written', () async {
    final instant = DateTime.utc(2026, 5, 5);
    await dataSource.like(favorite('first', createdAt: instant));
    await dataSource.like(favorite('second', createdAt: instant));

    expect((await dataSource.getFavorites()).map((f) => f.key),
        ['second', 'first']);
  });

  test('liking the same place twice keeps one row', () async {
    await dataSource.like(favorite('k1', name: 'Antes'));
    await dataSource.like(favorite('k1', name: 'Después'));

    final favorites = await dataSource.getFavorites();
    expect(favorites, hasLength(1));
    expect(favorites.single.name, 'Después');
  });

  group('mutual exclusion', () {
    test('liking a disliked place clears the dislike', () async {
      await dataSource.dislike('k1');

      await dataSource.like(favorite('k1'));

      expect(await db.query('place_dislikes'), isEmpty);
      expect((await dataSource.getFavorites()).map((f) => f.key), ['k1']);
    });

    test('disliking a favorite clears the favorite', () async {
      await dataSource.like(favorite('k1'));

      await dataSource.dislike('k1');

      expect(await dataSource.getFavorites(), isEmpty);
      expect((await db.query('place_dislikes')).single['place_key'], 'k1');
    });

    test('a place is never in both tables after any sequence of reactions',
        () async {
      for (final step in ['like', 'dislike', 'like', 'like', 'dislike']) {
        if (step == 'like') {
          await dataSource.like(favorite('k1'));
        } else {
          await dataSource.dislike('k1');
        }
        final liked = (await db.query('place_favorites')).length;
        final disliked = (await db.query('place_dislikes')).length;
        expect(liked + disliked, 1, reason: 'after $step');
      }
    });
  });

  group('dislikes store no venue data', () {
    test('the table has only the key and a timestamp', () async {
      await dataSource.dislike('k1');

      final columns = (await db.rawQuery('PRAGMA table_info(place_dislikes)'))
          .map((c) => c['name'])
          .toList();
      expect(columns, ['place_key', 'created_at']);
    });

    test('the persisted row does not contain the venue name', () async {
      await dataSource.like(favorite('k1', name: 'Secret Venue Name'));

      await dataSource.dislike('k1');

      final row = (await db.query('place_dislikes')).single;
      expect(row.keys.toSet(), {'place_key', 'created_at'});
      expect(row.values.map((v) => '$v').join(' '),
          isNot(contains('Secret Venue Name')));
    });
  });

  group('removing', () {
    test('removing a favorite is not a dislike', () async {
      await dataSource.like(favorite('k1'));

      await dataSource.removeFavorite('k1');

      expect(await dataSource.getFavorites(), isEmpty);
      expect(await db.query('place_dislikes'), isEmpty);
      expect(await dataSource.getReactedKeys(), isEmpty,
          reason: 'the place may appear in the feed again');
    });

    test('removing a dislike lets the place come back', () async {
      await dataSource.dislike('k1');

      await dataSource.removeDislike('k1');

      expect(await dataSource.getReactedKeys(), isEmpty);
    });

    test('clearing dislikes leaves the favorites untouched', () async {
      await dataSource.like(favorite('liked'));
      await dataSource.dislike('d1');
      await dataSource.dislike('d2');

      await dataSource.clearDislikes();

      expect(await db.query('place_dislikes'), isEmpty);
      expect((await dataSource.getFavorites()).map((f) => f.key), ['liked']);
    });
  });

  test('reacted keys are the union of likes and dislikes', () async {
    await dataSource.like(favorite('liked'));
    await dataSource.dislike('disliked');

    expect(await dataSource.getReactedKeys(), {'liked', 'disliked'});
  });

  test('watchFavorites emits on like, dislike and remove', () async {
    final snapshots = StreamIterator(dataSource.watchFavorites());
    addTearDown(snapshots.cancel);
    Future<List<String>> next() async {
      expect(await snapshots.moveNext().timeout(const Duration(seconds: 2)),
          isTrue);
      return snapshots.current.map((f) => f.key).toList();
    }

    expect(await next(), isEmpty);

    await dataSource.like(favorite('k1'));
    expect(await next(), ['k1']);

    await dataSource.dislike('k1');
    expect(await next(), isEmpty);

    await dataSource.like(favorite('k2'));
    expect(await next(), ['k2']);

    await dataSource.removeFavorite('k2');
    expect(await next(), isEmpty);
  });

  test('a damaged row is skipped instead of failing the whole list', () async {
    await dataSource.like(favorite('good'));
    await db.insert('place_favorites', {
      'place_key': 'damaged',
      'name': 'Broken',
      'category': 'museum',
      'created_at': 'not-a-date',
    });

    expect((await dataSource.getFavorites()).map((f) => f.key), ['good']);
  });

  test('an unknown stored category degrades to other', () async {
    await dataSource.like(favorite('k1'));
    await db.update('place_favorites', {'category': 'spaceport'});

    expect((await dataSource.getFavorites()).single.category,
        PlaceCategory.other);
  });

  test('a closed database surfaces a ServerException, never a raw error',
      () async {
    await db.close();

    expect(() => dataSource.getFavorites(), throwsA(isA<ServerException>()));
    expect(() => dataSource.like(favorite('k1')),
        throwsA(isA<ServerException>()));
    expect(() => dataSource.dislike('k1'), throwsA(isA<ServerException>()));
  });
}
