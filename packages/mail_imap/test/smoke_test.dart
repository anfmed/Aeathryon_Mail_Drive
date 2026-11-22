import 'package:mail_imap/mail_imap.dart';
import 'package:test/test.dart';

void main() {
  test('config defaults are TLS-on', () {
    const c = ImapSmtpConfig(imapHost: 'h', smtpHost: 's', username: 'u');
    expect(c.imapSecure, isTrue);
    expect(c.smtpSecure, isTrue);
    expect(c.imapPort, 993);
  });
}
