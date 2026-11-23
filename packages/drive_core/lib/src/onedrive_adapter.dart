import 'dart:convert';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:http/http.dart' as http;
import 'adapter.dart';
import 'capabilities_manifest.dart';
import 'chunk_planner.dart';
import 'http_util.dart';
import 'models.dart';
import 'resumable.dart';

/// Microsoft Graph OneDrive. Verified in Phase 0 (S11): createUploadSession and the
/// 320 KiB chunk multiple. Everything else is BLIND-WRITTEN from general knowledge;
/// capabilities stay UNVERIFIED until a live test passes (Phase 8).
/// Security: the bearer token is NEVER sent to pre-authenticated download/upload URLs.
class OneDriveAdapter implements StorageAdapter, ResumableUploader {
  final Future<String> Function(String accountId) accessToken;
  final http.Client _client;
  final RetryPolicy retryPolicy;
  final CapabilityRegistry _registry = buildDriveRegistry();
  static const _g = 'https://graph.microsoft.com/v1.0';
  static const singleUploadLimit = 4 * 1024 * 1024;

  OneDriveAdapter({required this.accessToken, http.Client? client, this.retryPolicy = const RetryPolicy()})
      : _client = client ?? http.Client();

  @override
  String get providerId => 'onedrive';
  @override
  Capability capability(String feature) => _registry.lookup(providerId, feature);

  String _item(String id) => id == '/' ? '/me/drive/root' : '/me/drive/items/$id';
  String _child(String parentId, String name) => '${_item(parentId)}:/${Uri.encodeComponent(name)}:';

  Future<http.Response> _call(String acc, String method, String pathOrUrl,
      {Object? json, List<int>? bytes, Map<String, String>? headers}) async {
    final token = await accessToken(acc);
    final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$_g$pathOrUrl';
    return sendBuffered(_client, retryPolicy, () {
      final q = http.Request(method, Uri.parse(url))..headers['Authorization'] = 'Bearer $token';
      headers?.forEach((k, v) => q.headers[k] = v);
      if (json != null) {
        q.headers['Content-Type'] = 'application/json';
        q.body = jsonEncode(json);
      } else if (bytes != null) {
        q.headers['Content-Type'] = 'application/octet-stream';
        q.bodyBytes = bytes;
      }
      return q;
    });
  }

  Map<String, dynamic> _obj(http.Response r) =>
      r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;

  RemoteNode _node(String acc, Map<String, dynamic> e) => RemoteNode(
        accountId: acc,
        id: e['id'] as String,
        parentId: (e['parentReference'] as Map?)?['id'] as String?,
        name: e['name'] as String,
        isFolder: e.containsKey('folder'),
        size: e.containsKey('folder') ? null : (e['size'] as num?)?.toInt(),
        modifiedUtc: DateTime.tryParse((e['lastModifiedDateTime'] ?? '') as String)?.toUtc(),
        etag: e['eTag'] as String?,
      );

  @override
  Future<Page<RemoteNode>> listChildren(String accountId, String parentId, {String? cursor}) async {
    final j = _obj(await _call(accountId, 'GET', cursor ?? '${_item(parentId)}/children'));
    final items = (j['value'] as List).cast<Map<String, dynamic>>();
    return Page([for (final e in items) _node(accountId, e)], nextCursor: j['@odata.nextLink'] as String?);
  }

  @override
  Future<RemoteNode> metadata(String accountId, String id) async =>
      _node(accountId, _obj(await _call(accountId, 'GET', _item(id))));

  @override
  Stream<List<int>> download(String accountId, String id, {int? start, int? endInclusive}) async* {
    final token = await accessToken(accountId);
    final first = http.Request('GET', Uri.parse('$_g${_item(id)}/content'))
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $token';
    var resp = await _client.send(first);
    if (resp.statusCode >= 300 && resp.statusCode < 400) {
      final loc = resp.headers['location'];
      await resp.stream.drain<void>();
      if (loc == null) throw ProviderHttpError(resp.statusCode, 'redirect without location');
      final second = http.Request('GET', Uri.parse(loc)); // pre-authenticated URL: NO bearer token
      if (start != null) second.headers['Range'] = 'bytes=$start-${endInclusive ?? ''}';
      resp = await sendStreaming(_client, second);
    } else if (resp.statusCode >= 400) {
      await resp.stream.drain<void>();
      throw ProviderHttpError(resp.statusCode, 'GET content');
    }
    yield* resp.stream;
  }

