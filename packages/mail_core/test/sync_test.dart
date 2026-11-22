import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

HeaderInfo h(int uid, {String? mid, String? irt, List<String> refs = const []}) =>
    HeaderInfo(uid: uid, messageId: mid, inReplyTo: irt, references: refs, subject: 's$uid');

void main() {
  test('first sync fetches everything in pages; second sync fetches only new', () async {
    final t = MemoryMailTransport(capabilities: 'IMAP4rev1 CONDSTORE QRESYNC');
    t.addFolder('INBOX', uidValidity: 7, messages: [for (var i = 1; i <= 5; i++) h(i)]);
    final store = MemoryMailStore();
    final svc = MailSyncService(t, store);

    final r1 = await svc.syncFolder('a', 'INBOX', pageSize: 2);
    expect(r1.fetched, 5);
    expect(r1.fullResync, isTrue);
    expect(r1.strategy, SyncStrategy.qresync);
    expect((await store.folderState('a', 'INBOX'))!.lastSeenUid, 5);

    t.addMessage('INBOX', h(6));
    final r2 = await svc.syncFolder('a', 'INBOX');
    expect(r2.fetched, 1);
    expect(r2.fullResync, isFalse);
    expect((await store.headers('a', 'INBOX')).length, 6);
  });

  test('UIDVALIDITY change wipes cache and refetches', () async {
    final t = MemoryMailTransport();
    t.addFolder('INBOX', uidValidity: 1, messages: [h(1), h(2)]);
    final store = MemoryMailStore();
    final svc = MailSyncService(t, store);
    await svc.syncFolder('a', 'INBOX');
    t.changeUidValidity('INBOX', 2);
    final r = await svc.syncFolder('a', 'INBOX');
    expect(r.fullResync, isTrue);
    expect(r.fetched, 2);
  });

  test('empty folder leaves lastSeenUid null', () async {
    final t = MemoryMailTransport()..addFolder('INBOX');
    final store = MemoryMailStore();
    await MailSyncService(t, store).syncFolder('a', 'INBOX');
    expect((await store.folderState('a', 'INBOX'))!.lastSeenUid, isNull);
  });

  test('accounts are isolated in the store', () async {
    final t = MemoryMailTransport()..addFolder('INBOX', messages: [h(1)]);
    final store = MemoryMailStore();
    await MailSyncService(t, store).syncFolder('a', 'INBOX');
    expect(await store.headers('b', 'INBOX'), isEmpty);
  });

  test('threadHeaders groups replies', () {
    final m = threadHeaders([
      h(1, mid: '<a@x>'),
      h(2, mid: '<b@x>', irt: '<a@x>', refs: ['<a@x>']),
      h(3, mid: '<q@x>'),
    ]);
    expect(m[1], m[2]);
    expect(m[3], isNot(m[1]));
  });

  test('memory transport send is recorded', () async {
    final t = MemoryMailTransport();
    await t.sendPlain(fromName: 'A', fromAddress: 'a@x.y', to: ['b@x.y'], subject: 's', body: 'b');
    expect(t.sent.single.subject, 's');
  });
}
