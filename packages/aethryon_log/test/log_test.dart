import 'package:aethryon_log/aethryon_log.dart';
import 'package:test/test.dart';

void main() {
  test('bearer, kv, json, email, opaque are redacted', () {
    final out = Redactor.redact(
        'GET Authorization: Bearer abc.def-123 user a.b@example.com '
        'access_token=XYZ123 {"refresh_token":"secretvalue"} '
        'id=0123456789abcdef0123456789abcdef01');
    expect(out.contains('abc.def-123'), isFalse);
    expect(out.contains('example.com'), isFalse);
    expect(out.contains('XYZ123'), isFalse);
    expect(out.contains('secretvalue'), isFalse);
    expect(out.contains('0123456789abcdef0123456789abcdef01'), isFalse);
  });
  test('level filter', () {
    final lines = <String>[];
    RedactingLogger(lines.add, min: LogLevel.warn)
      ..log(LogLevel.info, 'x')
      ..log(LogLevel.error, 'y');
    expect(lines, ['[error] y']);
  });
}
