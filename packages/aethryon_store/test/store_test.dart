import 'dart:io';

import 'package:aethryon_auth/aethryon_auth.dart' show MemorySecureStore;
import 'package:aethryon_store/aethryon_store.dart';
import 'package:drive_core/drive_core.dart';
import 'package:mail_core/mail_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const k = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
Database memDb(String schema) =>
    openDatabase(':memory:', hexKey: k, schema: schema, allowUnencrypted: true);
RemoteNode n(
  String id,
  String parent,
  String name, {
  bool folder = false,
  int? size,
}) => RemoteNode(
  accountId: 'a',
  id: id,
  parentId: parent,
  name: name,
  isFolder: folder,
  size: size,
);

void main() {
  test('splitSql yields one statement per CREATE/INSERT/PRAGMA', () {
    for (final s in [driveSchemaV1, mailSchemaV1]) {
      final st = splitSql(s);
      final expected = RegExp(
        r'^(CREATE|INSERT|PRAGMA)',
        multiLine: true,
      ).allMatches(s).length;
      expect(st.length, expected);
      expect(st.any((e) => e.contains(';')), isFalse);
    }
  });

  test('ftsPrefixQuery quotes every token and drops operators', () {
    expect(ftsPrefixQuery('hello, World!'), '"hello"* "World"*');
    expect(ftsPrefixQuery('   '), isNull);
    expect(ftsPrefixQuery('a" OR b*'), '"a"* "OR"* "b"*');
    expect(ftsPrefixQuery('অর্থ'), '"অর্থ"*');
  });

  test(
    'key manager creates one 256-bit key per namespace and reuses it',
    () async {
      final s = MemorySecureStore();
      final a = await DbKeyManager(s, 'drive').getOrCreate();
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(a), isTrue);
      expect(await DbKeyManager(s, 'drive').getOrCreate(), a);
      expect(await DbKeyManager(s, 'mail').getOrCreate(), isNot(a));
    },
  );

  test('plain SQLite is refused unless explicitly allowed (never silent plaintext)', () {
    expect(
      () => openDatabase(':memory:', hexKey: k, schema: driveSchemaV1),
      throwsA(isA<EncryptionUnavailable>()),
    );
    expect(
      () => openDatabase(
        ':memory:',
        hexKey: 'short',
        schema: driveSchemaV1,
        allowUnencrypted: true,
      ),
      throwsArgumentError,
    );
  });

  test(
    'openAppDatabase reports the problem instead of storing plaintext',
    () async {
      final r = await openAppDatabase(
        store: MemorySecureStore(),
        namespace: 'x',
        path: ':memory:',
        schema: driveSchemaV1,
      );
      expect(r.db, isNull);
      expect(r.problem, contains('encryption'));
    },
  );

  test('a damaged cache file is recreated (it is only a cache)', () async {
    final dir = Directory.systemTemp.createTempSync('aeth_store_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/c.db';
    File(path).writeAsBytesSync(List.filled(4096, 7));
    final r = await openAppDatabase(
      store: MemorySecureStore(),
      namespace: 'x',
      path: path,
      schema: driveSchemaV1,
      allowUnencrypted: true,
    );
    expect(r.recreated, isTrue);
    expect(r.db, isNotNull);
    r.db!.close();
  });

  group('DriveStore', () {
    late DriveStore s;
    setUp(() {
      s = DriveStore(memDb(driveSchemaV1))
        ..ensureAccount('a', 'webdav', 'A')
        ..ensureAccount('b', 'webdav', 'B');
    });

    test('round trip, refresh replaces the listing, favorites survive only for kept nodes', () {
      s.saveChildren('a', '/', [
        n('/x', '/', 'x', folder: true),
        n('/f.txt', '/', 'f.txt', size: 5),
      ]);
      expect(s.children('a', '/').map((e) => e.name).toSet(), {'x', 'f.txt'});
      s.addFavorite('a', '/f.txt');
      s.addFavorite('a', '/x');
      s.saveChildren('a', '/', [n('/f.txt', '/', 'f.txt', size: 6)]);
      expect(s.children('a', '/').single.size, 6);
      expect(s.favorites('a'), {'/f.txt'});
      expect(s.hasListing('a', '/'), isTrue);
      expect(s.hasListing('a', '/nope'), isFalse);
    });

    test('search: Latin prefix, Bengali, account scoping, hostile input', () {
      s.saveChildren('a', '/', [
        n('/q', '/', 'Quarterly report.pdf'),
        n('/b', '/', 'অর্থ.txt'),
      ]);
      s.saveChildren('b', '/', [n('/q2', '/', 'quarter notes.txt')]);
      expect(s.search('quarter').length, 2);
      expect(s.search('quarter', accountId: 'a').single.id, '/q');
      expect(s.search('অর্থ').single.name, 'অর্থ.txt');
      expect(s.search('") OR 1=1 --'), isEmpty);
      expect(s.search(''), isEmpty);
    });

    test('removing an account wipes nodes and search index', () {
      s.saveChildren('a', '/', [n('/q', '/', 'secretname.txt')]);
      s.removeAccount('a');
      expect(s.children('a', '/'), isEmpty);
      expect(s.search('secretname'), isEmpty);
    });
  });

  group('SqliteMailStore', () {
    late SqliteMailStore s;
    HeaderInfo h(
      int uid, {
      String subj = 'hello',
      Set<String> flags = const {},
      String? mid,
      List<String> refs = const [],
    }) => HeaderInfo(
      uid: uid,
      subject: subj,
      flags: flags,
      messageId: mid,
      references: refs,
      dateUtc: DateTime.utc(2026, 1, 1),
    );
    setUp(() {
      s = SqliteMailStore(memDb(mailSchemaV1))
        ..registerAccount('a', 'icloud', 'a@x.y')
        ..registerAccount('b', 'icloud', 'b@x.y');
    });

    test('flag bit mapping round-trips', () {
      expect(bitsToFlags(flagsToBits({'seen', 'flagged'})), {
        'seen',
        'flagged',
      });
      expect(flagsToBits({'unknown'}), 0);
    });

    test('headers round-trip (flags, references, date) newest first', () async {
      await s.upsertHeaders('a', 'INBOX', [
        h(1, flags: {'seen'}),
        h(2, mid: '<m@x>', refs: ['<r1@x>', '<r2@x>']),
      ]);
      final l = await s.headers('a', 'INBOX');
      expect(l.map((e) => e.uid), [2, 1]);
      expect(l[1].flags, {'seen'});
      expect(l[0].references, ['<r1@x>', '<r2@x>']);
      expect(l[0].dateUtc, DateTime.utc(2026, 1, 1));
      expect(await s.uids('a', 'INBOX'), {1, 2});
    });

    test(
      'full sync service round-trip incl. flag-sync and expunge on SQLite',
      () async {
        final t = MemoryMailTransport(capabilities: 'CONDSTORE')
          ..addFolder('INBOX', uidValidity: 5, messages: [h(1), h(2), h(3)]);
        final svc = MailSyncService(t, s);
        await svc.syncFolder('a', 'INBOX');
        await t.setFlags('INBOX', [2], add: {'seen'});
        t.expunge('INBOX', 3);
        final r = await svc.syncFolder('a', 'INBOX');
        expect(r.removed, 1);
        final m = {for (final x in await s.headers('a', 'INBOX')) x.uid: x};
        expect(m.keys.toSet(), {1, 2});
        expect(m[2]!.flags, {'seen'});
        expect((await s.folderState('a', 'INBOX'))!.uidValidity, 5);
        t.changeUidValidity('INBOX', 6);
        final r2 = await svc.syncFolder('a', 'INBOX');
        expect(r2.fullResync, isTrue);
        expect((await s.uids('a', 'INBOX')).length, 2);
      },
    );

    test('search is scoped to the account; delete removes index rows; account removal wipes all', () async {
      await s.upsertHeaders('a', 'INBOX', [
        h(1, subj: 'Quarterly budget'),
        h(2, subj: 'অর্থ বাজেট'),
      ]);
      await s.upsertHeaders('b', 'INBOX', [h(1, subj: 'Quarterly other')]);
      expect(s.search('a', 'quarter').single.subject, 'Quarterly budget');
      expect(s.search('a', 'অর্থ').single.uid, 2);
      await s.deleteUids('a', 'INBOX', [1]);
      expect(s.search('a', 'quarter'), isEmpty);
      s.removeAccount('a');
      expect(await s.headers('a', 'INBOX'), isEmpty);
      expect((await s.headers('b', 'INBOX')).length, 1);
    });
  });
}
