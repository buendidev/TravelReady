import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/core/utils/app_env.dart';
import 'package:travel_ready/data/models/weather_model.dart';

/// Servicio que consulta OpenWeatherMap API.
/// Docs: https://openweathermap.org/current
class WeatherService {
  final http.Client _client;
  static const _base = 'https://api.openweathermap.org/data/2.5';
  static const _lang = 'es';
  static const _units = 'metric'; // Celsius

  WeatherService({http.Client? client})
      : _client = client ?? http.Client();

  /// Obtiene el tiempo por nombre de ciudad. Ej: "Madrid" o "París, FR"
  Future<WeatherModel> getWeatherByCity(String city) async {
    if (!AppEnv.hasWeatherKey) {
      throw ServerException(
          'OPENWEATHER_API_KEY no configurada. Añádela en .env');
    }
    final uri = Uri.parse('$_base/weather').replace(queryParameters: {
      'q':     city.trim(),
      'appid': AppEnv.openWeatherKey,
      'lang':  _lang,
      'units': _units,
    });

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));

      switch (res.statusCode) {
        case 200:
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          return WeatherModel.fromJson(json);
        case 401:
          throw const ServerException('API key inválida. Revisa .env');
        case 404:
          throw ServerException('Ciudad "$city" no encontrada.');
        case 429:
          throw const ServerException('Límite de peticiones excedido.');
        default:
          throw ServerException(
              'Error del servidor: ${res.statusCode}');
      }
    } on ServerException { rethrow; }
    catch (e) {
      throw ServerException('Sin conexión o error de red: $e');
    }
  }

  /// Obtiene tiempo por coordenadas (lat/lon). Más preciso que por ciudad.
  Future<WeatherModel> getWeatherByCoords(
      double lat, double lon) async {
    if (!AppEnv.hasWeatherKey) {
      throw const ServerException('OPENWEATHER_API_KEY no configurada.');
    }
    final uri = Uri.parse('$_base/weather').replace(queryParameters: {
      'lat':   lat.toString(),
      'lon':   lon.toString(),
      'appid': AppEnv.openWeatherKey,
      'lang':  _lang,
      'units': _units,
    });

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return WeatherModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw ServerException('Error: ${res.statusCode}');
    } on ServerException { rethrow; }
    catch (e) {
      throw ServerException('Error de red: $e');
    }
  }
}
