import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ready/core/utils/input_sanitizer.dart';
import 'package:travel_ready/core/utils/rate_limiter.dart';

void main() {
  // ── InputSanitizer ────────────────────────────────────────────────────────

  group('InputSanitizer.sanitize', () {
    test('elimina caracteres < > " y null byte', () {
      expect(
        InputSanitizer.sanitize('<script>"alert"</script>\x00'),
        'scriptalert/script',
      );
    });

    test('trim espacios al inicio y fin', () {
      expect(InputSanitizer.sanitize('  hello  '), 'hello');
    });

    test('texto normal no se modifica', () {
      expect(InputSanitizer.sanitize('Pasaporte'), 'Pasaporte');
    });

    test('sanitizeTruncate recorta a maxLength', () {
      final long = 'a' * 100;
      expect(InputSanitizer.sanitizeTruncate(long, 20).length, 20);
    });

    test('sanitizeTruncate no recorta si está dentro del límite', () {
      expect(InputSanitizer.sanitizeTruncate('hola', 80), 'hola');
    });
  });

  group('InputSanitizer.isValidEmail', () {
    test('email correcto → true', () {
      expect(InputSanitizer.isValidEmail('pablo@travelready.com'), true);
    });

    test('email sin @ → false', () {
      expect(InputSanitizer.isValidEmail('pablotravelready.com'), false);
    });

    test('email sin dominio → false', () {
      expect(InputSanitizer.isValidEmail('pablo@'), false);
    });

    test('email con TLD de 1 char → false', () {
      expect(InputSanitizer.isValidEmail('pablo@test.c'), false);
    });
  });

  group('InputSanitizer.isValidPassword', () {
    test('≥6 chars → true', () {
      expect(InputSanitizer.isValidPassword('abc123'), true);
    });

    test('<6 chars → false', () {
      expect(InputSanitizer.isValidPassword('abc'), false);
    });

    test('exactamente 6 → true', () {
      expect(InputSanitizer.isValidPassword('123456'), true);
    });
  });

  group('InputSanitizer.isValidName', () {
    test('nombre correcto → true', () {
      expect(InputSanitizer.isValidName('Pablo Buendicho'), true);
    });

    test('nombre de 1 char → false', () {
      expect(InputSanitizer.isValidName('P'), false);
    });

    test('nombre con <> → false', () {
      expect(InputSanitizer.isValidName('<script>'), false);
    });

    test('nombre de 60 chars → true', () {
      expect(InputSanitizer.isValidName('A' * 60), true);
    });

    test('nombre de 61 chars → false', () {
      expect(InputSanitizer.isValidName('A' * 61), false);
    });
  });

  group('InputSanitizer.isValidTripName', () {
    test('nombre de viaje normal → true', () {
      expect(InputSanitizer.isValidTripName('Viaje a París'), true);
    });

    test('cadena vacía → false', () {
      expect(InputSanitizer.isValidTripName(''), false);
    });

    test('más de 80 chars → false', () {
      expect(InputSanitizer.isValidTripName('A' * 81), false);
    });
  });

  // ── RateLimiter ───────────────────────────────────────────────────────────

  group('RateLimiter', () {
    setUp(() {
      // Limpiar estado entre tests
      RateLimiter.clear('test_key');
      RateLimiter.clear('auth_key');
    });

    test('permite primeros intentos dentro del límite', () {
      for (var i = 0; i < 5; i++) {
        expect(RateLimiter.check('test_key'), true,
            reason: 'intento $i debería permitirse');
      }
    });

    test('bloquea tras 5 intentos auth', () {
      for (var i = 0; i < 5; i++) {
        RateLimiter.check('auth_key', isAuth: true);
      }
      expect(RateLimiter.check('auth_key', isAuth: true), false);
    });

    test('clear() resetea el contador', () {
      for (var i = 0; i < 5; i++) {
        RateLimiter.check('auth_key', isAuth: true);
      }
      RateLimiter.clear('auth_key');
      expect(RateLimiter.check('auth_key', isAuth: true), true);
    });

    test('secondsUntilReset devuelve 0 si no hay intentos', () {
      expect(
        RateLimiter.secondsUntilReset('nuevo_key', isAuth: true),
        0,
      );
    });

    test('keys diferentes no se interfieren', () {
      for (var i = 0; i < 5; i++) {
        RateLimiter.check('key_a', isAuth: true);
      }
      // key_a bloqueada pero key_b libre
      expect(RateLimiter.check('key_a', isAuth: true), false);
      expect(RateLimiter.check('key_b', isAuth: true), true);
      RateLimiter.clear('key_a');
      RateLimiter.clear('key_b');
    });
  });
}
