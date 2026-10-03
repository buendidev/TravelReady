import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_ready/presentation/pages/premium/premium_widgets.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Column(children: [child])),
        ),
      );

  testWidgets('MockPremiumView shows premium copy and fires callbacks', (
    tester,
  ) async {
    final toggledTo = <bool>[];
    var subscribed = false;

    await pump(
      tester,
      MockPremiumView(
        yearly: false,
        onToggle: toggledTo.add,
        onSubscribe: () => subscribed = true,
      ),
    );

    expect(find.text('Hazte Premium'), findsOneWidget);
    expect(find.textContaining('9,99 €'), findsOneWidget);
    expect(find.text('Empezar prueba gratuita 7 días'), findsOneWidget);

    await tester.tap(find.textContaining('Anual'));
    await tester.pump();
    expect(toggledTo, [true]);

    await tester.ensureVisible(find.text('Empezar prueba gratuita 7 días'));
    await tester.tap(find.text('Empezar prueba gratuita 7 días'));
    expect(subscribed, isTrue);
  });

  testWidgets('MockPremiumView yearly shows yearly price and savings copy', (
    tester,
  ) async {
    await pump(
      tester,
      MockPremiumView(yearly: true, onToggle: (_) {}, onSubscribe: () {}),
    );

    expect(find.textContaining('89,99 €'), findsOneWidget);
    expect(find.text('Ahorra un 25% vs mensual'), findsOneWidget);
  });

  testWidgets(
      'RevenueCatPremiumView falls back to static prices and fires '
      'subscribe/restore', (tester) async {
    var subscribed = false;
    var restored = false;

    await pump(
      tester,
      RevenueCatPremiumView(
        yearly: true,
        onToggle: (_) {},
        onSubscribe: () => subscribed = true,
        onRestore: () => restored = true,
      ),
    );

    expect(find.text('Hazte Premium'), findsOneWidget);
    expect(find.textContaining('89,99 €'), findsOneWidget);
    expect(find.text('Suscribirse ahora'), findsOneWidget);
    expect(find.text('Restaurar compras'), findsOneWidget);

    await tester.ensureVisible(find.text('Suscribirse ahora'));
    await tester.tap(find.text('Suscribirse ahora'));
    expect(subscribed, isTrue);

    await tester.ensureVisible(find.text('Restaurar compras'));
    await tester.tap(find.text('Restaurar compras'));
    expect(restored, isTrue);
  });

  testWidgets('PremiumActiveView shows active state and fires restore', (
    tester,
  ) async {
    var restored = false;

    await pump(tester, PremiumActiveView(onRestore: () => restored = true));

    expect(find.text('¡Ya eres Premium!'), findsOneWidget);
    expect(find.text('Suscripción activa'), findsOneWidget);

    await tester.tap(find.text('Restaurar compras'));
    expect(restored, isTrue);
  });
}
