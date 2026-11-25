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

/// Dropbox requires non-ASCII characters in the Dropbox-API-Arg header to be \uXXXX escaped.
String asciiJson(Object? value) {
  final s = jsonEncode(value);
  final b = StringBuffer();
  for (final u in s.codeUnits) {
    if (u > 0x7f) {
      b.write('\\u${u.toRadixString(16).padLeft(4, '0')}');
    } else {
      b.writeCharCode(u);
    }
  }
  return b.toString();
}

/// BLIND-WRITTEN against Dropbox HTTP API v2 from general knowledge (no official
/// page was read in this project). Capabilities stay UNVERIFIED => no UI path
/// enables it until a live test with a real account passes (Phase 8).
class DropboxAdapter implements StorageAdapter, ResumableUploader {
  final Future<String> Function(String accountId) accessToken;
  final http.Client _client;
  final RetryPolicy retryPolicy;
  final CapabilityRegistry _registry = buildDriveRegistry();
  static const _api = 'https://api.dropboxapi.com/2';
  static const _content = 'https://content.dropboxapi.com/2';
  static const singleUploadLimit =
      8 * 1024 * 1024; // larger files must use the resumable path

  DropboxAdapter({
    required this.accessToken,
    http.Client? client,
    this.retryPolicy = const RetryPolicy(),
  }) : _client = client ?? http.Client();

  @override
  String get providerId => 'dropbox';
  @override
  Capability capability(String feature) =>
      _registry.lookup(providerId, feature);

  String _p(String id) => id == '/' ? '' : id;

  Future<Map<String, dynamic>> _rpc(
    String acc,
    String endpoint,
    Object? body,
  ) async {
    final token = await accessToken(acc);
    final r = await sendBuffered(_client, retryPolicy, () {
      final q = http.Request('POST', Uri.parse('$_api$endpoint'))
        ..headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        q.headers['Content-Type'] = 'application/json';
        q.body = jsonEncode(body);
      }
      return q;
    });
    return r.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<http.Response> _contentCall(
    String acc,
    String endpoint,
    Object arg,
    List<int> bytes,
  ) async {
    final token = await accessToken(acc);
    return sendBuffered(
      _client,
      retryPolicy,
      () => http.Request('POST', Uri.parse('$_content$endpoint'))
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Dropbox-API-Arg'] = asciiJson(arg)
        ..headers['Content-Type'] = 'application/octet-stream'
        ..bodyBytes = bytes,
    );
  }

  RemoteNode _node(String acc, Map<String, dynamic> e) {
    final id = (e['path_display'] ?? e['path_lower']) as String;
    final i = id.lastIndexOf('/');
    return RemoteNode(
      accountId: acc,
      id: id,
      parentId: i <= 0 ? '/' : id.substring(0, i),
      name: e['name'] as String,
      isFolder: e['.tag'] == 'folder',
      size: (e['size'] as num?)?.toInt(),
      modifiedUtc: DateTime.tryParse((e['server_modified'] ?? '') as String)
          ?.toUtc(),
      etag: e['rev'] as String?,
    );
  }

  @override
  Future<Page<RemoteNode>> listChildren(
    String accountId,
    String parentId, {
    String? cursor,
  }) async {
    final j = cursor == null
        ? await _rpc(accountId, '/files/list_folder', {
            'path': _p(parentId),
            'limit': 200,
          })
        : await _rpc(accountId, '/files/list_folder/continue', {
            'cursor': cursor,
          });
    final entries = (j['entries'] as List).cast<Map<String, dynamic>>();
    return Page([
      for (final e in entries) _node(accountId, e),
    ], nextCursor: j['has_more'] == true ? j['cursor'] as String : null);
  }

  @override
  Future<RemoteNode> metadata(String accountId, String id) async => _node(
    accountId,
    await _rpc(accountId, '/files/get_metadata', {'path': _p(id)}),
  );

