import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const marker = 'TOP-SECRET-MARKER-123';

void main() {
  late Directory dir;
  late String path;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('aeth_db_');
    path = '${dir.path}/t.db';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('encrypted file is not plaintext; no key / wrong key fail; right key works; FTS5 works', () {
    var db = sqlite3.open(path);
    db.execute("PRAGMA key = 'correct horse battery';");
    db.execute('CREATE TABLE t(x TEXT);');
    db.execute("INSERT INTO t VALUES ('$marker');");
    db.execute('CREATE VIRTUAL TABLE f USING fts5(a);');
    db.execute("INSERT INTO f(a) VALUES ('quarterly report budget');");
    db.close();

    final bytes = File(path).readAsBytesSync();
    expect(latin1.decode(bytes.sublist(0, 15)), isNot('SQLite format 3'), reason: 'header must be encrypted');
    expect(latin1.decode(bytes).contains(marker), isFalse, reason: 'content must not appear in plaintext');

    db = sqlite3.open(path);
    expect(() => db.select('SELECT count(*) FROM t'), throwsA(isA<SqliteException>()), reason: 'no key');
    db.close();

    db = sqlite3.open(path);
    db.execute("PRAGMA key = 'wrong';");
    expect(() => db.select('SELECT count(*) FROM t'), throwsA(isA<SqliteException>()), reason: 'wrong key');
    db.close();

    db = sqlite3.open(path);
    db.execute("PRAGMA key = 'correct horse battery';");
    expect(db.select('SELECT x FROM t').first['x'], marker);
    expect(db.select("SELECT count(*) AS n FROM f WHERE f MATCH 'quarter*'").first['n'], 1);
    db.close();
  });
}
