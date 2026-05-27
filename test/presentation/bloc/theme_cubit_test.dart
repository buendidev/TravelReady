import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_ready/presentation/bloc/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeCubit', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('estado inicial es ThemeMode.system', () async {
      final cubit = ThemeCubit(prefs: prefs);
      await Future.delayed(Duration.zero);
      expect(cubit.state, ThemeMode.system);
      await cubit.close();
    });

    blocTest<ThemeCubit, ThemeMode>(
      'setLight() emite ThemeMode.light',
      build: () => ThemeCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) => c.setLight(),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setDark() emite ThemeMode.dark',
      build: () => ThemeCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) => c.setDark(),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setSystem() emite ThemeMode.system',
      build: () => ThemeCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) async {
        await c.setDark();
        await c.setSystem();
      },
      expect: () => [ThemeMode.dark, ThemeMode.system],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme() alterna de light a dark',
      build: () => ThemeCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) async {
        await c.setLight();
        await c.toggleTheme();
      },
      expect: () => [ThemeMode.light, ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme() alterna de dark a light',
      build: () => ThemeCubit(prefs: prefs),
      wait: const Duration(milliseconds: 50),
      act: (c) async {
        await c.setDark();
        await c.toggleTheme();
      },
      expect: () => [ThemeMode.dark, ThemeMode.light],
    );
  });
}
