import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/core/services/places/places_gateway.dart';
import 'package:travel_ready/domain/entities/recommendations/place_key.dart';
import 'package:travel_ready/domain/repositories/favorites_repository.dart';
import 'package:travel_ready/domain/usecases/recommendations/get_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/react_to_place_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/refill_recommendation_feed_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/reset_dislikes_usecase.dart';
import 'package:travel_ready/domain/usecases/recommendations/undo_reaction_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:travel_ready/presentation/pages/recommendations/recommendations_page.dart';

import '../../helpers/fake_data.dart';
import '../../support/recommendations_fakes.dart';

const _top = ValueKey('deck-top-card');

void main() {
  late FakePlacesGateway gateway;
  late InMemoryFavoritesRepository repo;

  setUp(() {
    gateway = FakePlacesGateway(catalog: fakeCatalog(perCategory: 2));
    repo = InMemoryFavoritesRepository();
    getIt.registerSingleton<PlacesGateway>(gateway);
    getIt.registerSingleton<FavoritesRepository>(repo);
    getIt.registerFactory<RecommendationsBloc>(() {
      final feed =
          GetRecommendationFeedUseCase(gateway: gateway, favorites: repo);
      return RecommendationsBloc(
        getFeed: feed,
        refill: RefillRecommendationFeedUseCase(feed),
        react: ReactToPlaceUseCase(repo),
        undo: UndoReactionUseCase(repo),
        resetDislikes: ResetDislikesUseCase(repo),
        seedProvider: () => 1,
      );
    });
  });

  tearDown(() async {
    await getIt.reset();
    repo.dispose();
  });

  Future<void> pumpPage(
    WidgetTester t, {
    Locale locale = const Locale('es'),
    bool settle = true,
  }) async {
    await t.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecommendationsPage(trip: tTrip),
    ));
    if (settle) await t.pumpAndSettle();
  }

  String topName(WidgetTester t) => t
      .widget<Text>(find
          .descendant(of: find.byKey(_top), matching: find.byType(Text))
          .first)
      .data!;

  Future<void> swipe(WidgetTester t, {required bool right}) async {
    await t.fling(find.byKey(_top), Offset(right ? 300 : -300, 0), 1500);
    await t.pumpAndSettle();
  }

  group('states', () {
    testWidgets('shows a spinner while loading and then the deck', (t) async {
      final gate = Completer<void>();
      gateway.gate = gate.future;

      await pumpPage(t, settle: false);
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(_top), findsNothing);

      gate.complete();
      await t.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(_top), findsOneWidget);
    });

    testWidgets('labels the demo provider and does not claim city results',
        (t) async {
      gateway.availability = PlacesAvailability.demo;

      await pumpPage(t);

      expect(find.textContaining('Datos de ejemplo'), findsOneWidget);
      expect(find.byType(TextField), findsNothing,
          reason: 'a typed city would imply city-specific demo results');
      expect(find.textContaining('París'), findsNothing);
    });

    testWidgets('a configured provider shows attribution and the city field',
        (t) async {
      gateway.availability = PlacesAvailability.configured;
      gateway.attributionText = 'Powered by Test Places';

      await pumpPage(t);

      expect(find.text('Powered by Test Places'), findsOneWidget);
      expect(find.textContaining('Datos de ejemplo'), findsNothing);
      expect(find.widgetWithText(TextField, 'París, Francia'), findsOneWidget);
      expect(gateway.calls.first.destinationHint, 'París, Francia');
    });

    testWidgets('a typed city reloads the feed with that location', (t) async {
      gateway.availability = PlacesAvailability.configured;
      await pumpPage(t);

      await t.enterText(find.byType(TextField), 'Granada');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();

      expect(gateway.calls.last.destinationHint, 'Granada');
    });

    testWidgets('an unavailable provider is honest and shows no cards',
        (t) async {
      gateway.availability = PlacesAvailability.unavailable;

      await pumpPage(t);

      expect(find.text('Proveedor no disponible'), findsOneWidget);
      expect(find.byKey(_top), findsNothing);
      expect(gateway.calls, isEmpty);
    });

    testWidgets('an error offers a retry that loads the feed', (t) async {
      gateway.failure = const ServerFailure('sin conexión');
      await pumpPage(t);

      expect(find.text('No se pudieron cargar las recomendaciones'),
          findsOneWidget);
      expect(find.text('sin conexión'), findsOneWidget);

      gateway.failure = null;
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();

      expect(find.byKey(_top), findsOneWidget);
    });

    testWidgets('a provider with nothing for the filter is the empty state',
        (t) async {
      gateway.catalog = [];

      await pumpPage(t);

      expect(find.text('Sin recomendaciones'), findsOneWidget);
      expect(find.byKey(_top), findsNothing);
    });

    testWidgets('texts follow the app language', (t) async {
      await pumpPage(t, locale: const Locale('en'));

      expect(find.text('Sample data — no provider configured'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);
      expect(find.text('I like it'), findsOneWidget);
    });
  });

  group('swiping', () {
    testWidgets('swipe right saves the place to Favorites', (t) async {
      await pumpPage(t);
      final name = topName(t);

      await swipe(t, right: true);

      expect(repo.favorites.map((f) => f.name), [name]);
      expect(repo.dislikedKeys, isEmpty);
      expect(find.text('Guardado en favoritos'), findsOneWidget);
    });

    testWidgets('swipe left hides the place and stores no favorite', (t) async {
      await pumpPage(t);
      final name = topName(t);

      await swipe(t, right: false);

      expect(repo.favorites, isEmpty);
      expect(repo.dislikedKeys, hasLength(1));
      expect(find.text('No volverás a ver este lugar'), findsOneWidget);
      expect(topName(t), isNot(name));
    });

    testWidgets('the buttons do what the gestures do', (t) async {
      await pumpPage(t);
      final liked = topName(t);
      await t.tap(find.text('Me gusta'));
      await t.pumpAndSettle();
      final skipped = topName(t);
      await t.tap(find.text('No me interesa'));
      await t.pumpAndSettle();

      expect(repo.favorites.map((f) => f.name), [liked]);
      expect(repo.dislikedKeys, hasLength(1));
      expect(skipped, isNot(liked));
    });

    testWidgets('a disliked place never comes back, not even after a refill',
        (t) async {
      gateway.catalog = [
        for (var i = 0; i < 5; i++) fakePlace('Food $i', PlaceCategory.food),
      ];
      await pumpPage(t);
      final seen = <String>[];

      for (var i = 0; i < 5; i++) {
        if (find.byKey(_top).evaluate().isEmpty) break;
        seen.add(topName(t));
        await swipe(t, right: false);
      }

      expect(seen, hasLength(5));
      expect(seen.toSet(), hasLength(5), reason: 'no place was offered twice');
      expect(find.byKey(_top), findsNothing);
      expect(find.text('No hay más lugares con este filtro'), findsOneWidget);
    });

    testWidgets('a failed write puts the card back and says so', (t) async {
      await pumpPage(t);
      final name = topName(t);
      repo.writeFailure = const CacheFailure('disk full');

      await swipe(t, right: true);

      expect(topName(t), name);
      expect(find.text('No se pudo guardar tu elección. Inténtalo de nuevo.'),
          findsOneWidget);
      expect(repo.favorites, isEmpty);
    });
  });

  group('filters', () {
    testWidgets('the four filters are offered with Todos selected', (t) async {
      await pumpPage(t);

      for (final label in ['Todos', 'Monumentos', 'Restaurantes', 'Ocio']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(
          t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todos')).selected,
          isTrue);
    });

    testWidgets('Restaurantes shows only food places', (t) async {
      await pumpPage(t);

      await t.tap(find.widgetWithText(ChoiceChip, 'Restaurantes'));
      await t.pumpAndSettle();

      expect(
          t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Restaurantes')).selected,
          isTrue);
      expect(find.descendant(of: find.byKey(_top), matching: find.text('Comida')),
          findsOneWidget);
      for (var i = 0; i < 2; i++) {
        expect(topName(t), startsWith('food-'));
        await swipe(t, right: true);
      }
      expect(find.byKey(_top), findsNothing);
    });

    testWidgets('Ocio mixes nature, nightlife and shopping only', (t) async {
      await pumpPage(t);

      await t.tap(find.widgetWithText(ChoiceChip, 'Ocio'));
      await t.pumpAndSettle();

      final allowed = {'nature-', 'nightlife-', 'shopping-'};
      for (var i = 0; i < 6; i++) {
        expect(allowed.any(topName(t).startsWith), isTrue);
        await swipe(t, right: false);
      }
    });

    testWidgets('an exhausted filter offers a way back to Todos', (t) async {
      await pumpPage(t);
      await t.tap(find.widgetWithText(ChoiceChip, 'Restaurantes'));
      await t.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await swipe(t, right: false);
      }
      expect(find.text('No hay más lugares con este filtro'), findsOneWidget);

      await t.tap(find.text('Ver todos'));
      await t.pumpAndSettle();

      expect(find.byKey(_top), findsOneWidget);
      expect(
          t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todos')).selected,
          isTrue);
    });

    testWidgets('Todos does not offer "Ver todos"', (t) async {
      gateway.catalog = [fakePlace('only', PlaceCategory.food)];
      await pumpPage(t);
      await swipe(t, right: true);

      expect(find.text('No hay más lugares con este filtro'), findsOneWidget);
      expect(find.text('Ver todos'), findsNothing);
      expect(find.text('Reiniciar feed'), findsOneWidget);
    });
  });

  group('undo', () {
    testWidgets('the snackbar undoes a like and brings the card back',
        (t) async {
      await pumpPage(t);
      final name = topName(t);
      await swipe(t, right: true);

      await t.tap(find.text('Deshacer'));
      await t.pumpAndSettle();

      expect(topName(t), name);
      expect(repo.favorites, isEmpty);
      expect(repo.dislikedKeys, isEmpty);
    });

    testWidgets('the snackbar undoes a dislike', (t) async {
      await pumpPage(t);
      final name = topName(t);
      await swipe(t, right: false);

      await t.tap(find.text('Deshacer'));
      await t.pumpAndSettle();

      expect(topName(t), name);
      expect(repo.dislikedKeys, isEmpty);
    });

    testWidgets('only the last swipe can be undone', (t) async {
      await pumpPage(t);
      final first = topName(t);
      await swipe(t, right: true);
      final second = topName(t);
      await swipe(t, right: true);

      await t.tap(find.text('Deshacer'));
      await t.pumpAndSettle();

      expect(topName(t), second);
      expect(repo.favorites.map((f) => f.name), [first]);
    });

    testWidgets('the undo snackbar is short-lived, not persistent', (t) async {
      await pumpPage(t);
      await swipe(t, right: true);
      expect(find.text('Deshacer'), findsOneWidget);

      await t.pump(const Duration(seconds: 8));
      await t.pumpAndSettle();

      expect(find.text('Deshacer'), findsNothing);
    });

    testWidgets('undoing the last card of the feed works from exhausted',
        (t) async {
      gateway.catalog = [fakePlace('only', PlaceCategory.food)];
      await pumpPage(t);
      await swipe(t, right: false);
      expect(find.text('No hay más lugares con este filtro'), findsOneWidget);

      await t.tap(find.text('Deshacer'));
      await t.pumpAndSettle();

      expect(topName(t), 'only');
    });
  });

  group('reset the feed', () {
    Future<void> openReset(WidgetTester t) async {
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Reiniciar feed').last);
      await t.pumpAndSettle();
    }

    testWidgets('is reachable from the overflow menu behind a confirmation',
        (t) async {
      await pumpPage(t);
      await swipe(t, right: false);

      await openReset(t);

      expect(find.text('¿Reiniciar el feed?'), findsOneWidget);
      expect(repo.dislikedKeys, hasLength(1), reason: 'nothing cleared yet');
    });

    testWidgets('cancelling leaves the dislikes alone', (t) async {
      await pumpPage(t);
      await swipe(t, right: false);
      await openReset(t);

      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();

      expect(repo.dislikedKeys, hasLength(1));
      expect(find.text('¿Reiniciar el feed?'), findsNothing);
    });

    testWidgets('confirming clears dislikes only and offers them again',
        (t) async {
      await pumpPage(t);
      final liked = topName(t);
      await swipe(t, right: true);
      final hidden = topName(t);
      await swipe(t, right: false);
      await openReset(t);

      await t.tap(find.widgetWithText(TextButton, 'Reiniciar'));
      await t.pumpAndSettle();

      expect(repo.dislikedKeys, isEmpty);
      expect(repo.favorites.map((f) => f.name), [liked]);
      expect(find.text('Feed reiniciado'), findsOneWidget);
      final shown = <String>{};
      for (var i = 0; i < 12; i++) {
        if (find.byKey(_top).evaluate().isEmpty) break;
        shown.add(topName(t));
        await swipe(t, right: false);
      }
      expect(shown, contains(hidden));
      expect(shown, isNot(contains(liked)));
    });

    testWidgets('an exhausted feed has a reset action that revives it',
        (t) async {
      gateway.catalog = [fakePlace('only', PlaceCategory.food)];
      await pumpPage(t);
      await swipe(t, right: false);
      await t.pump(const Duration(seconds: 8));
      await t.pumpAndSettle();

      await t.tap(find.widgetWithText(OutlinedButton, 'Reiniciar feed'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(TextButton, 'Reiniciar'));
      await t.pumpAndSettle();

      expect(topName(t), 'only');
    });
  });

  testWidgets('every card shown carries a stable provider-neutral key',
      (t) async {
    await pumpPage(t);
    final seen = <String>{};

    for (var i = 0; i < 12; i++) {
      if (find.byKey(_top).evaluate().isEmpty) break;
      final place = gateway.catalog.firstWhere((p) => p.name == topName(t));
      seen.add(placeKeyOf(place));
      await swipe(t, right: true);
    }

    expect(repo.favorites.map((f) => f.key).toSet(), seen);
  });
}
