import 'dart:convert';

Object? _decode(String v) => jsonDecode(v);
String _encode(Object? v) => jsonEncode(v);

/// Interfaces only. Concrete OS bindings (Keychain/Keystore/Credential Manager/
/// libsecret, connectivity, battery) are Phase 4 work and are NOT written here.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class NetworkState {
  final bool online;
  final bool metered;
  final bool wifi;
  const NetworkState({
    required this.online,
    required this.metered,
    required this.wifi,
  });
}

class PowerState {
  final int batteryPercent; // 0..100
  final bool charging;
  final bool batterySaver;
  const PowerState({
    required this.batteryPercent,
    required this.charging,
    required this.batterySaver,
  });
}

abstract class NetworkProbe {
  Future<NetworkState> current();
}

abstract class PowerProbe {
  Future<PowerState> current();
}

/// A file chosen by the user (desktop path, or an Android content URI behind a stream).
abstract class PickedFile {
  String get name;
  Future<int> length();
  Stream<List<int>> openRead([int? start, int? end]);
}

abstract class FilePlatform {
  Future<PickedFile?> pickFile();
  Future<String> appDataDir(); // private app storage (databases)
  Future<String> downloadsDir(); // where downloaded files are written
}

abstract class UrlOpener {
  Future<void> open(Uri url);
}

/// Small non-secret preferences stored as one JSON document.
class JsonSettings {
  final SecureStore store;
  final String key;
  JsonSettings(this.store, this.key);
  Future<Map<String, Object?>> load() async {
    final v = await store.read(key);
    if (v == null) return {};
    try {
      return Map<String, Object?>.from(_decode(v) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, Object?> values) =>
      store.write(key, _encode(values));
}
