import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  test('parse raw response line', () {
    final c = ImapCapabilities.parse(
      '* CAPABILITY IMAP4rev1 IDLE MOVE CONDSTORE QRESYNC UIDPLUS AUTH=XOAUTH2',
    );
    expect(c.idle && c.move && c.condstore && c.qresync && c.xoauth2, isTrue);
    expect(c.threadReferences, isFalse);
  });
  test('QRESYNC without CONDSTORE is not trusted', () {
    final c = ImapCapabilities.parse('IMAP4rev1 QRESYNC');
    expect(c.qresync, isFalse);
  });
  test('strategy picks cheapest supported', () {
    expect(
      chooseSyncStrategy(ImapCapabilities.parse('CONDSTORE QRESYNC')),
      SyncStrategy.qresync,
    );
    expect(
      chooseSyncStrategy(ImapCapabilities.parse('CONDSTORE')),
      SyncStrategy.condstore,
    );
    expect(
      chooseSyncStrategy(ImapCapabilities.parse('IMAP4rev1')),
      SyncStrategy.uidScan,
    );
  });
  test('UIDVALIDITY change forces full resync', () {
    const s = FolderSyncState(uidValidity: 5, lastSeenUid: 100);
    expect(resyncAction(s, 5), ResyncAction.incremental);
    expect(resyncAction(s, 6), ResyncAction.fullResync);
    expect(resyncAction(null, 5), ResyncAction.fullResync);
  });
}
