import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:travel_ready/core/network/connectivity_checker.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late ConnectivityChecker checker;
  late MockConnectivity mockConn;

  setUp(() {
    mockConn = MockConnectivity();
    checker  = ConnectivityChecker(connectivity: mockConn);
  });

  group('ConnectivityChecker', () {
    test('isConnected → true con wifi', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await checker.isConnected, true);
    });

    test('isConnected → true con datos móviles', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);
      expect(await checker.isConnected, true);
    });

    test('isConnected → true con ethernet', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.ethernet]);
      expect(await checker.isConnected, true);
    });

    test('isConnected → false sin conexión', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await checker.isConnected, false);
    });

    test('isConnected → true con múltiples resultados incluyendo wifi', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [
            ConnectivityResult.none,
            ConnectivityResult.wifi,
          ]);
      expect(await checker.isConnected, true);
    });
  });
}
