/// Transport boundary. Implementations: MemoryMailTransport (this package; demo
/// + tests) and ImapSmtpTransport (package mail_imap, enough_mail, blind-written
/// in Phase 4 - see docs/PHASE_4_REPORT.md).
class FolderInfo {
  final String path;
  final int uidValidity;
  final int? highestModSeq;
  const FolderInfo(this.path, this.uidValidity, {this.highestModSeq});
}

class HeaderInfo {
  final int uid;
  final String? messageId;
  final String? inReplyTo;
  final List<String> references;
  final String subject;
  final DateTime? dateUtc;
  final Set<String> flags;
  const HeaderInfo({
    required this.uid,
    this.messageId,
    this.inReplyTo,
    this.references = const [],
    this.subject = '',
    this.dateUtc,
    this.flags = const {},
  });
}

class MessageBody {
  final String? text;
  final String? html;
  const MessageBody({this.text, this.html});
}

abstract class MailTransport {
  Future<String> capabilityLine();
  Future<List<FolderInfo>> listFolders();
  Future<FolderInfo> select(String path);
  Future<List<HeaderInfo>> fetchHeaders(String path, {required int fromUid, int? limit});
  Future<void> setFlags(String path, List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}});
  /// Full body of one message (never cached to disk by the app: memory only).
  Future<MessageBody> fetchBody(String path, int uid);

  /// UIDs currently on the server (cheap) - used to detect deletions.
  Future<Set<int>> fetchUids(String path);

  /// Flags of all messages, or only those changed since [changedSinceModSeq]
  /// when the server supports CONDSTORE (the transport may return all).
  Future<Map<int, Set<String>>> fetchFlags(String path, {int? changedSinceModSeq});

  Future<void> sendPlain({
    required String fromName,
    required String fromAddress,
    required List<String> to,
    required String subject,
    required String body,
  });
}
