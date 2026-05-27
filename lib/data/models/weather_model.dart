import 'package:equatable/equatable.dart';

/// Modelo de datos del tiempo — mapeado desde OpenWeatherMap API.
class WeatherModel extends Equatable {
  final String city;
  final String country;
  final double tempCelsius;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String description;   // "cielo despejado"
  final String iconCode;      // "01d"
  final int humidity;         // %
  final double windSpeed;     // m/s
  final int visibility;       // metros

  const WeatherModel({
    required this.city,
    required this.country,
    required this.tempCelsius,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main    = json['main']    as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind    = json['wind']    as Map<String, dynamic>? ?? {};

    return WeatherModel(
      city:        json['name'] as String? ?? '',
      country:     (json['sys'] as Map<String, dynamic>?)?['country'] as String? ?? '',
      tempCelsius: (main['temp'] as num).toDouble(),
      feelsLike:   (main['feels_like'] as num).toDouble(),
      tempMin:     (main['temp_min'] as num).toDouble(),
      tempMax:     (main['temp_max'] as num).toDouble(),
      description: weather['description'] as String? ?? '',
      iconCode:    weather['icon'] as String? ?? '01d',
      humidity:    main['humidity'] as int? ?? 0,
      windSpeed:   (wind['speed'] as num?)?.toDouble() ?? 0,
      visibility:  json['visibility'] as int? ?? 10000,
    );
  }

  /// Temperatura redondeada como string. Ej: "22°C"
  String get tempDisplay => '${tempCelsius.round()}°C';
  String get feelsLikeDisplay => '${feelsLike.round()}°C';

  /// Descripción con primera letra en mayúscula.
  String get descriptionCapitalized =>
      description.isEmpty ? '' :
      description[0].toUpperCase() + description.substring(1);

  /// URL del icono de OpenWeatherMap.
  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  /// Emoji según condición climática.
  String get emoji {
    final code = iconCode.replaceAll('n', 'd');
    if (code.startsWith('01')) return '☀️';
    if (code.startsWith('02')) return '🌤️';
    if (code.startsWith('03') || code.startsWith('04')) return '☁️';
    if (code.startsWith('09') || code.startsWith('10')) return '🌧️';
    if (code.startsWith('11')) return '⛈️';
    if (code.startsWith('13')) return '🌨️';
    if (code.startsWith('50')) return '🌫️';
    return '🌡️';
  }

  @override
  List<Object?> get props =>
      [city, tempCelsius, description, iconCode, humidity];
}
