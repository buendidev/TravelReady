import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/data/models/weather_model.dart';

/// A network reading and the instant it was retrieved, not the time of replay.
class CachedWeather {
  final WeatherModel weather;
  final DateTime retrievedAt;

  const CachedWeather(this.weather, this.retrievedAt);
}

/// Stores one replaceable OpenWeatherMap reading per requested location.
/// The injected opener allows tests to exercise SQL calls without opening the
/// application's singleton database.
class WeatherCacheDataSource {
  final Future<Database> Function() openDatabase;

  WeatherCacheDataSource({Future<Database> Function()? openDatabase})
      : openDatabase = openDatabase ?? (() => DatabaseHelper().database);

  static String _cityKey(String city) {
    final normalized = city.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(city, 'city', 'Must not be empty');
    }
    return 'city:$normalized';
  }

  static String _coordsKey(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Coordinates must be finite and within geographic bounds');
    }
    // Preserve precision: nearby requests must not silently share a reading.
    final lat = latitude == 0 ? 0.0 : latitude;
    final lon = longitude == 0 ? 0.0 : longitude;
    return 'coords:$lat,$lon';
  }

  Future<void> saveByCity(String city, WeatherModel weather,
          {required DateTime retrievedAt}) =>
      _save(_cityKey(city), weather, retrievedAt);

  Future<void> saveByCoords(
          double latitude, double longitude, WeatherModel weather,
          {required DateTime retrievedAt}) =>
      _save(_coordsKey(latitude, longitude), weather, retrievedAt);

  Future<CachedWeather?> getByCity(String city) => _get(_cityKey(city));

  Future<CachedWeather?> getByCoords(double latitude, double longitude) =>
      _get(_coordsKey(latitude, longitude));

  Future<void> _save(String key, WeatherModel weather, DateTime retrievedAt) async {
    final db = await openDatabase();
    await db.insert(DatabaseHelper.tableWeatherCache, {
      'location_key': key,
      'weather_json': jsonEncode({
        'city': weather.city,
        'country': weather.country,
        'tempCelsius': weather.tempCelsius,
        'feelsLike': weather.feelsLike,
        'tempMin': weather.tempMin,
        'tempMax': weather.tempMax,
        'description': weather.description,
        'iconCode': weather.iconCode,
        'humidity': weather.humidity,
        'windSpeed': weather.windSpeed,
        'visibility': weather.visibility,
      }),
      'retrieved_at': retrievedAt.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CachedWeather?> _get(String key) async {
    final db = await openDatabase();
    final rows = await db.query(DatabaseHelper.tableWeatherCache,
        where: 'location_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.single;
    final json = jsonDecode(row['weather_json'] as String) as Map<String, dynamic>;
    return CachedWeather(
      WeatherModel(
        city: json['city'] as String,
        country: json['country'] as String,
        tempCelsius: (json['tempCelsius'] as num).toDouble(),
        feelsLike: (json['feelsLike'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        tempMax: (json['tempMax'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['iconCode'] as String,
        humidity: json['humidity'] as int,
        windSpeed: (json['windSpeed'] as num).toDouble(),
        visibility: json['visibility'] as int,
      ),
      DateTime.parse(row['retrieved_at'] as String),
    );
  }
}
