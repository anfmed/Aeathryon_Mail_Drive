import 'dart:convert';
import 'package:aethryon_platform/aethryon_platform.dart';

class AccountRecord {
  final String id;
  final String kind; // 'webdav' | 'imap' | ...
  final String label;
  final Map<String, String> settings; // NON-secret only (validated)
  AccountRecord({required this.id, required this.kind, required this.label, required this.settings}) {
    for (final k in settings.keys) {
      final l = k.toLowerCase();
      if (l.contains('password') || l.contains('token') || l.contains('secret')) {
        throw ArgumentError('settings must not contain secrets (key: $k)');
      }
    }
  }
  Map<String, Object?> toJson() => {'id': id, 'kind': kind, 'label': label, 'settings': settings};
  factory AccountRecord.fromJson(Map<String, Object?> j) => AccountRecord(
        id: j['id'] as String,
        kind: j['kind'] as String,
        label: j['label'] as String,
        settings: Map<String, String>.from(j['settings'] as Map),
      );
}

/// Accounts live ONLY in the OS secure store. [namespace] keeps Drive and Mail apart.
class AccountVault {
  final SecureStore store;
  final String namespace;
  AccountVault(this.store, this.namespace);

  String get _indexKey => '$namespace.accounts';
  String _rec(String id) => '$namespace.account.$id';
  String _sec(String id) => '$namespace.secret.$id';

  Future<List<String>> _ids() async {
    final v = await store.read(_indexKey);
    if (v == null) return [];
    return List<String>.from(jsonDecode(v) as List);
  }

  Future<List<AccountRecord>> list() async {
    final out = <AccountRecord>[];
    for (final id in await _ids()) {
      final v = await store.read(_rec(id));
      if (v != null) out.add(AccountRecord.fromJson(Map<String, Object?>.from(jsonDecode(v) as Map)));
    }
    return out;
  }

  Future<void> save(AccountRecord r, {String? secret}) async {
    await store.write(_rec(r.id), jsonEncode(r.toJson()));
    if (secret != null) await store.write(_sec(r.id), secret);
    final ids = await _ids();
    if (!ids.contains(r.id)) {
      await store.write(_indexKey, jsonEncode([...ids, r.id]));
    }
  }

  Future<String?> secret(String id) => store.read(_sec(id));

  Future<void> remove(String id) async {
    await store.delete(_rec(id));
    await store.delete(_sec(id));
    final ids = (await _ids())..remove(id);
    await store.write(_indexKey, jsonEncode(ids));
  }
}
