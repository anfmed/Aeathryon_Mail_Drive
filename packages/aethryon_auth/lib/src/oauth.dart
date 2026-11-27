import 'dart:convert';
import 'package:http/http.dart' as http;
import '../aethryon_auth.dart' show Pkce, TokenSet;

class OAuthError implements Exception {
  final String code; // e.g. invalid_grant. Never contains token material.
  final String? description;
  OAuthError(this.code, [this.description]);
  @override
  String toString() => 'OAuthError($code${description == null ? '' : ': $description'})';
}

Uri buildAuthorizationUrl({
  required Uri endpoint,
  required String clientId,
  required Uri redirectUri,
  required List<String> scopes,
  required String state,
  required Pkce pkce,
  Map<String, String> extra = const {},
}) =>
    endpoint.replace(queryParameters: {
      ...endpoint.queryParameters,
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'scope': scopes.join(' '),
      'state': state,
      'code_challenge': pkce.challenge,
      'code_challenge_method': Pkce.method,
      ...extra,
    });

/// Constant-time comparison for the OAuth `state` parameter.
bool verifyState(String expected, String? actual) {
  if (actual == null || actual.length != expected.length) return false;
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
  }
  return diff == 0;
}

Future<TokenSet> _post(
  http.Client client,
  Uri tokenEndpoint,
  Map<String, String> form,
  DateTime Function() nowUtc, {
  String? previousRefreshToken,
}) async {
  final resp = await client.post(tokenEndpoint,
      headers: {'Accept': 'application/json'}, body: form);
  Map<String, dynamic> json;
  try {
    json = jsonDecode(resp.body) as Map<String, dynamic>;
  } catch (_) {
    throw OAuthError('invalid_response', 'HTTP ${resp.statusCode}');
  }
  if (resp.statusCode != 200 || json['error'] != null) {
    throw OAuthError('${json['error'] ?? 'http_${resp.statusCode}'}',
        json['error_description'] as String?);
  }
  final access = json['access_token'] as String?;
  if (access == null) throw OAuthError('invalid_response', 'no access_token');
  final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
  final scope = (json['scope'] as String?)?.split(' ').where((e) => e.isNotEmpty).toList() ?? const <String>[];
  return TokenSet(
    accessToken: access,
    refreshToken: (json['refresh_token'] as String?) ?? previousRefreshToken,
    expiresAtUtc: nowUtc().add(Duration(seconds: expiresIn)),
    scopes: scope,
  );
}

Future<TokenSet> exchangeCode({
  required http.Client client,
  required Uri tokenEndpoint,
  required String clientId,
  String? clientSecret, // BYO clients (e.g. Google "Desktop app") may require it
  required String code,
  required Uri redirectUri,
  required String codeVerifier,
  DateTime Function()? nowUtc,
}) =>
    _post(
      client,
      tokenEndpoint,
      {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri.toString(),
        'client_id': clientId,
        'code_verifier': codeVerifier,
        if (clientSecret != null) 'client_secret': clientSecret,
      },
      nowUtc ?? () => DateTime.now().toUtc(),
    );

Future<TokenSet> refreshTokens({
  required http.Client client,
  required Uri tokenEndpoint,
  required String clientId,
  String? clientSecret,
  required String refreshToken,
  DateTime Function()? nowUtc,
}) =>
    _post(
      client,
      tokenEndpoint,
      {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
      },
      nowUtc ?? () => DateTime.now().toUtc(),
      previousRefreshToken: refreshToken,
    );
