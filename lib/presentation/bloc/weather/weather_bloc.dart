import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/weather_service.dart';
import '../../../data/models/weather_model.dart';
import '../../../core/errors/failures.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService _service;

  WeatherBloc({required WeatherService service})
      : _service = service,
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
      emit(WeatherLoaded(weather));
    } on ServerException catch (ex) {
      emit(WeatherError(ex.message));
    } catch (ex) {
      emit(WeatherError(ex.toString()));
    }
  }

  Future<void> _onFetchByCoords(
      WeatherFetchByCoords e, Emitter<WeatherState> emit) async {
    emit(const WeatherLoading());
    try {
      final weather = await _service.getWeatherByCoords(e.lat, e.lon);
      emit(WeatherLoaded(weather));
    } on ServerException catch (ex) {
      emit(WeatherError(ex.message));
    } catch (ex) {
      emit(WeatherError(ex.toString()));
    }
  }
}
