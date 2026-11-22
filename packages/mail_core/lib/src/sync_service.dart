import 'imap_caps.dart';
import 'threader.dart';
import 'transport.dart';

abstract class MailStore {
  Future<FolderSyncState?> folderState(String accountId, String folder);
  Future<void> saveFolderState(
    String accountId,
    String folder,
    FolderSyncState s,
  );
  Future<void> clearFolder(String accountId, String folder);
  Future<void> upsertHeaders(
    String accountId,
    String folder,
    List<HeaderInfo> h,
  );
  Future<List<HeaderInfo>> headers(String accountId, String folder);
}

class MemoryMailStore implements MailStore {
  final Map<String, FolderSyncState> _state = {};
  final Map<String, Map<int, HeaderInfo>> _hdr = {};
  String _k(String a, String f) => '$a\u0000$f';

  @override
  Future<FolderSyncState?> folderState(String a, String f) async =>
      _state[_k(a, f)];
  @override
  Future<void> saveFolderState(String a, String f, FolderSyncState s) async =>
      _state[_k(a, f)] = s;
  @override
  Future<void> clearFolder(String a, String f) async {
    _state.remove(_k(a, f));
    _hdr.remove(_k(a, f));
  }

  @override
  Future<void> upsertHeaders(String a, String f, List<HeaderInfo> h) async {
    final m = _hdr.putIfAbsent(_k(a, f), () => {});
    for (final x in h) {
      m[x.uid] = x;
    }
  }

  @override
  Future<List<HeaderInfo>> headers(String a, String f) async {
    final l = (_hdr[_k(a, f)] ?? {}).values.toList()
      ..sort((x, y) => y.uid.compareTo(x.uid));
    return l;
  }
}

class SyncResult {
  final int fetched;
  final bool fullResync;
  final SyncStrategy strategy;
  const SyncResult(this.fetched, this.fullResync, this.strategy);
}

/// Phase 4 scope: discovers NEW messages (uid scan) and handles UIDVALIDITY
/// resets. Flag-change/expunge sync via CONDSTORE/QRESYNC is NOT implemented yet
/// (strategy is detected and reported, but only the uid-scan path runs).
class MailSyncService {
  final MailTransport transport;
  final MailStore store;
  MailSyncService(this.transport, this.store);

  Future<SyncResult> syncFolder(
    String accountId,
    String path, {
    int pageSize = 200,
  }) async {
    if (pageSize < 1) throw ArgumentError('pageSize must be >= 1');
    final caps = ImapCapabilities.parse(await transport.capabilityLine());
    final strategy = chooseSyncStrategy(caps);
    final info = await transport.select(path);
    final stored = await store.folderState(accountId, path);
    final action = resyncAction(stored, info.uidValidity);

    var maxUid = 0;
    var from = 1;
    if (action == ResyncAction.fullResync) {
      await store.clearFolder(accountId, path);
    } else {
      maxUid = stored!.lastSeenUid ?? 0;
      from = maxUid + 1;
    }

    var fetched = 0;
    while (true) {
      final batch = await transport.fetchHeaders(
        path,
        fromUid: from,
        limit: pageSize,
      );
      if (batch.isEmpty) break;
      await store.upsertHeaders(accountId, path, batch);
      fetched += batch.length;
      for (final h in batch) {
        if (h.uid > maxUid) maxUid = h.uid;
      }
      if (batch.length < pageSize) break;
      from = maxUid + 1;
    }

    await store.saveFolderState(
      accountId,
      path,
      FolderSyncState(
        uidValidity: info.uidValidity,
        highestModSeq: info.highestModSeq,
        lastSeenUid: maxUid == 0 ? null : maxUid,
      ),
    );
    return SyncResult(fetched, action == ResyncAction.fullResync, strategy);
  }
}

/// message uid -> thread id, using the pure threader.
Map<int, String> threadHeaders(List<HeaderInfo> headers) {
  final t = buildThreads([
    for (final h in headers)
      MsgRef(
        key: '${h.uid}',
        messageId: h.messageId,
        inReplyTo: h.inReplyTo,
        references: h.references,
      ),
  ]);
  return {for (final h in headers) h.uid: t['${h.uid}']!};
}
