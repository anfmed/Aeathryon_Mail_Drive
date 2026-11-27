// BLIND-WRITTEN (no Dart toolchain was available). Every call whose exact name
// or signature was NOT seen verbatim in the enough_mail docs carries an
// `UNVERIFIED-API` marker; if `ci-imap` fails, those lines are the suspects.
// Verified in docs: ImapClient(), connectToServer(host, port, isSecure:),
// authenticateWithOAuth2(user, token), capability(), selectMailbox(box, ...),
// fetchMessages(sequence, definition), eventStream, serverInfo.
import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:mail_core/mail_core.dart';

class ImapSmtpConfig {
  final String imapHost;
  final int imapPort;
  final bool imapSecure;
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure; // true = implicit TLS (465); false = STARTTLS (587)
  final String smtpDomain;
  final String username;
  const ImapSmtpConfig({
    required this.imapHost,
    this.imapPort = 993,
    this.imapSecure = true,
    required this.smtpHost,
    this.smtpPort = 465,
    this.smtpSecure = true,
    this.smtpDomain = 'localhost',
    required this.username,
  });
}

/// [secret] returns a password/app-password, or an OAuth access token when
/// [useOAuth] is true. It is called per connection and never stored here.
class ImapSmtpTransport implements MailTransport {
  final ImapSmtpConfig config;
  final Future<String> Function() secret;
  final bool useOAuth;
  ImapClient? _imap;
  String? _selectedPath;
  final Map<String, Mailbox> _boxes = {};

  ImapSmtpTransport(this.config, this.secret, {this.useOAuth = false});

  Future<ImapClient> _client() async {
    final existing = _imap;
    if (existing != null && existing.isConnected && existing.isLoggedIn) return existing;
    final c = ImapClient(isLogEnabled: false);
    await c.connectToServer(config.imapHost, config.imapPort, isSecure: config.imapSecure);
    final s = await secret();
    if (useOAuth) {
      await c.authenticateWithOAuth2(config.username, s);
    } else {
      await c.login(config.username, s); // UNVERIFIED-API (seen in older examples)
    }
    _imap = c;
    _selectedPath = null;
    return c;
  }

  Future<void> close() async {
    final c = _imap;
    _imap = null;
    if (c != null && c.isConnected) await c.disconnect();
  }

  @override
  Future<String> capabilityLine() async {
    final c = await _client();
    final caps = await c.capability();
    return caps.map((e) => e.name).join(' '); // UNVERIFIED-API: Capability.name
  }

  @override
  Future<List<FolderInfo>> listFolders() async {
    final c = await _client();
    final boxes = await c.listMailboxes(); // UNVERIFIED-API
    _boxes
      ..clear()
      ..addEntries(boxes.map((b) => MapEntry(b.path, b))); // UNVERIFIED-API: Mailbox.path
    return [for (final b in boxes) FolderInfo(b.path, b.uidValidity ?? 0)];
  }

  @override
  Future<FolderInfo> select(String path) async {
    final c = await _client();
    if (_boxes.isEmpty) await listFolders();
    final box = _boxes[path];
    if (box == null) throw StateError('unknown mailbox: $path');
    final sel = await c.selectMailbox(box);
    _selectedPath = path;
    return FolderInfo(path, sel.uidValidity ?? 0, // UNVERIFIED-API: uidValidity
        highestModSeq: sel.highestModSequence); // UNVERIFIED-API: highestModSequence
  }

