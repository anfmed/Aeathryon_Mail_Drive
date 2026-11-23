import 'package:mail_core/mail_core.dart';

const demoAccount = 'demo';

/// uid -> HTML body (demo). Real bodies come from the transport in Phase 6.
const demoBodies = <int, String>{
  1: '<p>Welcome to <b>Aethryon Mail</b>.</p><p>Remote images are never loaded.</p>'
      '<img src="http://tracker.example/p.gif"><script>alert(1)</script>',
  2: '<div>Lunch tomorrow? &amp; bring the report.</div>',
  3: '<p>Re: Lunch &mdash; sounds good.</p>',
};

MemoryMailTransport buildDemoTransport() {
  final t = MemoryMailTransport(capabilities: 'IMAP4rev1 IDLE MOVE CONDSTORE');
  t.addFolder('INBOX', uidValidity: 1, messages: [
    HeaderInfo(uid: 1, messageId: '<w@demo>', subject: 'Welcome', dateUtc: DateTime.utc(2026, 11, 1)),
    HeaderInfo(uid: 2, messageId: '<l@demo>', subject: 'Lunch?', dateUtc: DateTime.utc(2026, 11, 2)),
    HeaderInfo(uid: 3, messageId: '<r@demo>', inReplyTo: '<l@demo>', references: ['<l@demo>'],
        subject: 'Re: Lunch?', dateUtc: DateTime.utc(2026, 11, 3)),
  ]);
  return t;
}
