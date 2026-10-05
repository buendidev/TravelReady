import 'package:flutter_test/flutter_test.dart';

import 'package:travel_ready/core/utils/name_display.dart';

void main() {
  group('nameTokens', () {
    test('no devuelve tokens para nombres vacíos o sólo con espacios', () {
      expect(nameTokens(''), isEmpty);
      expect(nameTokens('   '), isEmpty);
      expect(nameTokens('\t\n '), isEmpty);
    });

    test('trata cualquier secuencia de espacios como separador', () {
      expect(nameTokens('Ana  Pérez'), ['Ana', 'Pérez']);
      expect(nameTokens('  Ana Pérez  '), ['Ana', 'Pérez']);
      expect(nameTokens('\tAna\tPérez\nLópez\n'), ['Ana', 'Pérez', 'López']);
      expect(nameTokens('Ana'), ['Ana']);
    });
  });

  group('nameInitials', () {
    test('usa hasta los dos primeros tokens', () {
      expect(nameInitials('Ana  Pérez'), 'AP');
      expect(nameInitials('Ana Pérez López'), 'AP');
      expect(nameInitials('  Ana  '), 'A');
      expect(nameInitials('\tAna\tPérez\n'), 'AP');
    });

    test('cae al valor por defecto cuando no hay token utilizable', () {
      expect(nameInitials(''), 'U');
      expect(nameInitials('   '), 'U');
      expect(nameInitials('\t\n '), 'U');
      expect(nameInitials('   ', fallback: '?'), '?');
    });
  });
}
