import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_isolation.dart';

void main() {
  test('singleton opens exactly the owned absolute filename', () async {
    final fixture = await DatabaseIsolation.create();
    final db = await fixture.database.database;
    expect(p.isAbsolute(fixture.directory.path), isTrue);
    expect(p.equals(db.path, fixture.path), isTrue);
    expect(p.equals(await fixture.factory.getDatabasesPath(),
        fixture.directory.path), isTrue);
    await fixture.dispose();
    expect(db.isOpen, isFalse);
    expect(await fixture.directory.exists(), isFalse);
  });

  test('successive fixtures never share marker data or factories', () async {
    final first = await DatabaseIsolation.create();
    final firstDb = await first.database.database;
    await firstDb.execute('CREATE TABLE isolation_marker (value TEXT)');
    await firstDb.insert('isolation_marker', {'value': 'first fixture only'});
    await first.dispose();

    final second = await DatabaseIsolation.create();
    final secondDb = await second.database.database;
    expect(second.path, isNot(first.path));
    expect(identical(second.factory, first.factory), isFalse);
    expect(await secondDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'isolation_marker'"),
        isEmpty);
  });

  for (final initialized in [false, true]) {
    test('restores ${initialized ? 'existing' : 'null'} factory and removes directory', () async {
      final original = databaseFactoryOrNull;
      addTearDown(() => databaseFactoryOrNull = original);
      final previous = initialized ? createDatabaseFactoryFfi() : null;
      databaseFactoryOrNull = previous;
      final fixture = await DatabaseIsolation.create();
      await fixture.database.database;
      await fixture.dispose();
      expect(identical(databaseFactoryOrNull, previous), isTrue);
      expect(await fixture.directory.exists(), isFalse);
      await fixture.dispose(); // Registered teardown remains safe after disposal.
      expect(identical(databaseFactoryOrNull, previous), isTrue);
    });
  }

  test('callback failure closes handles, restores factory and removes directory', () async {
    final previous = databaseFactoryOrNull;
    late DatabaseIsolation owned;
    late Database handle;
    final failure = StateError('callback failed');
    await expectLater(DatabaseIsolation.run((fixture) async {
      owned = fixture;
      handle = await fixture.openDatabase();
      throw failure;
    }), throwsA(same(failure)));
    expect(handle.isOpen, isFalse);
    expect(identical(databaseFactoryOrNull, previous), isTrue);
    expect(await owned.directory.exists(), isFalse);
  });

  test('failing resource cleanup still closes singleton and restores ownership', () async {
    final previous = databaseFactoryOrNull;
    final fixture = await DatabaseIsolation.create();
    final handle = await fixture.database.database;
    final failure = StateError('disposer failed');
    fixture.addCleanup(() {
      expect(identical(databaseFactoryOrNull, fixture.factory), isTrue);
      expect(handle.isOpen, isTrue);
      throw failure;
    });
    await expectLater(fixture.dispose(), throwsA(same(failure)));
    expect(handle.isOpen, isFalse);
    expect(identical(databaseFactoryOrNull, previous), isTrue);
    expect(await fixture.directory.exists(), isFalse);
  });
}
