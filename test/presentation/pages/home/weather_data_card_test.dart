import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/data/models/weather_model.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/pages/home/home_page.dart';

const _weather = WeatherModel(
  city: 'Madrid',
  country: 'ES',
  tempCelsius: 22.5,
  feelsLike: 21.0,
  tempMin: 18.0,
  tempMax: 25.0,
  description: 'cielo despejado',
  iconCode: '01d',
  humidity: 45,
  windSpeed: 3.2,
  visibility: 10000,
);

void main() {
  testWidgets('shows the localized stale weather age', (tester) async {
    final retrievedAt = DateTime.utc(2026, 4, 1, 12);
    final currentTime = DateTime.utc(2026, 4, 1, 12, 5);

    Future<void> pump(Locale locale) => tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeatherDataCard(
                weather: _weather,
                isStale: true,
                retrievedAt: retrievedAt,
                currentTime: currentTime,
                onRefresh: (_) {},
              ),
            ),
          ),
        );

    await pump(const Locale('es'));
    expect(find.text('Datos sin actualizar · hace 5 min'), findsOneWidget);

    await pump(const Locale('en'));
    expect(find.text('Stale data · 5 min ago'), findsOneWidget);
  });
}
