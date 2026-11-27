import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens/keys only. NEVER store tokens anywhere else (plain files, SQLite, prefs).
class FlutterSecureStore implements SecureStore {
  final FlutterSecureStorage _s;
  FlutterSecureStore([FlutterSecureStorage? s])
    : _s = s ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}
