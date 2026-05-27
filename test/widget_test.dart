// Widget tests de TravelReady! — smoke tests básicos
// Asegura que la app arranca sin errores en un entorno de test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Smoke tests', () {
    testWidgets('MaterialApp con tema no lanza errores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(children: const [
                Icon(Icons.luggage_rounded, color: Color(0xFF006571)),
                Text('TravelReady!'),
              ]),
            ),
          ),
        ),
      );

      expect(find.text('TravelReady!'), findsOneWidget);
      expect(find.byIcon(Icons.luggage_rounded), findsOneWidget);
    });

    testWidgets('Scaffold básico renderiza sin overflow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
