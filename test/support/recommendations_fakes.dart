import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/place_result.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/recommendations/favorite_place.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/repositories/favorites_repository.dart';

/// One recorded call to [FakePlacesGateway.search].
class SearchCall {
  final String query;
  final PlaceCategory? category;
  final String? destinationHint;
  final int limit;

  const SearchCall({
    required this.query,
    required this.category,
    required this.destinationHint,
    required this.limit,
  });
}

/// Gateway double that records every call and answers from [catalog], honouring
/// the requested category the way a real provider would.
class FakePlacesGateway implements PlacesGateway {
  FakePlacesGateway({
    this.availability = PlacesAvailability.demo,
    this.attributionText,
    List<PlaceResult> catalog = const [],
  }) : catalog = List.of(catalog);

  @override
  PlacesAvailability availability;
  @override
  String? attributionText;

  List<PlaceResult> catalog;
  Failure? failure;

  /// When set, a search waits for it before answering (to observe loading).
  Future<void>? gate;
  final List<SearchCall> calls = [];

  /// Optional per-call override, e.g. to return different data on a refill.
  Either<Failure, List<PlaceResult>> Function(SearchCall call)? responder;

  @override
  Future<Either<Failure, List<PlaceResult>>> search({
    required String query,
    PlaceCategory? category,
    String? destinationHint,
    int limit = 20,
  }) async {
    final call = SearchCall(
      query: query,
      category: category,
      destinationHint: destinationHint,
      limit: limit,
    );
    calls.add(call);
    if (gate != null) await gate;
    if (failure != null) return Left(failure!);
    if (responder != null) return responder!(call);
    final matches = catalog
        .where((p) => category == null || p.category == category)
        .take(limit)
        .toList();
    return Right(matches);
  }
}

/// Per-account state of [InMemoryFavoritesRepository]: favorites and dislikes
/// are disjoint per account, like the SQLite tables.
class _AccountReactions {
  final Map<String, FavoritePlace> favorites = {};
  final Set<String> dislikes = {};
}

/// Full in-memory [FavoritesRepository] that enforces the same contract as the
/// SQLite one: reactions are scoped to the account, like and dislike are
/// mutually exclusive, removing a favorite is not a dislike, and a dislike
/// keeps only the key.
class InMemoryFavoritesRepository implements FavoritesRepository {
  final Map<String, _AccountReactions> _accounts = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _tick = 0;

  /// When set, every write fails with it.
  Failure? writeFailure;

  /// When set, every read fails with it.
  Failure? readFailure;

  final List<String> log = [];

  /// Live [watchFavorites] subscriptions, to catch a consumer that stacks them.
  int activeWatchers = 0;

  _AccountReactions _account(String accountId) =>
      _accounts.putIfAbsent(accountId, _AccountReactions.new);

  /// The account [favoritesFor] and [dislikesFor] inspect.
  String inspectedAccountId = '';

  Set<String> dislikesFor(String accountId) =>
      Set.unmodifiable(_account(accountId).dislikes);
  List<FavoritePlace> favoritesFor(String accountId) => _sorted(accountId);

  List<FavoritePlace> _sorted(String accountId) =>
      _account(accountId).favorites.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Either<Failure, Unit> _write(void Function() action, String entry) {
    if (writeFailure != null) return Left(writeFailure!);
    action();
    log.add(entry);
    _changes.add(null);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<FavoritePlace>>> getFavorites(
      {required String accountId}) async =>
      readFailure != null
          ? Left(readFailure!)
          : Right(_sorted(accountId));

  @override
  Stream<Either<Failure, List<FavoritePlace>>> watchFavorites(
      {required String accountId}) {
    late StreamController<Either<Failure, List<FavoritePlace>>> controller;
    StreamSubscription<void>? subscription;
    void emit() {
      if (controller.isClosed) return;
      controller.add(readFailure != null
          ? Left(readFailure!)
          : Right(_sorted(accountId)));
    }

    controller = StreamController(
      onListen: () {
        activeWatchers++;
        subscription = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () {
        activeWatchers--;
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Either<Failure, Set<String>>> getReactedKeys(
      {required String accountId}) async =>
      readFailure != null
          ? Left(readFailure!)
          : Right({
              ..._account(accountId).favorites.keys,
              ..._account(accountId).dislikes
            });

  @override
  Future<Either<Failure, Unit>> like(RecommendedPlace place,
      {required String accountId}) async =>
      _write(() {
        final account = _account(accountId);
        account.dislikes.remove(place.key);
        account.favorites[place.key] = FavoritePlace.fromRecommended(place,
            createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: _tick++)));
      }, 'like:${place.key}');

  @override
  Future<Either<Failure, Unit>> dislike(String placeKey,
      {required String accountId}) async =>
      _write(() {
        final account = _account(accountId);
        account.favorites.remove(placeKey);
        account.dislikes.add(placeKey);
      }, 'dislike:$placeKey');

  @override
  Future<Either<Failure, Unit>> removeFavorite(String placeKey,
          {required String accountId}) async =>
      _write(() => _account(accountId).favorites.remove(placeKey),
          'removeFavorite:$placeKey');

  @override
  Future<Either<Failure, Unit>> removeDislike(String placeKey,
          {required String accountId}) async =>
      _write(() => _account(accountId).dislikes.remove(placeKey),
          'removeDislike:$placeKey');

  @override
  Future<Either<Failure, Unit>> resetDislikes(
          {required String accountId}) async =>
      _write(() => _account(accountId).dislikes.clear(), 'resetDislikes');

  void dispose() => _changes.close();
}

/// Builds a place with a deterministic address so each name is a distinct venue.
PlaceResult fakePlace(String name, PlaceCategory category,
        {String? address}) =>
    PlaceResult(
      providerId: 'prov-$name',
      photoReference: 'photo-$name',
      name: name,
      category: category,
      address: address ?? '$name street',
      priceLevelLabel: '€€',
      shortDescription: 'About $name.',
    );

/// A catalog with [perCategory] venues in each feed category plus a hotel and
/// an `other` that must never surface.
List<PlaceResult> fakeCatalog({int perCategory = 3}) => [
      for (final c in const [
        PlaceCategory.monument,
        PlaceCategory.museum,
        PlaceCategory.food,
        PlaceCategory.nature,
        PlaceCategory.nightlife,
        PlaceCategory.shopping,
      ])
        for (var i = 0; i < perCategory; i++) fakePlace('${c.name}-$i', c),
      fakePlace('grand-hotel', PlaceCategory.hotel),
      fakePlace('mystery', PlaceCategory.other),
    ];
