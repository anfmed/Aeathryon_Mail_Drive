import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

export 'src/oauth.dart';
export 'src/loopback.dart';
export 'src/secure_token_store.dart';
export 'src/account_vault.dart';
export 'src/oauth_providers.dart';
export 'src/oauth_signin.dart';
export 'src/token_source.dart';

String _b64url(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');

/// RFC 7636 PKCE (S256 only; `plain` is intentionally not offered).
class Pkce {
  static const method = 'S256';
  final String verifier;
  final String challenge;
  Pkce._(this.verifier, this.challenge);

  factory Pkce.generate({Random? random}) {
    final r = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return Pkce.fromVerifier(_b64url(bytes));
  }

  factory Pkce.fromVerifier(String verifier) {
    if (verifier.length < 43 || verifier.length > 128) {
      throw ArgumentError('PKCE verifier must be 43..128 chars');
    }
    final digest = sha256.convert(ascii.encode(verifier));
    return Pkce._(verifier, _b64url(digest.bytes));
  }
}

String randomState({Random? random, int bytes = 16}) {
  final r = random ?? Random.secure();
  return _b64url(List<int>.generate(bytes, (_) => r.nextInt(256)));
}

class TokenSet {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAtUtc;
  final List<String> scopes;
  const TokenSet({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAtUtc,
    this.scopes = const [],
  });

  bool needsRefresh(DateTime nowUtc,
          {Duration skew = const Duration(seconds: 60)}) =>
      !nowUtc.add(skew).isBefore(expiresAtUtc);

  /// Never prints secrets.
  @override
  String toString() =>
      'TokenSet(expires: ${expiresAtUtc.toIso8601String()}, scopes: $scopes)';

  Map<String, Object?> toJson() => {
        'a': accessToken,
        'r': refreshToken,
        'e': expiresAtUtc.toIso8601String(),
        's': scopes,
      };

  factory TokenSet.fromJson(Map<String, Object?> j) => TokenSet(
        accessToken: j['a'] as String,
        refreshToken: j['r'] as String?,
        expiresAtUtc: DateTime.parse(j['e'] as String).toUtc(),
        scopes: (j['s'] as List?)?.cast<String>() ?? const [],
      );
}

/// Implementations MUST persist via the OS secure store only (never plain files/DB).
abstract class TokenStore {
  Future<TokenSet?> read(String accountId);
  Future<void> write(String accountId, TokenSet tokens);
  Future<void> delete(String accountId);
}
