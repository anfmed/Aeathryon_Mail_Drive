import 'dart:io';

import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:sqlite3/sqlite3.dart';

import 'key_manager.dart';
import 'sql.dart';

class EncryptionUnavailable implements Exception {
  final String message;
  EncryptionUnavailable(this.message);
  @override
  String toString() => 'EncryptionUnavailable($message)';
}

/// True when a cipher-enabled SQLite (SQLCipher or SQLite3MultipleCiphers) is linked.
/// Plain SQLite silently IGNORES `PRAGMA key`, so we must check explicitly.
bool cipherActive(Database db) {
  for (final p in const ['cipher_version', 'cipher']) {
    try {
      if (db.select('PRAGMA $p;').isNotEmpty) return true;
    } catch (_) {}
  }
  return false;
}

Database openDatabase(
  String path, {
  required String hexKey,
  required String schema,
  bool allowUnencrypted = false,
}) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey))
    throw ArgumentError('key must be 64 hex chars');
  final db = sqlite3.open(path);
  try {
    if (!allowUnencrypted) {
      db.execute("PRAGMA key = '$hexKey';");
      if (!cipherActive(db)) {
        throw EncryptionUnavailable(
          'This build has no database encryption; nothing will be saved to disk.',
        );
      }
    }
    db.execute('PRAGMA foreign_keys = ON;');
    final has = db.select(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name='schema_meta'",
    );
    if (has.isEmpty) {
      for (final st in splitSql(schema)) {
        db.execute(st);
      }
    }
    return db;
  } catch (_) {
    db.close();
    rethrow;
  }
}

class DbOpenResult {
  final Database? db;
  final String? problem; // human-readable; null when db != null
  final bool recreated; // key lost / file unreadable -> cache started fresh
  const DbOpenResult({this.db, this.problem, this.recreated = false});
}

Future<DbOpenResult> openAppDatabase({
  required SecureStore store,
  required String namespace,
  required String path,
  required String schema,
  bool allowUnencrypted = false,
}) async {
  final key = await DbKeyManager(store, namespace).getOrCreate();
  try {
    return DbOpenResult(
      db: openDatabase(
        path,
        hexKey: key,
        schema: schema,
        allowUnencrypted: allowUnencrypted,
      ),
    );
  } on EncryptionUnavailable catch (e) {
    return DbOpenResult(problem: e.message);
  } on SqliteException {
    // wrong/lost key or a damaged file: it is only a cache, so start fresh.
    try {
      for (final ext in const ['', '-wal', '-shm', '-journal']) {
        final f = File('$path$ext');
        if (f.existsSync()) f.deleteSync();
      }
      return DbOpenResult(
        db: openDatabase(
          path,
          hexKey: key,
          schema: schema,
          allowUnencrypted: allowUnencrypted,
        ),
        recreated: true,
      );
    } catch (_) {
      return const DbOpenResult(problem: 'Could not open the local database.');
    }
  }
}

T inTransaction<T>(Database db, T Function() body) {
  db.execute('BEGIN');
  try {
    final r = body();
    db.execute('COMMIT');
    return r;
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
