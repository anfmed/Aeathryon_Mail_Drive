import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:test/test.dart';

AccountRecord rec(String id) =>
    AccountRecord(id: id, kind: 'webdav', label: 'L$id', settings: {'url': 'https://h/', 'username': 'u'});

void main() {
  test('save/list/secret/remove round-trip', () async {
    final v = AccountVault(MemorySecureStore(), 'aethryon.drive');
    await v.save(rec('1'), secret: 'pw1');
    await v.save(rec('2'), secret: 'pw2');
    expect((await v.list()).map((e) => e.id), ['1', '2']);
    expect(await v.secret('1'), 'pw1');
    await v.remove('1');
    expect((await v.list()).map((e) => e.id), ['2']);
    expect(await v.secret('1'), isNull);
  });
  test('re-saving the same id does not duplicate', () async {
    final v = AccountVault(MemorySecureStore(), 'ns');
    await v.save(rec('1'));
    await v.save(rec('1'), secret: 'new');
    expect((await v.list()).length, 1);
    expect(await v.secret('1'), 'new');
  });
  test('Drive and Mail vaults are isolated', () async {
    final mem = MemorySecureStore();
    await AccountVault(mem, 'aethryon.drive').save(rec('1'), secret: 'x');
    expect(await AccountVault(mem, 'aethryon.mail').list(), isEmpty);
    expect(await AccountVault(mem, 'aethryon.mail').secret('1'), isNull);
  });
  test('secrets are rejected in non-secret settings', () {
    expect(() => AccountRecord(id: '1', kind: 'imap', label: 'x', settings: {'password': 'p'}), throwsArgumentError);
    expect(() => AccountRecord(id: '1', kind: 'imap', label: 'x', settings: {'accessToken': 'p'}), throwsArgumentError);
  });
}
