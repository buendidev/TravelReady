import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';

/// Guarda el último usuario confirmado por Firebase para poder arrancar sin red.
///
/// Sin esto, un arranque en frío sin conexión espera a que Firebase responda,
/// no recibe nada y manda al login a alguien que tiene sesión y datos locales,
/// sin forma de iniciarla porque el propio login necesita red.
///
/// La instantánea se reescribe con cada emisión autenticada y se borra al
/// cerrar sesión, así que sólo puede contener la última sesión que Firebase
/// confirmó. El stream de autenticación sigue escuchando: en cuanto responde,
/// la sesión verificada sustituye a la guardada.
class SessionSnapshotStore {
  static const _key = 'auth_session_snapshot';

  final SharedPreferences? _prefs;

  SessionSnapshotStore({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _store() async =>
      _prefs ?? await SharedPreferences.getInstance();

  Future<void> save(User user) async {
    final prefs = await _store();
    await prefs.setString(_key, jsonEncode(UserModel.fromEntity(user).toMap()));
  }

  /// Devuelve la sesión guardada, o null si no hay ninguna o está ilegible.
  Future<UserModel?> read() async {
    final prefs = await _store();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return UserModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Una instantánea corrupta no debe tumbar el arranque: se descarta y se
      // trata como si no hubiera sesión guardada.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _store();
    await prefs.remove(_key);
  }
}
