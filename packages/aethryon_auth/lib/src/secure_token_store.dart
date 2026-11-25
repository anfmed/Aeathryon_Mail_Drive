import 'dart:convert';
import 'package:aethryon_platform/aethryon_platform.dart';
import '../aethryon_auth.dart' show TokenSet, TokenStore;

class MemorySecureStore implements SecureStore {
  final Map<String, String> _m = {};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
}

/// TokenStore over any SecureStore. [namespace] separates Drive from Mail
/// (e.g. 'aethryon.drive' / 'aethryon.mail') so one app can never read the other's tokens.
class SecureTokenStore implements TokenStore {
  final SecureStore store;
  final String namespace;
  SecureTokenStore(this.store, this.namespace);
  String _k(String id) => '$namespace.token.$id';

  @override
  Future<TokenSet?> read(String accountId) async {
    final v = await store.read(_k(accountId));
    if (v == null) return null;
    return TokenSet.fromJson(Map<String, Object?>.from(jsonDecode(v) as Map));
  }

  @override
  Future<void> write(String accountId, TokenSet tokens) =>
      store.write(_k(accountId), jsonEncode(tokens.toJson()));

  @override
  Future<void> delete(String accountId) => store.delete(_k(accountId));
}
