import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// APP2-3 — Guarda: todo `showModalBottomSheet(` en `lib/` debe llevar
/// `useRootNavigator: true` explícito.
///
/// Estrategia: se "enmascaran" comentarios y literales de cadena (incluyendo
/// raw, triples y `${...}`) con un autómata de estados sobre los caracteres
/// del fichero, y después se localiza cada llamada por su identificador y se
/// extrae su lista de argumentos por balance de paréntesis. Así un argumento
/// multilínea se lee completo y una ocurrencia en un comentario o dentro de
/// una cadena se ignora.

/// Sustituye por espacios todo el contenido de comentarios y cadenas
/// (incluido el código dentro de `${...}`), preservando la longitud del
/// fichero. El código real se copia tal cual.
String maskCommentsAndStrings(String src) {
  final n = src.length;
  final out = List<int>.filled(n, 0x20); // espacio

  bool isIdentChar(int c) =>
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x30 && c <= 0x39) ||
      c == 0x5F; // _
  bool isQuote(int c) => c == 0x27 || c == 0x22; // ' "

  // Pila de frames:
  //  'copy'   → código real, se copia a la salida
  //  'interp' → código dentro de ${...}, se enmascara (con profundidad)
  //  'str'    → literal de cadena, se enmascara
  final kind = <String>['copy'];
  final braceDepth = <int>[0];
  final quoteChar = <int>[0];
  final isTriple = <bool>[false];
  final isRaw = <bool>[false];

  var i = 0;
  while (i < n) {
    final c = src.codeUnitAt(i);

    switch (kind.last) {
      case 'copy':
        // Comentario de línea.
        if (c == 0x2F /* / */ && i + 1 < n && src.codeUnitAt(i + 1) == 0x2F) {
          while (i < n && src.codeUnitAt(i) != 0x0A) {
            i++; // el salto de línea se conserva
          }
          continue;
        }
        // Comentario de bloque.
        if (c == 0x2F && i + 1 < n && src.codeUnitAt(i + 1) == 0x2A /* * */) {
          i += 2;
          while (i + 1 < n &&
              !(src.codeUnitAt(i) == 0x2A && src.codeUnitAt(i + 1) == 0x2F)) {
            i++;
          }
          i = i + 2 > n ? n : i + 2;
          continue;
        }
        // Apertura de cadena.
        if (isQuote(c)) {
          final raw = i > 0 &&
              src.codeUnitAt(i - 1) == 0x72 /* r */ &&
              (i - 2 < 0 || !isIdentChar(src.codeUnitAt(i - 2)));
          final triple = i + 2 < n &&
              src.codeUnitAt(i + 1) == c &&
              src.codeUnitAt(i + 2) == c;
          kind.add('str');
          braceDepth.add(0);
          quoteChar.add(c);
          isTriple.add(triple);
          isRaw.add(raw);
          i += triple ? 3 : 1;
          continue;
        }
        out[i] = c; // código real: se copia
        i++;

      case 'interp':
        // Código dentro de ${...}: se enmascera pero hay que respetar las
        // cadenas anidadas para no contar sus llaves ni sus cierres.
        if (isQuote(c)) {
          final raw = i > 0 &&
              src.codeUnitAt(i - 1) == 0x72 /* r */ &&
              (i - 2 < 0 || !isIdentChar(src.codeUnitAt(i - 2)));
          final triple = i + 2 < n &&
              src.codeUnitAt(i + 1) == c &&
              src.codeUnitAt(i + 2) == c;
          kind.add('str');
          braceDepth.add(0);
          quoteChar.add(c);
          isTriple.add(triple);
          isRaw.add(raw);
          i += triple ? 3 : 1;
          continue;
        }
        if (c == 0x7B /* { */) braceDepth[kind.length - 1] += 1;
        if (c == 0x7D /* } */) {
          if (braceDepth[kind.length - 1] == 0) {
            kind.removeLast(); // cierra la interpolación
            braceDepth.removeLast();
            quoteChar.removeLast();
            isTriple.removeLast();
            isRaw.removeLast();
          } else {
            braceDepth[kind.length - 1] -= 1;
          }
        }
        i++;

      case 'str':
        if (!isRaw.last && c == 0x5C /* \ */) {
          i = i + 2 > n ? n : i + 2; // escapa el carácter siguiente
          continue;
        }
        // Interpolación dentro de la cadena.
        if (c == 0x24 /* $ */ && i + 1 < n && src.codeUnitAt(i + 1) == 0x7B) {
          kind.add('interp');
          braceDepth.add(0);
          quoteChar.add(0);
          isTriple.add(false);
          isRaw.add(false);
          i += 2;
          continue;
        }
        // Cierre de cadena.
        if (c == quoteChar.last) {
          if (isTriple.last) {
            if (i + 2 < n &&
                src.codeUnitAt(i + 1) == quoteChar.last &&
                src.codeUnitAt(i + 2) == quoteChar.last) {
              kind.removeLast();
              braceDepth.removeLast();
              quoteChar.removeLast();
              isTriple.removeLast();
              isRaw.removeLast();
              i += 3;
              continue;
            }
          } else {
            kind.removeLast();
            braceDepth.removeLast();
            quoteChar.removeLast();
            isTriple.removeLast();
            isRaw.removeLast();
            i++;
            continue;
          }
        }
        i++;
    }
  }
  return String.fromCharCodes(out);
}

