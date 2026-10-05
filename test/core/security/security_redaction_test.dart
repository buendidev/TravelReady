import 'package:flutter_test/flutter_test.dart';

import 'package:travel_ready/core/security/crypto_service.dart';
import 'package:travel_ready/core/utils/security_log.dart';

void main() {
  group('SecurityLog.sessionEvent', () {
    test('admite ids cortos y vacíos sin lanzar', () {
      expect(() => SecurityLog.sessionEvent('login_ok', 'usr-001'),
          returnsNormally);
      expect(
          () => SecurityLog.sessionEvent('login_ok', 'ab'), returnsNormally);
      expect(() => SecurityLog.sessionEvent('logout', ''), returnsNormally);
    });
  });

  group('CryptoService.hashEmailForLog', () {
    test('enmascara un correo normal conservando dominio', () {
      expect(CryptoService.hashEmailForLog('pablo@test.com'),
          'pa***lo@test.com');
    });

    test('admite local vacío o muy corto sin lanzar', () {
      expect(CryptoService.hashEmailForLog('@test.com'), '***@test.com');
      expect(CryptoService.hashEmailForLog('a@test.com'), 'a***@test.com');
      expect(CryptoService.hashEmailForLog('ab@test.com'), 'a***@test.com');
    });

    test('marca como inválido lo que no tiene forma de correo', () {
      expect(CryptoService.hashEmailForLog('sin-arroba'), 'invalid');
    });
  });
}
