import 'dart:math';

import 'package:aethryon_platform/aethryon_platform.dart';

/// The database key lives ONLY in the OS secure store. The DB holds re-creatable
/// caches, so a lost key means "start fresh", never "data loss".
class DbKeyManager {
  final SecureStore store;
  final String namespace;
  DbKeyManager(this.store, this.namespace);
  String get _k => '$namespace.dbkey';

  Future<String> getOrCreate({Random? random}) async {
    final v = await store.read(_k);
    if (v != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(v)) return v;
    final r = random ?? Random.secure();
    final hex = List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await store.write(_k, hex);
    return hex;
  }

  Future<void> delete() => store.delete(_k);
}
