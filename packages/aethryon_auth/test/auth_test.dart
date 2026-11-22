import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:test/test.dart';

void main() {
  test('RFC 7636 Appendix B vector', () {
    final p = Pkce.fromVerifier('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk');
    expect(p.challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  });
  test('generated verifier length is valid', () {
    final p = Pkce.generate();
    expect(p.verifier.length, inInclusiveRange(43, 128));
    expect(p.verifier.contains('='), isFalse);
  });
  test('short verifier rejected', () {
    expect(() => Pkce.fromVerifier('short'), throwsArgumentError);
  });
  test('refresh skew', () {
    final t = TokenSet(
        accessToken: 'a', expiresAtUtc: DateTime.utc(2026, 1, 1, 0, 10));
    expect(t.needsRefresh(DateTime.utc(2026, 1, 1, 0, 0)), isFalse);
    expect(t.needsRefresh(DateTime.utc(2026, 1, 1, 0, 9, 30)), isTrue);
  });
  test('toString leaks nothing', () {
    final t = TokenSet(
        accessToken: 'SECRETTOKEN', expiresAtUtc: DateTime.utc(2026));
    expect(t.toString().contains('SECRETTOKEN'), isFalse);
  });
}
