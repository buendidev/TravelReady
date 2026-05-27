import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/presentation/bloc/weather/weather_bloc.dart';
import 'package:travel_ready/data/datasources/remote/weather_service.dart';
import 'package:travel_ready/data/models/weather_model.dart';
import 'package:travel_ready/core/errors/failures.dart';

// ── Mock ──────────────────────────────────────────────────────────────────
class MockWeatherService extends Mock implements WeatherService {}

// ── Datos de prueba ────────────────────────────────────────────────────────
final tWeather = WeatherModel(
  city:        'Madrid',
  country:     'ES',
  tempCelsius: 22.5,
  feelsLike:   21.0,
  tempMin:     18.0,
  tempMax:     25.0,
  description: 'cielo despejado',
  iconCode:    '01d',
  humidity:    45,
  windSpeed:   3.2,
  visibility:  10000,
);

void main() {
  late WeatherBloc bloc;
  late MockWeatherService service;

  setUp(() {
    service = MockWeatherService();
    bloc    = WeatherBloc(service: service);
  });

  tearDown(() => bloc.close());

  // ── WeatherFetchByCity ────────────────────────────────────────────────────

  group('WeatherFetchByCity', () {
    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Loaded] en éxito',
      build: () {
        when(() => service.getWeatherByCity('Madrid'))
            .thenAnswer((_) async => tWeather);
        return bloc;
      },
      act: (b) => b.add(const WeatherFetchByCity('Madrid')),
      expect: () => [
        const WeatherLoading(),
        WeatherLoaded(tWeather),
      ],
    );

    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Error] con ciudad no encontrada',
      build: () {
        when(() => service.getWeatherByCity(any()))
            .thenThrow(const ServerException('Ciudad "xyz" no encontrada.'));
        return bloc;
      },
      act: (b) => b.add(const WeatherFetchByCity('xyz')),
      expect: () => [
        const WeatherLoading(),
        const WeatherError('Ciudad "xyz" no encontrada.'),
      ],
    );

    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Error] sin API key',
      build: () {
        when(() => service.getWeatherByCity(any()))
            .thenThrow(const ServerException(
                'OPENWEATHER_API_KEY no configurada. Añádela en .env'));
        return bloc;
      },
      act: (b) => b.add(const WeatherFetchByCity('Madrid')),
      expect: () => [
        const WeatherLoading(),
        const WeatherError(
            'OPENWEATHER_API_KEY no configurada. Añádela en .env'),
      ],
    );

    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Error] sin conexión',
      build: () {
        when(() => service.getWeatherByCity(any()))
            .thenThrow(const ServerException('Sin conexión o error de red'));
        return bloc;
      },
      act: (b) => b.add(const WeatherFetchByCity('Madrid')),
      expect: () => [
        const WeatherLoading(),
        const WeatherError('Sin conexión o error de red'),
      ],
    );
  });

  // ── WeatherFetchByCoords ──────────────────────────────────────────────────

  group('WeatherFetchByCoords', () {
    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Loaded] con coordenadas correctas',
      build: () {
        when(() => service.getWeatherByCoords(40.4, -3.7))
            .thenAnswer((_) async => tWeather);
        return bloc;
      },
      act: (b) => b.add(const WeatherFetchByCoords(40.4, -3.7)),
      expect: () => [
        const WeatherLoading(),
        WeatherLoaded(tWeather),
      ],
    );
  });

  // ── WeatherState equatable ────────────────────────────────────────────────

  group('WeatherState', () {
    test('WeatherLoaded con mismo weather son iguales', () {
      expect(WeatherLoaded(tWeather), equals(WeatherLoaded(tWeather)));
    });

    test('WeatherError con mismo mensaje son iguales', () {
      const s1 = WeatherError('error');
      const s2 = WeatherError('error');
      expect(s1, equals(s2));
    });

    test('WeatherLoading son iguales', () {
      expect(const WeatherLoading(), equals(const WeatherLoading()));
    });
  });

  // ── WeatherModel ──────────────────────────────────────────────────────────

  group('WeatherModel', () {
    test('tempDisplay muestra grados redondeados', () {
      expect(tWeather.tempDisplay, '23°C'); // 22.5 → 23
    });

    test('emoji para cielo despejado es ☀️', () {
      expect(tWeather.emoji, '☀️');
    });

    test('descriptionCapitalized tiene primera letra en mayúscula', () {
      expect(tWeather.descriptionCapitalized, 'Cielo despejado');
    });

    test('iconUrl apunta a openweathermap', () {
      expect(tWeather.iconUrl,
          contains('openweathermap.org/img/wn/01d@2x.png'));
    });

    test('fromJson parsea correctamente', () {
      final json = {
        'name': 'Sevilla',
        'sys': {'country': 'ES'},
        'main': {
          'temp': 32.1,
          'feels_like': 31.0,
          'temp_min': 28.0,
          'temp_max': 35.0,
          'humidity': 30,
        },
        'weather': [
          {'description': 'soleado', 'icon': '01d'}
        ],
        'wind': {'speed': 2.1},
        'visibility': 10000,
      };
      final model = WeatherModel.fromJson(json);
      expect(model.city,        'Sevilla');
      expect(model.tempCelsius, 32.1);
      expect(model.humidity,    30);
      expect(model.iconCode,    '01d');
    });
  });
}
