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
  const accountId = 'me';
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
    expect(await repo.like(pradoCard, accountId: accountId), const Right(unit));

    final favorite = right(await repo.getFavorites(accountId: accountId)).single;

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
        const PlaceResult(name: 'A', category: PlaceCategory.food, address: 'a')), accountId: accountId);
    await repo.like(RecommendedPlace.from(
        const PlaceResult(name: 'B', category: PlaceCategory.food, address: 'b')), accountId: accountId);

    final favorites = right(await repo.getFavorites(accountId: accountId));

    expect(favorites.map((f) => f.name), ['B', 'A']);
    expect(favorites.first.createdAt, DateTime.utc(2026, 10, 9, 8, 2));
  });

  test('dislike takes only a key, hides the place and removes a like',
      () async {
    await repo.like(pradoCard, accountId: accountId);

    expect(await repo.dislike(pradoCard.key, accountId: accountId), const Right(unit));

    expect(right(await repo.getFavorites(accountId: accountId)), isEmpty);
    expect(right(await repo.getReactedKeys(accountId: accountId)), {pradoCard.key});
  });

  test('like after dislike restores the favorite and drops the dislike',
      () async {
    await repo.dislike(pradoCard.key, accountId: accountId);

    await repo.like(pradoCard, accountId: accountId);

    expect(right(await repo.getFavorites(accountId: accountId)).map((f) => f.key), [pradoCard.key]);
    expect(await db.query('place_dislikes'), isEmpty);
  });

  test('removeFavorite frees the place; it is not a dislike', () async {
    await repo.like(pradoCard, accountId: accountId);

    expect(await repo.removeFavorite(pradoCard.key, accountId: accountId), const Right(unit));

    expect(right(await repo.getReactedKeys(accountId: accountId)), isEmpty);
  });

  test('removeDislike undoes a dislike', () async {
    await repo.dislike(pradoCard.key, accountId: accountId);

    expect(await repo.removeDislike(pradoCard.key, accountId: accountId), const Right(unit));

    expect(right(await repo.getReactedKeys(accountId: accountId)), isEmpty);
  });

  test('resetDislikes clears dislikes only', () async {
    await repo.like(pradoCard, accountId: accountId);
    await repo.dislike('someone-else', accountId: accountId);

    expect(await repo.resetDislikes(accountId: accountId), const Right(unit));

    expect(right(await repo.getReactedKeys(accountId: accountId)), {pradoCard.key});
  });

  test('watchFavorites streams the favorites as they change', () async {
    final emissions = repo.watchFavorites(accountId: accountId).map((e) => right(e).map((f) => f.key).toList());
    final expectation = expectLater(
        emissions.take(2), emitsInOrder([isEmpty, [pradoCard.key]]));

    await Future<void>.delayed(Duration.zero);
    await repo.like(pradoCard, accountId: accountId);

    await expectation;
  });

  test('reactions are scoped to the signed-in account', () async {
    expect(await repo.like(pradoCard, accountId: 'account-a'),
        const Right(unit));
    expect(await repo.dislike(pradoCard.key, accountId: 'account-b'),
        const Right(unit));

    expect(right(await repo.getFavorites(accountId: 'account-a')),
        hasLength(1),
        reason: 'account A only sees its own like');
    expect(right(await repo.getFavorites(accountId: 'account-b')), isEmpty,
        reason: "account B never sees account A's like");
    expect(right(await repo.getReactedKeys(accountId: 'account-b')),
        {pradoCard.key},
        reason: 'and only its own dislike');
  });

  test('storage errors become failures instead of exceptions', () async {
    await db.close();

    expect((await repo.getFavorites(accountId: accountId)).isLeft(), isTrue);
    expect((await repo.getReactedKeys(accountId: accountId)).isLeft(), isTrue);
    expect((await repo.like(pradoCard, accountId: accountId)).isLeft(), isTrue);
    expect((await repo.dislike('k', accountId: accountId)).isLeft(), isTrue);
    expect((await repo.removeFavorite('k', accountId: accountId)).isLeft(), isTrue);
    expect((await repo.removeDislike('k', accountId: accountId)).isLeft(), isTrue);
    expect((await repo.resetDislikes(accountId: accountId)).isLeft(), isTrue);
    final failure =
        (await repo.like(pradoCard, accountId: accountId)).swap().getOrElse((_) => fail('left'));
    expect(failure, isA<ServerFailure>());
  });
}
