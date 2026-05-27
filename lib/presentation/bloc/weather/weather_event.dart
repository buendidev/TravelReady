part of 'weather_bloc.dart';

sealed class WeatherEvent extends Equatable {
  const WeatherEvent();
  @override List<Object?> get props => [];
}

final class WeatherFetchByCity extends WeatherEvent {
  final String city;
  const WeatherFetchByCity(this.city);
  @override List<Object> get props => [city];
}

final class WeatherFetchByCoords extends WeatherEvent {
  final double lat, lon;
  const WeatherFetchByCoords(this.lat, this.lon);
  @override List<Object> get props => [lat, lon];
}
