import 'transport.dart';

class SentMessage {
  final String fromAddress;
  final List<String> to;
  final String subject;
  final String body;
  const SentMessage(this.fromAddress, this.to, this.subject, this.body);
}

/// In-memory transport: powers the demo UI and the unit tests (no network).
class MemoryMailTransport implements MailTransport {
  final String capabilities;
  final Map<String, int> _uidValidity = {};
  final Map<String, List<HeaderInfo>> _folders = {};
  final List<SentMessage> sent = [];
  int selectCalls = 0;

  MemoryMailTransport({this.capabilities = 'IMAP4rev1 IDLE'});

  void addFolder(String path, {int uidValidity = 1, List<HeaderInfo> messages = const []}) {
    _uidValidity[path] = uidValidity;
    _folders[path] = List.of(messages);
  }

  void addMessage(String path, HeaderInfo h) => _folders[path]!.add(h);
  void changeUidValidity(String path, int v) => _uidValidity[path] = v;

  @override
  Future<String> capabilityLine() async => capabilities;

  @override
  Future<List<FolderInfo>> listFolders() async =>
      [for (final e in _folders.keys) FolderInfo(e, _uidValidity[e]!)];

  @override
  Future<FolderInfo> select(String path) async {
    selectCalls++;
    final v = _uidValidity[path];
    if (v == null) throw StateError('no such folder: $path');
    return FolderInfo(path, v);
  }

  @override
  Future<List<HeaderInfo>> fetchHeaders(String path, {required int fromUid, int? limit}) async {
    final all = _folders[path]!.where((h) => h.uid >= fromUid).toList()
      ..sort((a, b) => a.uid.compareTo(b.uid));
    return limit == null ? all : all.take(limit).toList();
  }

  @override
  Future<void> setFlags(String path, List<int> uids,
      {Set<String> add = const {}, Set<String> remove = const {}}) async {
    final list = _folders[path]!;
    for (var i = 0; i < list.length; i++) {
      final h = list[i];
      if (!uids.contains(h.uid)) continue;
      list[i] = HeaderInfo(
        uid: h.uid, messageId: h.messageId, inReplyTo: h.inReplyTo,
        references: h.references, subject: h.subject, dateUtc: h.dateUtc,
        flags: {...h.flags.difference(remove), ...add},
      );
    }
  }

  @override
  Future<void> sendPlain({
    required String fromName,
    required String fromAddress,
    required List<String> to,
    required String subject,
    required String body,
  }) async {
    sent.add(SentMessage(fromAddress, List.unmodifiable(to), subject, body));
  }
}
