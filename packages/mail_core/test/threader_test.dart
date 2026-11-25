import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  test('reply chain shares a thread; unrelated message does not', () {
    final t = buildThreads(const [
      MsgRef(key: '1', messageId: '<a@x>'),
      MsgRef(key: '2', messageId: '<b@x>', inReplyTo: '<a@x>', references: ['<a@x>']),
      MsgRef(key: '3', messageId: '<c@x>', inReplyTo: '<b@x>', references: ['<a@x>', '<b@x>']),
      MsgRef(key: '4', messageId: '<z@x>'),
    ]);
    expect(t['1'], t['2']);
    expect(t['2'], t['3']);
    expect(t['4'], isNot(t['1']));
  });
  test('siblings replying to a missing parent are joined', () {
    final t = buildThreads(const [
      MsgRef(key: '1', messageId: '<b@x>', inReplyTo: '<missing@x>', references: ['<missing@x>']),
      MsgRef(key: '2', messageId: '<c@x>', inReplyTo: '<missing@x>', references: ['<missing@x>']),
    ]);
    expect(t['1'], t['2']);
  });
  test('same subject alone never merges threads', () {
    final t = buildThreads(const [
      MsgRef(key: '1', messageId: '<a@x>'),
      MsgRef(key: '2', messageId: '<b@x>'),
    ]);
    expect(t['1'], isNot(t['2']));
  });
  test('message-id comparison is case/bracket-insensitive', () {
    final t = buildThreads(const [
      MsgRef(key: '1', messageId: '<A@X>'),
      MsgRef(key: '2', messageId: '<b@x>', inReplyTo: 'a@x'),
    ]);
    expect(t['1'], t['2']);
  });
}
