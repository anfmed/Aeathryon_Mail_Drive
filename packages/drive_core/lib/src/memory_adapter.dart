import 'package:aethryon_capability/aethryon_capability.dart';

import 'adapter.dart';
import 'models.dart';

/// In-memory storage: powers the demo UI and tests. Not a real provider.
class MemoryStorageAdapter implements StorageAdapter {
  final Map<String, RemoteNode> _nodes = {};
  final Map<String, List<int>> _data = {};
  final Set<String> _trashed = {};

  String _k(String a, String id) => '$a\u0000$id';

  @override
  String get providerId => 'memory';

  @override
  Capability capability(String feature) {
    switch (feature) {
      case DriveFeature.share:
      case DriveFeature.serverSearch:
      case DriveFeature.changeFeed:
        return const Capability.unsupported(note: 'demo adapter');
      default:
        return const Capability.partial(
          evidence: Evidence.none,
          note: 'demo adapter',
        );
    }
  }

  void seedFolder(String accountId, String path) {
    final segs = path.split('/').where((s) => s.isNotEmpty).toList();
    var cur = '';
    for (final s in segs) {
      final parent = cur.isEmpty ? '/' : cur;
      cur = '$cur/$s';
      _nodes.putIfAbsent(
        _k(accountId, cur),
        () => RemoteNode(
          accountId: accountId,
          id: cur,
          parentId: parent,
          name: s,
          isFolder: true,
        ),
      );
    }
  }

  void seedFile(
    String accountId,
    String path,
    List<int> bytes, {
    DateTime? modified,
  }) {
    final i = path.lastIndexOf('/');
    final parent = i <= 0 ? '/' : path.substring(0, i);
    if (parent != '/') seedFolder(accountId, parent);
    _data[_k(accountId, path)] = List.of(bytes);
    _nodes[_k(accountId, path)] = RemoteNode(
      accountId: accountId,
      id: path,
      parentId: parent,
      name: path.substring(i + 1),
      isFolder: false,
      size: bytes.length,
      modifiedUtc: modified,
    );
  }

  @override
  Future<Page<RemoteNode>> listChildren(
    String accountId,
    String parentId, {
    String? cursor,
  }) async {
    final items = _nodes.entries
        .where(
          (e) =>
              e.value.accountId == accountId &&
              e.value.parentId == parentId &&
              !_trashed.contains(e.key),
        )
        .map((e) => e.value)
        .toList();
    return Page(items);
  }

  @override
  Future<RemoteNode> metadata(String accountId, String id) async {
    final n = _nodes[_k(accountId, id)];
    if (n == null || _trashed.contains(_k(accountId, id))) {
      throw ProviderHttpError(404, 'not found');
    }
    return n;
  }

  @override
  Stream<List<int>> download(
    String accountId,
    String id, {
    int? start,
    int? endInclusive,
  }) async* {
    final d = _data[_k(accountId, id)];
    if (d == null) throw ProviderHttpError(404, 'not found');
    final s = start ?? 0;
    final e = endInclusive == null
        ? d.length
        : (endInclusive + 1).clamp(0, d.length);
    yield d.sublist(s.clamp(0, d.length), e);
  }

  @override
  Future<RemoteNode> upload(
    String accountId,
    String parentId,
    String name,
    Stream<List<int>> data,
    int length,
  ) async {
    final bytes = <int>[];
    await for (final c in data) {
      bytes.addAll(c);
    }
    if (bytes.length != length) throw ArgumentError('length mismatch');
    final path = parentId == '/' ? '/$name' : '$parentId/$name';
    seedFile(accountId, path, bytes);
    return _nodes[_k(accountId, path)]!;
  }

  @override
  Future<void> mkdir(String accountId, String parentId, String name) async =>
      seedFolder(accountId, parentId == '/' ? '/$name' : '$parentId/$name');

  @override
  Future<void> move(
    String accountId,
    String id,
    String newParentId,
    String newName,
  ) async {
    final n = await metadata(accountId, id);
    final newPath = newParentId == '/' ? '/$newName' : '$newParentId/$newName';
    if (_nodes.containsKey(_k(accountId, newPath))) {
      throw ProviderHttpError(
        412,
        'destination exists',
      ); // never overwrite silently
    }
    final data = _data.remove(_k(accountId, id));
    _nodes.remove(_k(accountId, id));
    _nodes[_k(accountId, newPath)] = RemoteNode(
      accountId: accountId,
      id: newPath,
      parentId: newParentId,
      name: newName,
      isFolder: n.isFolder,
      size: n.size,
      modifiedUtc: n.modifiedUtc,
      etag: n.etag,
    );
    if (data != null) _data[_k(accountId, newPath)] = data;
  }

  @override
  Future<void> trash(String accountId, String id) async {
    await metadata(accountId, id);
    _trashed.add(_k(accountId, id)); // recoverable
  }

  void restore(String accountId, String id) =>
      _trashed.remove(_k(accountId, id));

  @override
  Future<void> permanentDelete(String accountId, String id) async {
    _nodes.remove(_k(accountId, id));
    _data.remove(_k(accountId, id));
    _trashed.remove(_k(accountId, id));
  }

  @override
  Future<QuotaInfo> quota(String accountId) async => QuotaInfo(
    usedBytes: _data.entries
        .where((e) => e.key.startsWith('$accountId\u0000'))
        .fold<int>(0, (a, e) => a + e.value.length),
    totalBytes: 1024 * 1024 * 1024,
  );
}
