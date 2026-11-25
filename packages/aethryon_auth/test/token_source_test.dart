import 'dart:convert';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);
  final endpoint = Uri.parse('https://idp.example/token');

  OAuthTokenSource src(http.Client c, TokenStore store) => OAuthTokenSource(
    tokens: store,
    client: c,
    tokenEndpoint: endpoint,
    clientId: 'cid',
    nowUtc: () => now,
  );

  test('fresh token: no network call', () async {
    final store = SecureTokenStore(MemorySecureStore(), 'ns');
    await store.write(
      'a',
      TokenSet(
        accessToken: 'AT',
        refreshToken: 'RT',
        expiresAtUtc: now.add(const Duration(hours: 1)),
      ),
    );
    var calls = 0;
    final s = src(
      MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
      store,
    );
    expect(await s.accessToken('a'), 'AT');
    expect(calls, 0);
  });

  test('expired token is refreshed and saved', () async {
    final store = SecureTokenStore(MemorySecureStore(), 'ns');
    await store.write(
      'a',
      TokenSet(
        accessToken: 'OLD',
        refreshToken: 'RT',
        expiresAtUtc: now.subtract(const Duration(minutes: 1)),
      ),
    );
    final s = src(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'access_token': 'NEW', 'expires_in': 3600}),
          200,
        ),
      ),
      store,
    );
    expect(await s.accessToken('a'), 'NEW');
    expect((await store.read('a'))!.accessToken, 'NEW');
    expect((await store.read('a'))!.refreshToken, 'RT');
  });

  test('concurrent callers share ONE refresh request', () async {
    final store = SecureTokenStore(MemorySecureStore(), 'ns');
    await store.write(
      'a',
      TokenSet(accessToken: 'OLD', refreshToken: 'RT', expiresAtUtc: now),
    );
    var calls = 0;
    final s = src(
      MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(
          jsonEncode({'access_token': 'NEW', 'expires_in': 3600}),
          200,
        );
      }),
      store,
    );
    final r = await Future.wait([
      s.accessToken('a'),
      s.accessToken('a'),
      s.accessToken('a'),
    ]);
    expect(r, ['NEW', 'NEW', 'NEW']);
    expect(calls, 1);
  });

  test(
    'invalid_grant and missing tokens both demand re-authentication',
    () async {
      final store = SecureTokenStore(MemorySecureStore(), 'ns');
      await store.write(
        'a',
        TokenSet(accessToken: 'OLD', refreshToken: 'RT', expiresAtUtc: now),
      );
      final s = src(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': 'invalid_grant'}), 400),
        ),
        store,
      );
      await expectLater(
        s.accessToken('a'),
        throwsA(
          isA<OAuthError>().having((e) => e.code, 'code', 'reauth_required'),
        ),
      );
      await expectLater(
        s.accessToken('nobody'),
        throwsA(
          isA<OAuthError>().having((e) => e.code, 'code', 'reauth_required'),
        ),
      );
      await store.write('b', TokenSet(accessToken: 'OLD', expiresAtUtc: now));
      await expectLater(
        s.accessToken('b'),
        throwsA(
          isA<OAuthError>().having((e) => e.code, 'code', 'reauth_required'),
        ),
      );
    },
  );
}
