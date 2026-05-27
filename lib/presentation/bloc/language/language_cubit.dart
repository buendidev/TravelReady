import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit que gestiona el idioma de la app (ES / EN).
/// Persiste la preferencia con SharedPreferences.
class LanguageCubit extends Cubit<Locale> {
  static const _key = 'locale';
  final SharedPreferences? _prefs;

  LanguageCubit({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const Locale('es')) {
    _load();
  }

  static const supported = [
    Locale('es'), // Español
    Locale('en'), // English
  ];

  Future<void> _load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final code  = prefs.getString(_key) ?? 'es';
    emit(Locale(code));
  }

  Future<void> setSpanish() => _save(const Locale('es'));
  Future<void> setEnglish() => _save(const Locale('en'));

  Future<void> toggle() async {
    await _save(state.languageCode == 'es'
        ? const Locale('en')
        : const Locale('es'));
  }

  Future<void> _save(Locale locale) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    emit(locale);
  }

  String get currentLabel =>
      state.languageCode == 'es' ? '🇪🇸 Español' : '🇬🇧 English';
}