  @override
  Stream<List<int>> download(
    String accountId,
    String id, {
    int? start,
    int? endInclusive,
  }) async* {
    final token = await accessToken(accountId);
    final req = http.Request('POST', Uri.parse('$_content/files/download'))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Dropbox-API-Arg'] = asciiJson({'path': id});
    if (start != null)
      req.headers['Range'] = 'bytes=$start-${endInclusive ?? ''}';
    final resp = await sendStreaming(_client, req);
    yield* resp.stream;
  }

  @override
  Future<RemoteNode> upload(
    String accountId,
    String parentId,
    String name,
    Stream<List<int>> data,
    int length,
  ) async {
    if (length > singleUploadLimit) {
      throw ArgumentError(
        'file too large for single upload; use the resumable path',
      );
    }
    final bytes = <int>[];
    await for (final c in data) {
      bytes.addAll(c);
    }
    final path = parentId == '/' ? '/$name' : '$parentId/$name';
    final r = await _contentCall(accountId, '/files/upload', {
      'path': path,
      'mode': 'add',
      'autorename': false,
      'mute': false,
    }, bytes);
    return _node(accountId, jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<void> mkdir(String accountId, String parentId, String name) async {
    final path = parentId == '/' ? '/$name' : '$parentId/$name';
    await _rpc(accountId, '/files/create_folder_v2', {
      'path': path,
      'autorename': false,
    });
  }

  @override
  Future<void> move(
    String accountId,
    String id,
    String newParentId,
    String newName,
  ) async {
    final dest = newParentId == '/' ? '/$newName' : '$newParentId/$newName';
    await _rpc(accountId, '/files/move_v2', {
      'from_path': id,
      'to_path': dest,
      'autorename': false,
    });
  }

  @override
  Future<void> trash(String accountId, String id) =>
      throw UnsupportedOperation(DriveFeature.trash);

  @override
  Future<void> permanentDelete(String accountId, String id) async {
    await _rpc(accountId, '/files/delete_v2', {'path': id});
  }

  @override
  Future<QuotaInfo> quota(String accountId) async {
    final j = await _rpc(accountId, '/users/get_space_usage', null);
    final alloc = j['allocation'] as Map<String, dynamic>?;
    return QuotaInfo(
      usedBytes: (j['used'] as num?)?.toInt(),
      totalBytes: (alloc?['allocated'] as num?)?.toInt(),
    );
  }

  // ---- resumable upload sessions ----
  @override
  ChunkConstraint get constraint => ChunkConstraint.dropbox;

  @override
  Future<ResumableSession> begin(
    String accountId,
    String parentId,
    String name,
    int totalBytes,
  ) async {
    final r = await _contentCall(accountId, '/files/upload_session/start', {
      'close': false,
    }, const []);
    final id =
        (jsonDecode(r.body) as Map<String, dynamic>)['session_id'] as String;
    return _DropboxSession(
      this,
      accountId,
      id,
      parentId == '/' ? '/$name' : '$parentId/$name',
    );
  }
}

class _DropboxSession implements ResumableSession {
  final DropboxAdapter _o;
  final String _acc;
  final String _id;
  final String _path;
  int _offset = 0;
  _DropboxSession(this._o, this._acc, this._id, this._path);

  @override
  String get ref => _id;
  @override
  Future<int> confirmedOffset() async => _offset; // tracked locally; cross-restart resume = Phase 8

  @override
  Future<void> putChunk(
    ChunkRange range,
    List<int> bytes, {
    required int total,
  }) async {
    if (range.start != _offset) throw StateError('non-contiguous chunk');
    await _o._contentCall(_acc, '/files/upload_session/append_v2', {
      'cursor': {'session_id': _id, 'offset': range.start},
      'close': false,
    }, bytes);
    _offset = range.endInclusive + 1;
  }

  @override
  Future<RemoteNode> finish() async {
    final r = await _o._contentCall(_acc, '/files/upload_session/finish', {
      'cursor': {'session_id': _id, 'offset': _offset},
      'commit': {
        'path': _path,
        'mode': 'add',
        'autorename': false,
        'mute': false,
      },
    }, const []);
    return _o._node(_acc, jsonDecode(r.body) as Map<String, dynamic>);
  }
}
