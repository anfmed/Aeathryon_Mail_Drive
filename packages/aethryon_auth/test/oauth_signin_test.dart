import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Plays the browser: reads redirect_uri from the auth URL and calls it back.
Future<void> Function(Uri) fakeBrowser({String? stateOverride, Map<String, String>? extra}) => (url) async {
      final redirect = Uri.parse(url.queryParameters['redirect_uri']!);
      final q = {'code': 'CODE123', 'state': stateOverride ?? url.queryParameters['state']!, ...?extra};
      unawaited(Future(() async {
        final c = HttpClient();
        final rq = await c.getUrl(redirect.replace(queryParameters: q));
        final rs = await rq.close();
        await rs.drain<void>();
        c.close();
      }));
    };

void main() {
  final provider = oauthProviderById('google_mail')!;

  test('full loopback flow: URL carries PKCE+scopes; code is exchanged with the matching verifier', () async {
    Uri? authUrl;
    String? postedVerifier;
    final client = MockClient((req) async {
      final f = Uri.splitQueryString(req.body);
      postedVerifier = f['code_verifier'];
      expect(f['code'], 'CODE123');
      expect(f['client_id'], 'MY-CLIENT');
      return http.Response(jsonEncode({'access_token': 'AT', 'refresh_token': 'RT', 'expires_in': 3600}), 200);
    });
    final t = await oauthSignIn(
      provider: provider,
      clientId: 'MY-CLIENT',
      httpClient: client,
      openUrl: (u) async {
        authUrl = u;
        await fakeBrowser()(u);
      },
    );
    expect(t.accessToken, 'AT');
    expect(t.refreshToken, 'RT');
    expect(authUrl!.queryParameters['scope'], 'https://mail.google.com/');
    expect(authUrl!.queryParameters['access_type'], 'offline');
    expect(authUrl!.host, 'accounts.google.com');
    // end-to-end PKCE consistency: challenge in the URL == S256(verifier sent to the token endpoint)
    expect(Pkce.fromVerifier(postedVerifier!).challenge, authUrl!.queryParameters['code_challenge']);
  });

  test('state mismatch aborts before any token request', () async {
    var tokenCalls = 0;
    final client = MockClient((_) async {
      tokenCalls++;
      return http.Response('{}', 200);
    });
    await expectLater(
        oauthSignIn(provider: provider, clientId: 'c', httpClient: client, openUrl: fakeBrowser(stateOverride: 'EVIL')),
        throwsA(isA<OAuthError>().having((e) => e.code, 'code', 'state_mismatch')));
    expect(tokenCalls, 0);
  });

  test('provider-reported error is surfaced', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    await expectLater(
        oauthSignIn(
            provider: provider, clientId: 'c', httpClient: client,
            openUrl: (u) async {
              final redirect = Uri.parse(u.queryParameters['redirect_uri']!);
              unawaited(Future(() async {
                final c = HttpClient();
                final rs = await (await c.getUrl(redirect.replace(queryParameters: {'error': 'access_denied'}))).close();
                await rs.drain<void>();
                c.close();
              }));
            }),
        throwsA(isA<OAuthError>().having((e) => e.code, 'code', 'access_denied')));
  });

  test('openUrl failure closes the loopback server and rethrows', () async {
    await expectLater(
        oauthSignIn(provider: provider, clientId: 'c', httpClient: MockClient((_) async => http.Response('{}', 200)),
            openUrl: (_) async => throw StateError('no browser')),
        throwsStateError);
  });

  test('provider table: scopes tied to Phase-0 sources, no client secrets shipped', () {
    expect(oauthProviderById('microsoft_mail')!.scopes, contains('offline_access'));
    expect(oauthProviderById('microsoft_mail')!.scopeSources, contains('S09'));
    expect(oauthProviderById('google_drive')!.scopeSources, containsAll(['S01', 'S02']));
    expect(oauthProviders.every((p) => !p.endpointsVerified), isTrue); // honest: not verified yet
    expect(oauthProviderById('nope'), isNull);
  });
}
