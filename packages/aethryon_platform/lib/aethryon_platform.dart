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
  const NetworkState({required this.online, required this.metered, required this.wifi});
}

class PowerState {
  final int batteryPercent; // 0..100
  final bool charging;
  final bool batterySaver;
  const PowerState({required this.batteryPercent, required this.charging, required this.batterySaver});
}

abstract class NetworkProbe {
  Future<NetworkState> current();
}

abstract class PowerProbe {
  Future<PowerState> current();
}