  @override
  Future<RemoteNode> upload(String accountId, String parentId, String name,
      Stream<List<int>> data, int length) async {
    if (length > singleUploadLimit) {
      throw ArgumentError('file too large for single upload; use the resumable path');
    }
    final bytes = <int>[];
    await for (final c in data) {
      bytes.addAll(c);
    }
    final r = await _call(accountId, 'PUT', '${_child(parentId, name)}/content', bytes: bytes);
    return _node(accountId, _obj(r));
  }

  @override
  Future<void> mkdir(String accountId, String parentId, String name) async {
    await _call(accountId, 'POST', '${_item(parentId)}/children',
        json: {'name': name, 'folder': <String, dynamic>{}, '@microsoft.graph.conflictBehavior': 'fail'});
  }

  Future<String> _realId(String acc, String id) async =>
      id == '/' ? (_obj(await _call(acc, 'GET', '/me/drive/root?\$select=id'))['id'] as String) : id;

  @override
  Future<void> move(String accountId, String id, String newParentId, String newName) async {
    final parent = await _realId(accountId, newParentId);
    await _call(accountId, 'PATCH', '/me/drive/items/$id',
        json: {'name': newName, 'parentReference': {'id': parent}});
  }

  @override
  Future<void> trash(String accountId, String id) => throw UnsupportedOperation(DriveFeature.trash);

  @override
  Future<void> permanentDelete(String accountId, String id) async {
    await _call(accountId, 'DELETE', '/me/drive/items/$id');
  }

  @override
  Future<QuotaInfo> quota(String accountId) async {
    final q = _obj(await _call(accountId, 'GET', '/me/drive'))['quota'] as Map<String, dynamic>?;
    return QuotaInfo(usedBytes: (q?['used'] as num?)?.toInt(), totalBytes: (q?['total'] as num?)?.toInt());
  }

  // ---- resumable (S11) ----
  @override
  ChunkConstraint get constraint => ChunkConstraint.oneDrive;

  @override
  Future<ResumableSession> begin(String accountId, String parentId, String name, int totalBytes) async {
    final r = await _call(accountId, 'POST', '${_child(parentId, name)}/createUploadSession',
        json: {'item': {'@microsoft.graph.conflictBehavior': 'fail'}});
    return _OneDriveSession(this, accountId, _obj(r)['uploadUrl'] as String);
  }
}

class _OneDriveSession implements ResumableSession {
  final OneDriveAdapter _o;
  final String _acc;
  final String _url;
  Map<String, dynamic>? _final;
  _OneDriveSession(this._o, this._acc, this._url);

  @override
  String get ref => _url;

  @override
  Future<int> confirmedOffset() async {
    final r = await sendBuffered(_o._client, _o.retryPolicy, () => http.Request('GET', Uri.parse(_url))); // no auth
    final ranges = (_o._obj(r)['nextExpectedRanges'] as List?)?.cast<String>() ?? const [];
    if (ranges.isEmpty) return 0;
    return int.tryParse(ranges.first.split('-').first) ?? 0;
  }

  @override
  Future<void> putChunk(ChunkRange range, List<int> bytes, {required int total}) async {
    final r = await sendBuffered(
        _o._client,
        _o.retryPolicy,
        () => http.Request('PUT', Uri.parse(_url)) // pre-authenticated URL: NO bearer token
          ..headers['Content-Range'] = 'bytes ${range.start}-${range.endInclusive}/$total'
          ..bodyBytes = bytes);
    if (r.statusCode == 200 || r.statusCode == 201) _final = _o._obj(r);
  }

  @override
  Future<RemoteNode> finish() async {
    final f = _final;
    if (f == null) throw StateError('upload not complete: server did not return the final item');
    return _o._node(_acc, f);
  }
}
