/// Parsed IMAP CAPABILITY set. Input may be the raw response line
/// ("* CAPABILITY IMAP4rev1 IDLE ...") or just the space-separated tokens.
class ImapCapabilities {
  final Set<String> tokens; // upper-cased
  const ImapCapabilities(this.tokens);

  factory ImapCapabilities.parse(String line) {
    var s = line.trim();
    if (s.startsWith('*')) s = s.substring(1).trim();
    if (s.toUpperCase().startsWith('CAPABILITY')) s = s.substring('CAPABILITY'.length);
    final t = s
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toSet();
    return ImapCapabilities(t);
  }

  bool has(String cap) => tokens.contains(cap.toUpperCase());
  bool get idle => has('IDLE');
  bool get move => has('MOVE');
  bool get condstore => has('CONDSTORE');
  bool get qresync => has('QRESYNC') && condstore;
  bool get uidplus => has('UIDPLUS');
  bool get utf8 => has('UTF8=ACCEPT');
  bool get threadReferences => has('THREAD=REFERENCES');
  bool get xoauth2 => has('AUTH=XOAUTH2');
  bool get oauthbearer => has('AUTH=OAUTHBEARER');
  bool get loginDisabled => has('LOGINDISABLED');
}

enum SyncStrategy { qresync, condstore, uidScan }

/// Cheapest correct strategy the server supports. Never assumes support.
SyncStrategy chooseSyncStrategy(ImapCapabilities c) {
  if (c.qresync) return SyncStrategy.qresync;
  if (c.condstore) return SyncStrategy.condstore;
  return SyncStrategy.uidScan;
}

/// What the previous sync stored for a folder.
class FolderSyncState {
  final int uidValidity;
  final int? highestModSeq;
  final int? lastSeenUid;
  const FolderSyncState({required this.uidValidity, this.highestModSeq, this.lastSeenUid});
}

enum ResyncAction { incremental, fullResync }

/// RFC 3501 rule: if UIDVALIDITY changed, cached UIDs are invalid -> full resync.
ResyncAction resyncAction(FolderSyncState? stored, int serverUidValidity) {
  if (stored == null || stored.uidValidity != serverUidValidity) {
    return ResyncAction.fullResync;
  }
  return ResyncAction.incremental;
}
