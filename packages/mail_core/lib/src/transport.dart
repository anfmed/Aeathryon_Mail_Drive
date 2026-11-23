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

abstract class MailTransport {
  Future<String> capabilityLine();
  Future<List<FolderInfo>> listFolders();
  Future<FolderInfo> select(String path);
  Future<List<HeaderInfo>> fetchHeaders(String path, {required int fromUid, int? limit});
  Future<void> setFlags(String path, List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}});
  Future<void> sendPlain({
    required String fromName,
    required String fromAddress,
    required List<String> to,
    required String subject,
    required String body,
  });
}
