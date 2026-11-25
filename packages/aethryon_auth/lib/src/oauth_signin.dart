import 'package:http/http.dart' as http;

import '../aethryon_auth.dart' show Pkce, TokenSet, randomState;
import 'loopback.dart';
import 'oauth.dart';
import 'oauth_providers.dart';

typedef LoopbackFactory = Future<LoopbackReceiver> Function();

/// Desktop sign-in (RFC 8252 loopback + PKCE + state). [openUrl] launches the
/// system browser (injected: url_launcher wiring comes with the OAuth UI, Phase 8).
Future<TokenSet> oauthSignIn({
  required OAuthProviderConfig provider,
  required String clientId,
  String? clientSecret,
  required Future<void> Function(Uri url) openUrl,
  required http.Client httpClient,
  LoopbackFactory? receiverFactory,
  Duration timeout = const Duration(minutes: 5),
  DateTime Function()? nowUtc,
}) async {
  final receiver = await (receiverFactory ?? LoopbackReceiver.start)();
  final pkce = Pkce.generate();
  final state = randomState();
  final url = buildAuthorizationUrl(
    endpoint: provider.authEndpoint,
    clientId: clientId,
    redirectUri: receiver.redirectUri,
    scopes: provider.scopes,
    state: state,
    pkce: pkce,
    extra: provider.extraAuthParams,
  );
  try {
    await openUrl(url);
  } catch (_) {
    await receiver.close();
    rethrow;
  }
  final params = await receiver.waitForCallback(timeout: timeout);
  if (params['error'] != null)
    throw OAuthError(params['error']!, params['error_description']);
  if (!verifyState(state, params['state'])) throw OAuthError('state_mismatch');
  final code = params['code'];
  if (code == null || code.isEmpty) throw OAuthError('missing_code');
  return exchangeCode(
    client: httpClient,
    tokenEndpoint: provider.tokenEndpoint,
    clientId: clientId,
    clientSecret: clientSecret,
    code: code,
    redirectUri: receiver.redirectUri,
    codeVerifier: pkce.verifier,
    nowUtc: nowUtc,
  );
}
