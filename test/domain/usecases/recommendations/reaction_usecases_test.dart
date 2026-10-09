import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/recommendations/applied_reaction.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/domain/usecases/recommendations/react_to_place_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/reset_dislikes_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/undo_reaction_usecase.dart';

import '../../../support/recommendations_fakes.dart';

void main() {
  const accountId = 'me';
  late InMemoryFavoritesRepository repo;
  late ReactToPlaceUseCase react;
  late UndoReactionUseCase undo;
  late ResetDislikesUseCase reset;
  final card = RecommendedPlace.from(fakePlace('Prado', PlaceCategory.museum));

  setUp(() {
    repo = InMemoryFavoritesRepository();
    react = ReactToPlaceUseCase(repo);
    undo = UndoReactionUseCase(repo);
    reset = ResetDislikesUseCase(repo);
  });

  tearDown(() => repo.dispose());

  test('like keeps the place as a favorite and reports what was applied',
      () async {
    final applied =
        (await react(card, PlaceReaction.like, accountId: accountId)).getOrElse((_) => fail('left'));

    expect(applied, AppliedReaction(place: card, reaction: PlaceReaction.like));
    expect(repo.favoritesFor(accountId).map((f) => f.key), [card.key]);
  });

  test('dislike hides the place by key and removes a like', () async {
    await react(card, PlaceReaction.like, accountId: accountId);

    await react(card, PlaceReaction.dislike, accountId: accountId);

    expect(repo.favoritesFor(accountId), isEmpty);
    expect(repo.dislikesFor(accountId), {card.key});
  });

  test('a failed write is reported and nothing is applied', () async {
    repo.writeFailure = const CacheFailure('disk full');

    final result = await react(card, PlaceReaction.like, accountId: accountId);

    expect(result.isLeft(), isTrue);
    expect(repo.favoritesFor(accountId), isEmpty);
  });

  test('undoing a like removes the favorite without disliking the place',
      () async {
    final applied =
        (await react(card, PlaceReaction.like, accountId: accountId)).getOrElse((_) => fail('left'));

    expect(await undo(applied, accountId: accountId), const Right(unit));

    expect(repo.favoritesFor(accountId), isEmpty);
    expect(repo.dislikesFor(accountId), isEmpty);
  });

  test('undoing a dislike lets the place be offered again', () async {
    final applied = (await react(card, PlaceReaction.dislike, accountId: accountId))
        .getOrElse((_) => fail('left'));

    expect(await undo(applied, accountId: accountId), const Right(unit));

    expect(repo.dislikesFor(accountId), isEmpty);
  });

  test('reset clears dislikes only and keeps favorites', () async {
    final other = RecommendedPlace.from(fakePlace('Retiro', PlaceCategory.nature));
    await react(card, PlaceReaction.like, accountId: accountId);
    await react(other, PlaceReaction.dislike, accountId: accountId);

    expect(await reset(accountId: accountId), const Right(unit));

    expect(repo.dislikesFor(accountId), isEmpty);
    expect(repo.favoritesFor(accountId).map((f) => f.key), [card.key]);
  });
}
