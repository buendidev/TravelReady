import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_ready/presentation/bloc/language/language_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageCubit', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('estado inicial es Locale(es)', () async {
      final cubit = LanguageCubit(prefs: prefs);
      await Future.delayed(Duration.zero);
      expect(cubit.state, const Locale('es'));
      await cubit.close();
    });

    blocTest<LanguageCubit, Locale>(
      'setEnglish() emite Locale(en)',
      build: () => LanguageCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) => c.setEnglish(),
      expect: () => [const Locale('en')],
    );

    blocTest<LanguageCubit, Locale>(
      'setSpanish() emite Locale(es)',
      build: () => LanguageCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) async {
        await c.setEnglish();
        await c.setSpanish();
      },
      expect: () => [const Locale('en'), const Locale('es')],
    );

    blocTest<LanguageCubit, Locale>(
      'toggle() alterna de es a en',
      build: () => LanguageCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) => c.toggle(),
      expect: () => [const Locale('en')],
    );

    blocTest<LanguageCubit, Locale>(
      'toggle() alterna de en a es',
      build: () => LanguageCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) async {
        await c.setEnglish();
        await c.toggle();
      },
      expect: () => [const Locale('en'), const Locale('es')],
    );

    test('supported contiene es y en', () {
      expect(LanguageCubit.supported, containsAll([
        const Locale('es'),
        const Locale('en'),
      ]));
    });

    test('currentLabel es "🇪🇸 Español" en español', () async {
      final cubit = LanguageCubit(prefs: prefs);
      await Future.delayed(Duration.zero);
      expect(cubit.currentLabel, '🇪🇸 Español');
      await cubit.close();
    });
  });
}
