import 'dart:async';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:http/http.dart' as http;
import 'adapter.dart';
import 'capabilities_manifest.dart';
import 'models.dart';
import 'webdav_parse.dart';

const _propfindBody = '<?xml version="1.0" encoding="utf-8"?>'
    '<d:propfind xmlns:d="DAV:"><d:prop>'
    '<d:resourcetype/><d:getcontentlength/><d:getlastmodified/><d:getetag/>'
    '</d:prop></d:propfind>';

/// Generic WebDAV adapter (also the base for Nextcloud). STATUS: written without
/// a Dart toolchain and without a live server; Phase 2 CI only runs the pure
/// parser tests. Live-server behaviour is UNVERIFIED until an integration test
/// against a self-hosted Nextcloud/WebDAV container runs in CI.
class WebDavAdapter implements StorageAdapter {
  final Uri baseUrl; // e.g. https://host/remote.php/dav/files/user/
  /// Return null for servers that need no Authorization header (e.g. test server).
  final Future<String?> Function(String accountId) authorizationHeader;
  final http.Client _client;
  final RetryPolicy retryPolicy;
  final CapabilityRegistry _registry = buildDriveRegistry();

  WebDavAdapter({
    required this.baseUrl,
    required this.authorizationHeader,
    http.Client? client,
    this.retryPolicy = const RetryPolicy(),
  }) : _client = client ?? http.Client();

  @override
  String get providerId => 'webdav';

  @override
  Capability capability(String feature) => _registry.lookup(providerId, feature);

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    final base = baseUrl.path.endsWith('/') ? baseUrl.path : '${baseUrl.path}/';
    return baseUrl.replace(
        pathSegments: [
      ...base.split('/').where((s) => s.isNotEmpty),
      ...p.split('/').where((s) => s.isNotEmpty),
    ]);
  }

  FailureKind _classify(Object e) =>
      e is ProviderHttpError ? classifyStatus(e.statusCode) : FailureKind.transient;

  Future<http.StreamedResponse> _send(String accountId, String method, Uri uri,
      {Map<String, String>? headers, Stream<List<int>>? body, int? length}) {
    return retry<http.StreamedResponse>(
      policy: retryPolicy,
      classify: _classify,
      retryAfterOf: (e) => e is ProviderHttpError ? parseRetryAfter(e.retryAfterHeader) : null,
      op: () async {
        final req = http.StreamedRequest(method, uri);
        final auth = await authorizationHeader(accountId);
        if (auth != null) req.headers['Authorization'] = auth;
        headers?.forEach((k, v) => req.headers[k] = v);
        if (length != null) req.contentLength = length;
        if (body != null) {
          // NOTE: a consumed stream cannot be replayed; uploads therefore retry
          // only at the transfer-manager level (re-open source). Phase 2 limit.
          unawaited(req.sink.addStream(body).whenComplete(req.sink.close));
        } else {
          unawaited(req.sink.close());
        }
        final resp = await _client.send(req);
        if (resp.statusCode >= 400) {
          throw ProviderHttpError(resp.statusCode, '$method ${uri.path}',
              retryAfterHeader: resp.headers['retry-after']);
        }
        return resp;
      },
    );
  }

  @override
  Future<Page<RemoteNode>> listChildren(String accountId, String parentId,
      {String? cursor}) async {
    final uri = _uri(parentId);
    final resp = await _send(accountId, 'PROPFIND', uri,
        headers: {'Depth': '1', 'Content-Type': 'application/xml'},
        body: Stream.value(_propfindBody.codeUnits),
        length: _propfindBody.length);
    final text = await resp.stream.bytesToString();
    // uri.pathSegments is percent-decoded, matching the decoded hrefs in the parser.
    return Page(parsePropfind(text,
        accountId: accountId, requestedPath: '/${uri.pathSegments.join('/')}'));
  }

  @override
  Future<RemoteNode> metadata(String accountId, String id) async {
    final uri = _uri(id);
    final resp = await _send(accountId, 'PROPFIND', uri,
        headers: {'Depth': '0', 'Content-Type': 'application/xml'},
        body: Stream.value(_propfindBody.codeUnits),
        length: _propfindBody.length);
    final text = await resp.stream.bytesToString();
    // Depth 0 returns only the resource itself; parse with a sentinel self-path.
    final nodes = parsePropfind(text, accountId: accountId, requestedPath: '/__none__');
    if (nodes.isEmpty) throw ProviderHttpError(404, 'metadata not found');
    return nodes.first;
  }

  @override
  Stream<List<int>> download(String accountId, String id,
      {int? start, int? endInclusive}) async* {
    final headers = <String, String>{};
    if (start != null) {
      headers['Range'] = 'bytes=$start-${endInclusive ?? ''}';
    }
    final resp = await _send(accountId, 'GET', _uri(id), headers: headers);
    yield* resp.stream;
  }

  @override
  Future<RemoteNode> upload(String accountId, String parentId, String name,
      Stream<List<int>> data, int length) async {
    final path = parentId.endsWith('/') ? '$parentId$name' : '$parentId/$name';
    await _send(accountId, 'PUT', _uri(path), body: data, length: length);
    return metadata(accountId, path);
  }

  @override
  Future<void> mkdir(String accountId, String parentId, String name) async {
    final path = parentId.endsWith('/') ? '$parentId$name' : '$parentId/$name';
    await _send(accountId, 'MKCOL', _uri(path));
  }

  @override
  Future<void> move(String accountId, String id, String newParentId, String newName) async {
    final dest = newParentId.endsWith('/') ? '$newParentId$newName' : '$newParentId/$newName';
    await _send(accountId, 'MOVE', _uri(id),
        headers: {'Destination': _uri(dest).toString(), 'Overwrite': 'F'});
  }

  @override
  Future<void> trash(String accountId, String id) =>
      throw UnsupportedOperation(DriveFeature.trash);

  @override
  Future<void> permanentDelete(String accountId, String id) async {
    await _send(accountId, 'DELETE', _uri(id));
  }

  @override
  Future<QuotaInfo> quota(String accountId) =>
      throw UnsupportedOperation(DriveFeature.quota);
}
