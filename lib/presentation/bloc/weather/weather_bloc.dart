import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/local/weather_cache_datasource.dart';
import '../../../data/datasources/remote/weather_service.dart';
import '../../../data/models/weather_model.dart';
import '../../../core/errors/failures.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService _service;
  final WeatherCacheDataSource _cache;
  final DateTime Function() _now;

  WeatherBloc({
    required WeatherService service,
    required WeatherCacheDataSource cache,
    DateTime Function()? now,
  })  : _service = service,
        _cache = cache,
        _now = now ?? DateTime.now,
        super(const WeatherInitial()) {
    on<WeatherFetchByCity>(_onFetchByCity);
    on<WeatherFetchByCoords>(_onFetchByCoords);
  }

  /// HTTP ya es async no-bloqueante — compute() no necesario aquí
  /// (y no funciona porque http.Client no es Sendable entre isolates)
  Future<void> _onFetchByCity(
      WeatherFetchByCity e, Emitter<WeatherState> emit) async {
    emit(const WeatherLoading());
    try {
      final weather = await _service.getWeatherByCity(e.city);
      final retrievedAt = _now();
      await _cache.saveByCity(e.city, weather, retrievedAt: retrievedAt);
      emit(WeatherLoaded(weather, retrievedAt: retrievedAt));
    } on ServerException catch (ex) {
      final cached = _isRecoverableNetworkFailure(ex)
          ? await _cache.getByCity(e.city)
          : null;
      if (cached != null) {
        emit(WeatherLoaded(cached.weather,
            isStale: true, retrievedAt: cached.retrievedAt));
      } else {
        emit(WeatherError(ex.message));
      }
    } catch (ex) {
      emit(WeatherError(ex.toString()));
    }
  }

  Future<void> _onFetchByCoords(
      WeatherFetchByCoords e, Emitter<WeatherState> emit) async {
    emit(const WeatherLoading());
    try {
      final weather = await _service.getWeatherByCoords(e.lat, e.lon);
      final retrievedAt = _now();
      await _cache.saveByCoords(e.lat, e.lon, weather, retrievedAt: retrievedAt);
      emit(WeatherLoaded(weather, retrievedAt: retrievedAt));
    } on ServerException catch (ex) {
      final cached = _isRecoverableNetworkFailure(ex)
          ? await _cache.getByCoords(e.lat, e.lon)
          : null;
      if (cached != null) {
        emit(WeatherLoaded(cached.weather,
            isStale: true, retrievedAt: cached.retrievedAt));
      } else {
        emit(WeatherError(ex.message));
      }
    } catch (ex) {
      emit(WeatherError(ex.toString()));
    }
  }

  bool _isRecoverableNetworkFailure(ServerException exception) =>
      exception.message.startsWith('Sin conexión o error de red') ||
      exception.message.startsWith('Error de red');
}
