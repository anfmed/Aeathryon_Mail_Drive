import 'package:http/http.dart' as http;

import '../aethryon_auth.dart' show TokenSet, TokenStore;
import 'oauth.dart';

/// Gives callers a valid access token, refreshing (once, even under concurrency)
/// when it is about to expire. `reauth_required` means the user must sign in again.
class OAuthTokenSource {
  final TokenStore tokens;
  final http.Client client;
  final Uri tokenEndpoint;
  final String clientId;
  final String? clientSecret;
  final Future<String?> Function()?
  clientSecretProvider; // e.g. read from the secure store on demand
  final DateTime Function() nowUtc;
  final Map<String, Future<TokenSet>> _inflight = {};

  OAuthTokenSource({
    required this.tokens,
    required this.client,
    required this.tokenEndpoint,
    required this.clientId,
    this.clientSecret,
    this.clientSecretProvider,
    DateTime Function()? nowUtc,
  }) : nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  Future<String> accessToken(String accountId) async {
    final cur = await tokens.read(accountId);
    if (cur == null) throw OAuthError('reauth_required', 'no tokens stored');
    if (!cur.needsRefresh(nowUtc())) return cur.accessToken;
    final fresh = await (_inflight[accountId] ??=
        _refresh(accountId, cur).whenComplete(() {
          _inflight.remove(accountId); // block body: must NOT return the future being completed
        }));
    return fresh.accessToken;
  }

  Future<TokenSet> _refresh(String accountId, TokenSet cur) async {
    final rt = cur.refreshToken;
    if (rt == null) throw OAuthError('reauth_required', 'no refresh token');
    try {
      final fresh = await refreshTokens(
        client: client,
        tokenEndpoint: tokenEndpoint,
        clientId: clientId,
        clientSecret:
            clientSecret ?? _nonEmpty(await clientSecretProvider?.call()),
        refreshToken: rt,
        nowUtc: nowUtc,
      );
      await tokens.write(accountId, fresh);
      return fresh;
    } on OAuthError catch (e) {
      if (e.code == 'invalid_grant')
        throw OAuthError('reauth_required', 'refresh token was rejected');
      rethrow;
    }
  }
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;
