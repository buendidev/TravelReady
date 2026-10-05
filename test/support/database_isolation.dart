import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_ready/core/database/database_helper.dart';

/// Serial, test-only ownership of the global factory and singleton connection.
/// Never resolves or deletes the default database directory.
class DatabaseIsolation {
  DatabaseIsolation._(this.directory, this.factory, this._previousFactory);

  final Directory directory;
  final DatabaseFactory factory;
  final DatabaseFactory? _previousFactory;
  final _cleanups = <FutureOr<void> Function()>[];
  final _handles = <Database>[];
  bool _disposed = false;

  DatabaseHelper get database => DatabaseHelper();
  String get path => p.join(directory.path, 'travelready.db');

  static Future<DatabaseIsolation> create() async {
    sqfliteFfiInit();
    final previous = databaseFactoryOrNull;
    final factory = createDatabaseFactoryFfi();
    final directory = await Directory.systemTemp.createTemp('travelready_test_');
    final fixture = DatabaseIsolation._(directory.absolute, factory, previous);
    // Register immediately, including when subsequent setup fails.
    addTearDown(fixture.dispose);
    try {
      await factory.setDatabasesPath(fixture.directory.path);
      // Close any prior singleton handle without opening or resolving a path.
      await fixture.database.close();
      databaseFactoryOrNull = factory;
      return fixture;
    } catch (_) {
      await fixture.dispose();
      rethrow;
    }
  }

  static Future<T> run<T>(Future<T> Function(DatabaseIsolation) callback) async {
    final fixture = await create();
    try {
      return await callback(fixture);
    } finally {
      await fixture.dispose();
    }
  }

  /// Register immediately after acquiring a datasource or other resource.
  void addCleanup(FutureOr<void> Function() cleanup) => _cleanups.add(cleanup);

  /// Opens only the captured owned filename; tracks migration/reopen handles.
  Future<Database> openDatabase({OpenDatabaseOptions? options}) async {
    final handle = await factory.openDatabase(path, options: options);
    _handles.add(handle);
    return handle;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _disposeResources(_cleanups.length - 1);
    } finally {
      try {
        await database.close();
      } finally {
        try {
          await _closeHandles(_handles.length - 1);
        } finally {
          try {
            databaseFactoryOrNull = _previousFactory;
          } finally {
            // Only this uniquely created directory is ever removed.
            if (await directory.exists()) {
              await directory.delete(recursive: true);
            }
          }
        }
      }
    }
  }

  Future<void> _disposeResources(int index) async {
    if (index < 0) return;
    try {
      await _cleanups[index]();
    } finally {
      await _disposeResources(index - 1);
    }
  }

  Future<void> _closeHandles(int index) async {
    if (index < 0) return;
    try {
      if (_handles[index].isOpen) await _handles[index].close();
    } finally {
      await _closeHandles(index - 1);
    }
  }
}
