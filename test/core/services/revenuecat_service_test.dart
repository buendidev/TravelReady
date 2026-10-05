import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:travel_ready/core/services/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, dynamic> response;
  late List<String> calls;

  setUp(() {
    dotenv.loadFromString(envString: 'REVENUECAT_API_KEY=test-only-not-a-key');
    response = _offerings([]);
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method != 'getOfferings') {
        throw StateError('Llamada no permitida: ${call.method}');
      }
      return response;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    dotenv.clean();
    expect(calls, ['getOfferings']);
  });

  final selectors = <String, Future<Package?> Function()>{
    'monthly': RevenueCatService.getMonthlyPackage,
    'yearly': RevenueCatService.getYearlyPackage,
  };

  for (final entry in selectors.entries) {
    final period = entry.key;
    final select = entry.value;
    final otherPeriod = period == 'monthly' ? 'yearly' : 'monthly';

    group('Selección $period', () {
      test('devuelve el paquete cuando solo existe el periodo solicitado',
          () async {
        response = _offerings(['premium_$period']);

        final package = await select();

        expect(package, isNotNull);
        expect(package!.storeProduct.identifier, 'premium_$period');
        expect(package.identifier, 'package_0');
      });

      test('devuelve null cuando solo existe el otro periodo', () async {
        response = _offerings(['premium_$otherPeriod']);

        await expectLater(select(), completion(isNull));
      });

      test('devuelve null cuando los productos no coinciden', () async {
        response = _offerings(['premium_weekly', 'premium_lifetime']);

        await expectLater(select(), completion(isNull));
      });

      test('elige la primera coincidencia del producto y no el primer paquete',
          () async {
        response = _offerings([
          'premium_weekly',
          'premium_$otherPeriod',
          'travel_${period}_subscription',
          'premium_$period',
        ]);

        final package = await select();

        expect(package, isNotNull);
        expect(package!.storeProduct.identifier, 'travel_${period}_subscription');
        expect(package.identifier, 'package_2');
      });

      test('conserva la excepción cuando la oferta no tiene paquetes', () async {
        response = _offerings([]);

        await expectLater(select(), throwsA(_noOfferingsException));
      });

      test('conserva la excepción cuando no hay oferta actual', () async {
        response = {'all': <String, dynamic>{}, 'current': null};

        await expectLater(select(), throwsA(_noOfferingsException));
      });
    });
  }
}

final _noOfferingsException = isA<Exception>().having(
  (error) => error.toString(),
  'mensaje',
  'Exception: No hay ofertas disponibles',
);

Map<String, dynamic> _offerings(List<String> productIdentifiers) {
  final offering = <String, dynamic>{
    'identifier': 'test_offering',
    'serverDescription': 'Oferta de prueba',
    'metadata': <String, Object>{},
    'availablePackages': [
      for (var index = 0; index < productIdentifiers.length; index++)
        {
          'identifier': 'package_$index',
          'packageType': 'CUSTOM',
          'presentedOfferingContext': {
            'offeringIdentifier': 'test_offering',
          },
          'product': {
            'identifier': productIdentifiers[index],
            'description': 'Producto de prueba',
            'title': 'Suscripción de prueba',
            'price': 9.99,
            'priceString': '9,99 EUR',
            'currencyCode': 'EUR',
          },
        },
    ],
  };
  return {
    'all': {'test_offering': offering},
    'current': offering,
  };
}