  @override
  Future<List<HeaderInfo>> fetchHeaders(String path, {required int fromUid, int? limit}) async {
    final c = await _client();
    await _ensureSelected(path);
    final seq = MessageSequence.fromRangeToLast(fromUid, isUidSequence: true); // UNVERIFIED-API
    final res = await c.uidFetchMessages(
        // UNVERIFIED-API
        seq,
        '(FLAGS BODY.PEEK[HEADER.FIELDS (MESSAGE-ID IN-REPLY-TO REFERENCES SUBJECT DATE)])');
    final out = <HeaderInfo>[];
    for (final m in res.messages) {
      out.add(HeaderInfo(
        uid: m.uid ?? 0,
        messageId: m.getHeaderValue('message-id'),
        inReplyTo: m.getHeaderValue('in-reply-to'),
        references: (m.getHeaderValue('references') ?? '')
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList(),
        subject: m.decodeSubject() ?? '',
        dateUtc: m.decodeDate()?.toUtc(),
        flags: {if (m.isSeen) 'seen', if (m.isFlagged) 'flagged'}, // UNVERIFIED-API
      ));
    }
    out.sort((a, b) => a.uid.compareTo(b.uid));
    return limit == null ? out : out.take(limit).toList(); // inefficient: server returns all; Phase 6 optimisation
  }

  Future<void> _ensureSelected(String path) async {
    if (_selectedPath != path) await select(path);
  }

  Set<String> _flagsOf(MimeMessage m) => {
        if (m.isSeen) 'seen', // UNVERIFIED-API
        if (m.isFlagged) 'flagged', // UNVERIFIED-API
        if (m.isAnswered) 'answered', // UNVERIFIED-API
      };

  @override
  Future<Set<int>> fetchUids(String path) async {
    final c = await _client();
    await _ensureSelected(path);
    final res = await c.uidSearchMessages(searchCriteria: 'ALL'); // UNVERIFIED-API
    return (res.matchingSequence?.toList() ?? const <int>[]).toSet(); // UNVERIFIED-API
  }

  @override
  Future<Map<int, Set<String>>> fetchFlags(String path, {int? changedSinceModSeq}) async {
    final c = await _client();
    await _ensureSelected(path);
    final seq = MessageSequence.fromRangeToLast(1, isUidSequence: true); // UNVERIFIED-API
    final res = await c.uidFetchMessages(seq, '(FLAGS)', // UNVERIFIED-API
        changedSinceModSequence: changedSinceModSeq);
    return {for (final m in res.messages) if (m.uid != null) m.uid!: _flagsOf(m)};
  }

  @override
  Future<MessageBody> fetchBody(String path, int uid) async {
    final c = await _client();
    await _ensureSelected(path);
    final seq = MessageSequence.fromId(uid, isUid: true); // UNVERIFIED-API
    final res = await c.uidFetchMessages(seq, '(BODY.PEEK[])'); // UNVERIFIED-API
    if (res.messages.isEmpty) throw StateError('message not found');
    final m = res.messages.first;
    return MessageBody(text: m.decodeTextPlainPart(), html: m.decodeTextHtmlPart());
  }

  @override
  Future<void> setFlags(String path, List<int> uids,
      {Set<String> add = const {}, Set<String> remove = const {}}) {
    throw UnimplementedError('setFlags: needs UID STORE; not written blind');
  }

  @override
  Future<void> sendPlain({
    required String fromName,
    required String fromAddress,
    required List<String> to,
    required String subject,
    required String body,
  }) async {
    final smtp = SmtpClient(config.smtpDomain, isLogEnabled: false);
    try {
      await smtp.connectToServer(config.smtpHost, config.smtpPort, isSecure: config.smtpSecure);
      await smtp.ehlo();
      if (!config.smtpSecure) await smtp.startTls(); // UNVERIFIED-API
      await smtp.authenticate(config.username, await secret(),
          useOAuth ? AuthMechanism.xoauth2 : AuthMechanism.plain); // UNVERIFIED-API: xoauth2
      final escaped = const HtmlEscape().convert(body);
      final builder = MessageBuilder.prepareMultipartAlternativeMessage(
          plainText: body, htmlText: '<pre>$escaped</pre>')
        ..from = [MailAddress(fromName, fromAddress)]
        ..to = [for (final t in to) MailAddress(null, t)] // UNVERIFIED-API: null name accepted
        ..subject = subject;
      final resp = await smtp.sendMessage(builder.buildMimeMessage());
      if (!resp.isOkStatus) throw StateError('SMTP send rejected');
    } finally {
      await smtp.disconnect(); // UNVERIFIED-API
    }
  }
}
