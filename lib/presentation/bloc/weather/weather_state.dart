part of 'weather_bloc.dart';

sealed class WeatherState extends Equatable {
  const WeatherState();
  @override List<Object?> get props => [];
}

final class WeatherInitial extends WeatherState {
  const WeatherInitial();
}
final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}
final class WeatherLoaded extends WeatherState {
  final WeatherModel weather;
  final bool isStale;
  final DateTime retrievedAt;

  const WeatherLoaded(
    this.weather, {
    this.isStale = false,
    required this.retrievedAt,
  });

  @override
  List<Object> get props => [weather, isStale, retrievedAt];
}
final class WeatherError extends WeatherState {
  final String message;
  const WeatherError(this.message);
  @override List<Object> get props => [message];
}
