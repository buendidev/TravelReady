import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:travel_ready/core/database/database_helper.dart';
import 'package:travel_ready/data/datasources/local/weather_cache_datasource.dart';
import 'package:travel_ready/data/models/weather_model.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabase db;
  late WeatherCacheDataSource cache;
  late Map<String, Object?> rows;

  const weather = WeatherModel(
    city: 'Madrid', country: 'ES', tempCelsius: 22.5, feelsLike: 21.0,
    tempMin: 18, tempMax: 25, description: 'despejado', iconCode: '01d',
    humidity: 45, windSpeed: 3.2, visibility: 10000,
  );
  final fetchedAt = DateTime.utc(2026, 4, 2, 10, 30);

  setUpAll(() => registerFallbackValue(ConflictAlgorithm.replace));
  setUp(() {
    db = MockDatabase();
    rows = {};
    cache = WeatherCacheDataSource(openDatabase: () async => db);
    when(() => db.insert(
      DatabaseHelper.tableWeatherCache, any(),
      conflictAlgorithm: any(named: 'conflictAlgorithm'),
    )).thenAnswer((invocation) async {
      final row = invocation.positionalArguments[1] as Map<String, Object?>;
      rows[row['location_key'] as String] = Map<String, Object?>.of(row);
      return 1;
    });
    when(() => db.query(
      DatabaseHelper.tableWeatherCache,
      where: 'location_key = ?', whereArgs: any(named: 'whereArgs'), limit: 1,
    )).thenAnswer((invocation) async {
      final key = (invocation.namedArguments[#whereArgs] as List).single;
      final row = rows[key];
      return row == null ? [] : [Map<String, Object?>.of(row as Map<String, Object?>)];
    });
  });

  test('city cache round-trips every weather field, timestamp, and normalized key', () async {
    await cache.saveByCity('  MADRID  ', weather, retrievedAt: fetchedAt);
    final result = await cache.getByCity('madrid');
    expect(rows.keys, ['city:madrid']);
    expect(result?.retrievedAt, fetchedAt);
    expect(result?.weather.city, weather.city);
    expect(result?.weather.country, weather.country);
    expect(result?.weather.tempCelsius, weather.tempCelsius);
    expect(result?.weather.feelsLike, weather.feelsLike);
    expect(result?.weather.tempMin, weather.tempMin);
    expect(result?.weather.tempMax, weather.tempMax);
    expect(result?.weather.description, weather.description);
    expect(result?.weather.iconCode, weather.iconCode);
    expect(result?.weather.humidity, weather.humidity);
    expect(result?.weather.windSpeed, weather.windSpeed);
    expect(result?.weather.visibility, weather.visibility);
  });

  test('coordinate entries remain distinct from city and other coordinates', () async {
    await cache.saveByCoords(40.4168, -3.7038, weather, retrievedAt: fetchedAt);
    expect((await cache.getByCoords(40.4168, -3.7038))?.weather.city, 'Madrid');
    expect(await cache.getByCoords(40.4169, -3.7038), isNull);
    expect(await cache.getByCity('Madrid'), isNull);
    expect(rows.keys.single, 'coords:40.4168,-3.7038');
  });

  test('city whitespace and signed zero coordinates normalize consistently', () async {
    await cache.saveByCity(' New   York ', weather, retrievedAt: fetchedAt);
    await cache.saveByCoords(-0.0, 0, weather, retrievedAt: fetchedAt);
    expect((await cache.getByCity('new york'))?.retrievedAt, fetchedAt);
    expect((await cache.getByCoords(0, -0.0))?.retrievedAt, fetchedAt);
    expect(rows.keys, containsAll(['city:new york', 'coords:0.0,0.0']));
  });

  test('invalid locations are rejected before database access', () async {
    expect(() => cache.getByCity('  '), throwsArgumentError);
    expect(() => cache.getByCoords(double.nan, 0), throwsArgumentError);
    expect(() => cache.getByCoords(91, 0), throwsArgumentError);
    verifyNever(() => db.query(DatabaseHelper.tableWeatherCache,
        where: 'location_key = ?', whereArgs: any(named: 'whereArgs'), limit: 1));
  });

  test('upsert replaces only the matching city and unknown city stays absent', () async {
    await cache.saveByCity('Madrid', weather, retrievedAt: fetchedAt);
    await cache.saveByCity('Sevilla', weather, retrievedAt: fetchedAt);
    final later = fetchedAt.add(const Duration(hours: 2));
    await cache.saveByCity(' madrid ', weather, retrievedAt: later);
    expect(rows.length, 2);
    expect((await cache.getByCity('MADRID'))?.retrievedAt, later);
    expect((await cache.getByCity('Sevilla'))?.retrievedAt, fetchedAt);
    expect(await cache.getByCity('Barcelona'), isNull);
  });
}
