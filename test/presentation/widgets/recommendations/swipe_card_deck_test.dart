import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/services/places/place_category.dart';
import 'package:travel_ready/domain/entities/recommendations/applied_reaction.dart';
import 'package:travel_ready/domain/entities/recommendations/recommended_place.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/widgets/recommendations/swipe_card_deck.dart';

import '../../../support/recommendations_fakes.dart';

const _top = ValueKey('deck-top-card');
const _rotation = ValueKey('deck-top-rotation');

class _Reaction {
  final String name;
  final PlaceReaction reaction;
  const _Reaction(this.name, this.reaction);
}

void main() {
  late ValueNotifier<List<RecommendedPlace>> deck;
  late List<_Reaction> reactions;
  late List<String?> hapticCalls;

  List<RecommendedPlace> cards([int n = 5]) => [
        for (var i = 0; i < n; i++)
          RecommendedPlace.from(fakePlace('Place $i', PlaceCategory.museum,
              address: 'Calle $i, Madrid')),
      ];

  setUp(() {
    deck = ValueNotifier(cards());
    reactions = [];
    hapticCalls = [];
  });

  tearDown(() => deck.dispose());

  Future<void> pumpDeck(
    WidgetTester t, {
    bool parentRemovesCard = true,
    Locale locale = const Locale('es'),
  }) async {
    await t.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        hapticCalls.add(call.arguments as String?);
      }
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await t.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueListenableBuilder<List<RecommendedPlace>>(
          valueListenable: deck,
          builder: (_, list, __) => SwipeCardDeck(
            cards: list,
            onReact: (card, reaction) {
              reactions.add(_Reaction(card.place.name, reaction));
              if (parentRemovesCard) {
                deck.value = deck.value.where((c) => c.key != card.key).toList();
              }
            },
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
  }

  /// Slow, controlled drag so the release velocity stays well under a fling.
  Future<TestGesture> dragSlowly(WidgetTester t, double dx,
      {double dy = 0}) async {
    final gesture = await t.startGesture(t.getCenter(find.byKey(_top)));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(dx / steps, dy / steps));
      await t.pump(const Duration(milliseconds: 80));
    }
    return gesture;
  }

  double angleOf(WidgetTester t) {
    final m = t.widget<Transform>(find.byKey(_rotation)).transform;
    return math.atan2(m.entry(1, 0), m.entry(0, 0));
  }

  group('layout', () {
    testWidgets('shows the top card with category, price and address',
        (t) async {
      await pumpDeck(t);

      final top = find.byKey(_top);
      expect(find.descendant(of: top, matching: find.text('Place 0')),
          findsOneWidget);
      expect(find.descendant(of: top, matching: find.text('Calle 0, Madrid')),
          findsOneWidget);
      expect(find.descendant(of: top, matching: find.text('Museos')),
          findsOneWidget);
      expect(find.descendant(of: top, matching: find.text('€€')),
          findsOneWidget);
    });

    testWidgets('keeps two partially visible cards behind the top one',
        (t) async {
      await pumpDeck(t);

      expect(find.byKey(const ValueKey('deck-behind-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-behind-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-behind-3')), findsNothing);
    });

    testWidgets('shows fewer cards behind when the deck is almost empty',
        (t) async {
      deck.value = cards(2);
      await pumpDeck(t);

      expect(find.byKey(const ValueKey('deck-behind-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-behind-2')), findsNothing);
    });

    testWidgets('an empty deck renders nothing and does not throw', (t) async {
      deck.value = [];
      await pumpDeck(t);

      expect(find.byKey(_top), findsNothing);
      expect(find.text('Me gusta'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('swipe gestures', () {
    testWidgets('dragging past the threshold to the right likes the card',
        (t) async {
      await pumpDeck(t);

      final gesture = await dragSlowly(t, 200);
      await gesture.up();
      await t.pumpAndSettle();

      expect(reactions.single.name, 'Place 0');
      expect(reactions.single.reaction, PlaceReaction.like);
    });

    testWidgets('dragging past the threshold to the left dislikes the card',
        (t) async {
      await pumpDeck(t);

      final gesture = await dragSlowly(t, -200);
      await gesture.up();
      await t.pumpAndSettle();

      expect(reactions.single.name, 'Place 0');
      expect(reactions.single.reaction, PlaceReaction.dislike);
    });

    testWidgets('a short slow drag springs back without reacting', (t) async {
      await pumpDeck(t);
      final home = t.getCenter(find.byKey(_top));

      final gesture = await dragSlowly(t, 60);
      expect(t.getCenter(find.byKey(_top)).dx, greaterThan(home.dx + 30));
      await gesture.up();
      await t.pumpAndSettle();

      expect(reactions, isEmpty);
      expect(t.getCenter(find.byKey(_top)).dx, closeTo(home.dx, 0.5));
      expect(angleOf(t), closeTo(0, 1e-6));
    });

    testWidgets('just under 35 % of the card width does not commit',
        (t) async {
      await pumpDeck(t);
      final width = t.getSize(find.byKey(_top)).width;

      final gesture = await dragSlowly(t, width * 0.33);
      await gesture.up();
      await t.pumpAndSettle();

      expect(reactions, isEmpty);
    });

    testWidgets('just over 35 % of the card width commits', (t) async {
      await pumpDeck(t);
      final width = t.getSize(find.byKey(_top)).width;

      final gesture = await dragSlowly(t, width * 0.37);
      await gesture.up();
      await t.pumpAndSettle();

      expect(reactions.single.reaction, PlaceReaction.like);
    });

    testWidgets('a fast fling commits even below the distance threshold',
        (t) async {
      await pumpDeck(t);

      await t.fling(find.byKey(_top), const Offset(100, 0), 1500);
      await t.pumpAndSettle();

      expect(reactions.single.reaction, PlaceReaction.like);
    });

    testWidgets('a fast fling to the left dislikes', (t) async {
      await pumpDeck(t);

      await t.fling(find.byKey(_top), const Offset(-100, 0), 1500);
      await t.pumpAndSettle();

      expect(reactions.single.reaction, PlaceReaction.dislike);
    });

    testWidgets('a slow fling below 800 px/s and the distance does not commit',
        (t) async {
      await pumpDeck(t);

      await t.fling(find.byKey(_top), const Offset(100, 0), 400);
      await t.pumpAndSettle();

      expect(reactions, isEmpty);
    });

    testWidgets('a vertical fling does not react', (t) async {
      await pumpDeck(t);

      await t.fling(find.byKey(_top), const Offset(0, -300), 2000);
      await t.pumpAndSettle();

      expect(reactions, isEmpty);
    });

    testWidgets('the next card takes the top spot centred and unrotated',
        (t) async {
      await pumpDeck(t);
      final home = t.getCenter(find.byKey(_top));

      final gesture = await dragSlowly(t, 200);
      await gesture.up();
      await t.pumpAndSettle();

      expect(find.descendant(of: find.byKey(_top), matching: find.text('Place 1')),
          findsOneWidget);
      expect(t.getCenter(find.byKey(_top)).dx, closeTo(home.dx, 0.5));
      expect(angleOf(t), closeTo(0, 1e-6));
    });

    testWidgets('swiping works for consecutive cards', (t) async {
      await pumpDeck(t);

      for (var i = 0; i < 3; i++) {
        final gesture = await dragSlowly(t, i.isEven ? 200 : -200);
        await gesture.up();
        await t.pumpAndSettle();
      }

      expect(reactions.map((r) => r.name), ['Place 0', 'Place 1', 'Place 2']);
      expect(reactions.map((r) => r.reaction), [
        PlaceReaction.like,
        PlaceReaction.dislike,
        PlaceReaction.like,
      ]);
    });

    testWidgets(
        'if the parent keeps the card, the deck is reset so it is not lost',
        (t) async {
      await pumpDeck(t, parentRemovesCard: false);
      final home = t.getCenter(find.byKey(_top));

      final gesture = await dragSlowly(t, 200);
      await gesture.up();
      await t.pumpAndSettle();
      deck.value = List.of(deck.value); // parent rebuilds with the same cards

      await t.pumpAndSettle();
      expect(reactions, hasLength(1));
      expect(t.getCenter(find.byKey(_top)).dx, closeTo(home.dx, 0.5),
          reason: 'a card the parent kept must come back on screen');
    });
  });

  group('drag feedback', () {
    testWidgets('rotation grows proportionally with the horizontal drag',
        (t) async {
      await pumpDeck(t);
      expect(angleOf(t), 0);

      final gesture = await t.startGesture(t.getCenter(find.byKey(_top)));
      await gesture.moveBy(const Offset(40, 0));
      await t.pump(const Duration(milliseconds: 50));
      final small = angleOf(t);
      await gesture.moveBy(const Offset(40, 0));
      await t.pump(const Duration(milliseconds: 50));
      final double = angleOf(t);

      expect(small, greaterThan(0));
      expect(double / small, closeTo(2, 0.05));
      await gesture.moveBy(const Offset(-160, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(angleOf(t), lessThan(0), reason: 'left drag rotates the other way');
      await gesture.up();
      await t.pumpAndSettle();
    });

    testWidgets('the like badge appears only once the threshold is crossed',
        (t) async {
      await pumpDeck(t);
      final width = t.getSize(find.byKey(_top)).width;
      final gesture = await t.startGesture(t.getCenter(find.byKey(_top)));

      await gesture.moveBy(Offset(width * 0.2, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('swipe-like-badge')), findsNothing);

      await gesture.moveBy(Offset(width * 0.2, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('swipe-like-badge')), findsOneWidget);
      expect(find.byKey(const ValueKey('swipe-dislike-badge')), findsNothing);

      await gesture.moveBy(Offset(-width * 0.3, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('swipe-like-badge')), findsNothing);
      await gesture.up();
      await t.pumpAndSettle();
    });

    testWidgets('the dislike badge appears when dragging left past the threshold',
        (t) async {
      await pumpDeck(t);
      final width = t.getSize(find.byKey(_top)).width;
      final gesture = await t.startGesture(t.getCenter(find.byKey(_top)));

      await gesture.moveBy(Offset(-width * 0.4, 0));
      await t.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('swipe-dislike-badge')), findsOneWidget);
      expect(find.byKey(const ValueKey('swipe-like-badge')), findsNothing);
      await gesture.up();
      await t.pumpAndSettle();
    });

    testWidgets('a haptic tick fires once when the threshold is crossed',
        (t) async {
      await pumpDeck(t);
      final width = t.getSize(find.byKey(_top)).width;
      final gesture = await t.startGesture(t.getCenter(find.byKey(_top)));

      await gesture.moveBy(Offset(width * 0.2, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(hapticCalls, isEmpty);

      await gesture.moveBy(Offset(width * 0.2, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(hapticCalls, ['HapticFeedbackType.selectionClick']);

      await gesture.moveBy(Offset(width * 0.1, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(hapticCalls, hasLength(1), reason: 'no repeat while past it');

      await gesture.moveBy(Offset(-width * 0.5, 0));
      await t.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(Offset(width * 0.5, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(hapticCalls, hasLength(2), reason: 'crossing again ticks again');
      await gesture.up();
      await t.pumpAndSettle();
    });
  });

  group('buttons (the accessible path)', () {
    testWidgets('both buttons are always visible with their labels', (t) async {
      await pumpDeck(t);

      expect(find.text('No me interesa'), findsOneWidget);
      expect(find.text('Me gusta'), findsOneWidget);
    });

    testWidgets('the like button does what a right swipe does', (t) async {
      await pumpDeck(t);

      await t.tap(find.text('Me gusta'));
      await t.pumpAndSettle();

      expect(reactions.single.name, 'Place 0');
      expect(reactions.single.reaction, PlaceReaction.like);
      expect(find.descendant(of: find.byKey(_top), matching: find.text('Place 1')),
          findsOneWidget);
    });

    testWidgets('the dislike button does what a left swipe does', (t) async {
      await pumpDeck(t);

      await t.tap(find.text('No me interesa'));
      await t.pumpAndSettle();

      expect(reactions.single.name, 'Place 0');
      expect(reactions.single.reaction, PlaceReaction.dislike);
    });

    testWidgets('pressing a button twice in a row reacts once', (t) async {
      await pumpDeck(t);

      await t.tap(find.text('Me gusta'));
      await t.pump(const Duration(milliseconds: 20));
      await t.tap(find.text('Me gusta'), warnIfMissed: false);
      await t.pumpAndSettle();

      expect(reactions, hasLength(1));
    });

    testWidgets('both buttons are inert while the card flies away', (t) async {
      await pumpDeck(t);
      ButtonStyleButton button<T extends ButtonStyleButton>() =>
          t.widget<ButtonStyleButton>(find.bySubtype<T>());

      await t.tap(find.text('Me gusta'));
      await t.pump(const Duration(milliseconds: 20));

      expect(button<ElevatedButton>().onPressed, isNull);
      expect(button<OutlinedButton>().onPressed, isNull);

      await t.pumpAndSettle();

      expect(button<ElevatedButton>().onPressed, isNotNull,
          reason: 'the next card can be reacted to');
      expect(button<OutlinedButton>().onPressed, isNotNull);
    });

    testWidgets('buttons expose Semantics labels and are focusable buttons',
        (t) async {
      final handle = t.ensureSemantics();
      await pumpDeck(t);

      final like = t
          .getSemantics(find.bySemanticsLabel('Me gusta'))
          .getSemanticsData();
      final dislike = t
          .getSemantics(find.bySemanticsLabel('No me interesa'))
          .getSemanticsData();

      for (final data in [like, dislike]) {
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    });

    testWidgets('a screen reader can react through the semantic tap action',
        (t) async {
      final handle = t.ensureSemantics();
      await pumpDeck(t);

      t.semantics.tap(find.semantics.byLabel('Me gusta'));
      await t.pumpAndSettle();

      expect(reactions.single.reaction, PlaceReaction.like);
      handle.dispose();
    });

    testWidgets('the top card offers like and dislike as custom semantic actions',
        (t) async {
      final handle = t.ensureSemantics();
      await pumpDeck(t);

      final data = t.getSemantics(find.byKey(_top)).getSemanticsData();
      final labels = (data.customSemanticsActionIds ?? [])
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toSet();

      expect(labels, {'Me gusta', 'No me interesa'});
      handle.dispose();
    });

    testWidgets('the cards behind are hidden from assistive technology',
        (t) async {
      final handle = t.ensureSemantics();
      await pumpDeck(t);

      expect(find.bySemanticsLabel(RegExp('Place 1')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Place 0')), findsWidgets);
      handle.dispose();
    });

    testWidgets('labels follow the language of the app', (t) async {
      await pumpDeck(t, locale: const Locale('en'));

      expect(find.text('Not interested'), findsOneWidget);
      expect(find.text('I like it'), findsOneWidget);
    });
  });
}