/// Ocurrencias de `showModalBottomSheet(` en código (no en comentarios ni
/// cadenas), con el texto completo de su lista de argumentos.
List<String> findModalCalls(String src) {
  final masked = maskCommentsAndStrings(src);
  const name = 'showModalBottomSheet';
  final calls = <String>[];
  var from = 0;
  while (true) {
    final idx = masked.indexOf(name, from);
    if (idx < 0) break;
    from = idx + name.length;
    // Identificador completo (no _showModalBottomSheet ni sufijos).
    final before = idx > 0 ? masked.codeUnitAt(idx - 1) : 0x20;
    final after = from < masked.length ? masked.codeUnitAt(from) : 0x20;
    bool identChar(int c) =>
        (c >= 0x61 && c <= 0x7A) ||
        (c >= 0x41 && c <= 0x5A) ||
        (c >= 0x30 && c <= 0x39) ||
        c == 0x5F ||
        c == 0x24;
    if (identChar(before) || identChar(after)) continue;
    // Argumentos de tipo (<void>) y espacios entre el identificador y (.
    var j = from;
    while (j < masked.length && masked[j].trim().isEmpty) {
      j++;
    }
    if (j < masked.length && masked[j] == '<') {
      var angleDepth = 0;
      for (; j < masked.length; j++) {
        if (masked[j] == '<') angleDepth++;
        if (masked[j] == '>') {
          angleDepth--;
          if (angleDepth == 0) {
            j++;
            break;
          }
        }
      }
      while (j < masked.length && masked[j].trim().isEmpty) {
        j++;
      }
    }
    // Paréntesis de apertura.
    if (j >= masked.length || masked[j] != '(') continue;
    var depth = 0;
    final start = j;
    for (; j < masked.length; j++) {
      if (masked[j] == '(') depth++;
      if (masked[j] == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    if (depth != 0) continue; // paréntesis desbalanceados: no es una llamada
    calls.add(masked.substring(start + 1, j));
  }
  return calls;
}

void main() {
  group('scanner robustness', () {
    test('flags a call without useRootNavigator', () {
      const src = '''
void f(BuildContext c) {
  showModalBottomSheet<void>(
    context: c,
    builder: (_) => const SizedBox(),
  );
}
''';
      final calls = findModalCalls(src);
      expect(calls, hasLength(1));
      expect(calls.single.contains('useRootNavigator'), isFalse);
    });

    test('accepts useRootNavigator on the same line', () {
      const src = '''
void f(BuildContext c) {
  showModalBottomSheet<void>(context: c, useRootNavigator: true, builder: (_) => const SizedBox());
}
''';
      final calls = findModalCalls(src);
      expect(calls, hasLength(1));
      expect(calls.single, contains('useRootNavigator: true'));
    });

    test('accepts useRootNavigator in a multi-line argument list', () {
      const src = '''
void f(BuildContext c) {
  showModalBottomSheet<void>(
    context: c,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(1, 2, 3, 4),
      child: Text('x'),
    ),
  );
}
''';
      final calls = findModalCalls(src);
      expect(calls, hasLength(1));
      expect(calls.single, contains('useRootNavigator: true'));
    });

    test('ignores an occurrence inside a comment', () {
      const src = '''
// showModalBottomSheet(context: c, builder: (_) => SizedBox());
/* showModalBottomSheet(
   context: c,
) */
void f(BuildContext c) {}
''';
      expect(findModalCalls(src), isEmpty);
    });

    test('ignores an occurrence inside a string', () {
      const src = '''
const doc = 'llama a showModalBottomSheet(context: c) para abrir';
const doc2 = """
  showModalBottomSheet<void>(
    context: c,
  );
""";
''';
      expect(findModalCalls(src), isEmpty);
    });

    test('ignores an occurrence in string interpolation and raw strings', () {
      const src = '''
void f(String hint) {
  final msg = 'usar \${showModalBottomSheet(context: f)} aqui';
  final raw = r'showModalBottomSheet(context: c)';
  print(msg + raw);
}
''';
      expect(findModalCalls(src), isEmpty);
    });

    test('does not match identifiers that merely contain the name', () {
      const src = '''
void _showModalBottomSheetHelper(BuildContext c) {}
void g(BuildContext c) => showModalBottomSheet<void>(
      context: c,
      useRootNavigator: true,
    );
''';
      final calls = findModalCalls(src);
      expect(calls, hasLength(1));
      expect(calls.single, contains('useRootNavigator: true'));
    });
  });

  group('guard: every showModalBottomSheet in lib/ is root-scoped', () {
    final libDir = Directory('lib');
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    test('lib/ contains dart files to guard', () {
      expect(dartFiles, isNotEmpty);
    });

    for (final file in dartFiles) {
      test('${file.path} uses useRootNavigator: true on every sheet', () {
        final src = file.readAsStringSync();
        final calls = findModalCalls(src);
        for (final args in calls) {
          expect(
            RegExp(r'useRootNavigator\s*:\s*true\b').hasMatch(args),
            isTrue,
            reason: 'showModalBottomSheet en ${file.path} debe declarar '
                'useRootNavigator: true (argumentos: $args)',
          );
        }
      });
    }
  });
}
