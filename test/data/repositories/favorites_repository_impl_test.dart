import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/data/datasources/local/favorites_local_datasource.dart';
import 'package:travel_ready/data/repositories/favorites_repository_impl.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';

void main() {
  late Database db;
  late FavoritesLocalDataSource dataSource;
  late FavoritesRepositoryImpl repo;
  var clock = DateTime.utc(2026, 10, 9, 8);

  const prado = PlaceResult(
    providerId: 'prov-prado',
    photoReference: 'photo-prado',
    name: 'Museo Nacional del Prado',
    category: PlaceCategory.museum,
    address: 'C. de Ruiz de Alarcón 23, Madrid',
    latitude: 40.4138,
    longitude: -3.6921,
    websiteUri: 'https://www.museodelprado.es',
    openingHoursText: 'L–S 10:00–20:00',
    priceLevelLabel: '€€',
    shortDescription: 'Pinacoteca estatal.',
  );
  final pradoCard = RecommendedPlace.from(prado);

  T right<T>(Either<Failure, T> either) =>
      either.getOrElse((f) => fail('expected Right, got $f'));

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    clock = DateTime.utc(2026, 10, 9, 8);
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dataSource = FavoritesLocalDataSource(openDatabase: () async => db);
    repo = FavoritesRepositoryImpl(
        local: dataSource, now: () => clock = clock.add(const Duration(minutes: 1)));
  });

  tearDown(() async {
    dataSource.dispose();
    if (db.isOpen) await db.close();
  });

  test('like keeps the provider-neutral snapshot and drops provider data',
      () async {
    expect(await repo.like(pradoCard), const Right(unit));

    final favorite = right(await repo.getFavorites()).single;

    expect(favorite.key, placeKeyOf(prado));
    final shown = favorite.toPlaceResult();
    expect(shown.name, prado.name);
    expect(shown.category, PlaceCategory.museum);
    expect(shown.websiteUri, prado.websiteUri);
    expect(shown.priceLevelLabel, '€€');
    expect(shown.providerId, isNull);
    expect(shown.photoReference, isNull);
    expect(shown.shortDescription, isNull);
  });

  test('like stamps the injected clock, so ordering is deterministic',
      () async {
    await repo.like(RecommendedPlace.from(
        const PlaceResult(name: 'A', category: PlaceCategory.food, address: 'a')));
    await repo.like(RecommendedPlace.from(
        const PlaceResult(name: 'B', category: PlaceCategory.food, address: 'b')));

    final favorites = right(await repo.getFavorites());

    expect(favorites.map((f) => f.name), ['B', 'A']);
    expect(favorites.first.createdAt, DateTime.utc(2026, 10, 9, 8, 2));
  });

  test('dislike takes only a key, hides the place and removes a like',
      () async {
    await repo.like(pradoCard);

    expect(await repo.dislike(pradoCard.key), const Right(unit));

    expect(right(await repo.getFavorites()), isEmpty);
    expect(right(await repo.getReactedKeys()), {pradoCard.key});
  });

  test('like after dislike restores the favorite and drops the dislike',
      () async {
    await repo.dislike(pradoCard.key);

    await repo.like(pradoCard);

    expect(right(await repo.getFavorites()).map((f) => f.key), [pradoCard.key]);
    expect(await db.query('place_dislikes'), isEmpty);
  });

  test('removeFavorite frees the place; it is not a dislike', () async {
    await repo.like(pradoCard);

    expect(await repo.removeFavorite(pradoCard.key), const Right(unit));

    expect(right(await repo.getReactedKeys()), isEmpty);
  });

  test('removeDislike undoes a dislike', () async {
    await repo.dislike(pradoCard.key);

    expect(await repo.removeDislike(pradoCard.key), const Right(unit));

    expect(right(await repo.getReactedKeys()), isEmpty);
  });

  test('resetDislikes clears dislikes only', () async {
    await repo.like(pradoCard);
    await repo.dislike('someone-else');

    expect(await repo.resetDislikes(), const Right(unit));

    expect(right(await repo.getReactedKeys()), {pradoCard.key});
  });

  test('watchFavorites streams the favorites as they change', () async {
    final emissions = repo.watchFavorites().map((e) => right(e).map((f) => f.key).toList());
    final expectation = expectLater(
        emissions.take(2), emitsInOrder([isEmpty, [pradoCard.key]]));

    await Future<void>.delayed(Duration.zero);
    await repo.like(pradoCard);

    await expectation;
  });

  test('storage errors become failures instead of exceptions', () async {
    await db.close();

    expect((await repo.getFavorites()).isLeft(), isTrue);
    expect((await repo.getReactedKeys()).isLeft(), isTrue);
    expect((await repo.like(pradoCard)).isLeft(), isTrue);
    expect((await repo.dislike('k')).isLeft(), isTrue);
    expect((await repo.removeFavorite('k')).isLeft(), isTrue);
    expect((await repo.removeDislike('k')).isLeft(), isTrue);
    expect((await repo.resetDislikes()).isLeft(), isTrue);
    final failure =
        (await repo.like(pradoCard)).swap().getOrElse((_) => fail('left'));
    expect(failure, isA<ServerFailure>());
  });
}
