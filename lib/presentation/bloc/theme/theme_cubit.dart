import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit que controla el tema visual de la app (light / dark / system).
/// Persiste la preferencia del usuario con SharedPreferences.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _prefKey = 'theme_mode';
  final SharedPreferences? _prefs;

  ThemeCubit({SharedPreferences? prefs})
      : _prefs = prefs,
        super(ThemeMode.system) {
    _loadSavedTheme();
  }

  /// Carga el tema guardado al iniciar la app.
  Future<void> _loadSavedTheme() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    switch (saved) {
      case 'light':
        emit(ThemeMode.light);
      case 'dark':
        emit(ThemeMode.dark);
      default:
        emit(ThemeMode.system);
    }
  }

  /// Alterna entre modo claro y oscuro.
  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _save(next);
    emit(next);
  }

  Future<void> setLight() async {
    await _save(ThemeMode.light);
    emit(ThemeMode.light);
  }

  Future<void> setDark() async {
    await _save(ThemeMode.dark);
    emit(ThemeMode.dark);
  }

  Future<void> setSystem() async {
    await _save(ThemeMode.system);
    emit(ThemeMode.system);
  }

  Future<void> _save(ThemeMode mode) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
