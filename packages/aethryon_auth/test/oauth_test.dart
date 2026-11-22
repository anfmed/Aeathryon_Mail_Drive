import 'dart:convert';
import 'dart:io';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final token = Uri.parse('https://idp.example/token');
  final now = DateTime.utc(2026, 1, 1);

  test('authorization URL carries PKCE S256 + state', () {
    final p = Pkce.fromVerifier('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk');
    final u = buildAuthorizationUrl(
      endpoint: Uri.parse('https://idp.example/auth'),
      clientId: 'cid',
      redirectUri: Uri.parse('http://127.0.0.1:5555/callback'),
      scopes: ['a', 'b'],
      state: 'st',
      pkce: p,
    );
    expect(
      u.queryParameters['code_challenge'],
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
    expect(u.queryParameters['code_challenge_method'], 'S256');
    expect(u.queryParameters['scope'], 'a b');
    expect(u.queryParameters['state'], 'st');
    expect(u.queryParameters.containsKey('code_verifier'), isFalse);
  });

  test('state verification', () {
    expect(verifyState('abc', 'abc'), isTrue);
    expect(verifyState('abc', 'abd'), isFalse);
    expect(verifyState('abc', null), isFalse);
    expect(verifyState('abc', 'abcd'), isFalse);
  });

  test('exchangeCode sends verifier, parses tokens', () async {
    late http.BaseRequest seen;
    late String body;
    final c = MockClient((req) async {
      seen = req;
      body = req.body;
      return http.Response(
        jsonEncode({
          'access_token': 'AT',
          'refresh_token': 'RT',
          'expires_in': 100,
          'scope': 'a b',
        }),
        200,
      );
    });
    final t = await exchangeCode(
      client: c,
      tokenEndpoint: token,
      clientId: 'cid',
      code: 'CODE',
      redirectUri: Uri.parse('http://127.0.0.1:1/callback'),
      codeVerifier: 'VER',
      nowUtc: () => now,
    );
    expect(seen.method, 'POST');
    final f = Uri.splitQueryString(body);
    expect(f['grant_type'], 'authorization_code');
    expect(f['code_verifier'], 'VER');
    expect(f.containsKey('client_secret'), isFalse);
    expect(t.accessToken, 'AT');
    expect(t.refreshToken, 'RT');
    expect(t.expiresAtUtc, now.add(const Duration(seconds: 100)));
    expect(t.scopes, ['a', 'b']);
  });

  test('refresh keeps old refresh token when server omits it', () async {
    final c = MockClient(
      (_) async => http.Response(
        jsonEncode({'access_token': 'AT2', 'expires_in': 60}),
        200,
      ),
    );
    final t = await refreshTokens(
      client: c,
      tokenEndpoint: token,
      clientId: 'cid',
      refreshToken: 'OLD',
      nowUtc: () => now,
    );
    expect(t.refreshToken, 'OLD');
  });

  test('errors never echo the response body', () async {
    final c = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': 'invalid_grant',
          'error_description': 'expired',
          'refresh_token': 'LEAK',
        }),
        400,
      ),
    );
    try {
      await refreshTokens(
        client: c,
        tokenEndpoint: token,
        clientId: 'cid',
        refreshToken: 'OLD',
      );
      fail('should throw');
    } on OAuthError catch (e) {
      expect(e.code, 'invalid_grant');
      expect(e.toString().contains('LEAK'), isFalse);
    }
  });

  test('non-JSON response is an OAuthError', () async {
    final c = MockClient((_) async => http.Response('<html>oops</html>', 502));
    await expectLater(
      refreshTokens(
        client: c,
        tokenEndpoint: token,
        clientId: 'x',
        refreshToken: 'y',
      ),
      throwsA(isA<OAuthError>()),
    );
  });

  test('SecureTokenStore round-trip and namespace isolation', () async {
    final mem = MemorySecureStore();
    final drive = SecureTokenStore(mem, 'aethryon.drive');
    final mail = SecureTokenStore(mem, 'aethryon.mail');
    await drive.write(
      'acc',
      TokenSet(
        accessToken: 'AT',
        refreshToken: 'RT',
        expiresAtUtc: now,
        scopes: ['s'],
      ),
    );
    expect((await drive.read('acc'))!.refreshToken, 'RT');
    expect(await mail.read('acc'), isNull);
    await drive.delete('acc');
    expect(await drive.read('acc'), isNull);
  });

  test('loopback receiver returns query parameters', () async {
    final r = await LoopbackReceiver.start();
    expect(r.redirectUri.host, '127.0.0.1');
    final fut = r.waitForCallback(timeout: const Duration(seconds: 5));
    final cl = HttpClient();
    final req = await cl.getUrl(
      r.redirectUri.replace(queryParameters: {'code': 'abc', 'state': 's'}),
    );
    final resp = await req.close();
    await resp.drain<void>();
    cl.close();
    expect(await fut, {'code': 'abc', 'state': 's'});
  });
}
