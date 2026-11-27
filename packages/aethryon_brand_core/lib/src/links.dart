import 'dart:async';
import 'dart:convert';

import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:http/http.dart' as http;

class AppLinks {
  final String getInTouchUrl;
  final String supportUrl;
  const AppLinks({required this.getInTouchUrl, required this.supportUrl});
  @override
  bool operator ==(Object o) =>
      o is AppLinks &&
      o.getInTouchUrl == getInTouchUrl &&
      o.supportUrl == supportUrl;
  @override
  int get hashCode => Object.hash(getInTouchUrl, supportUrl);
}

/// Safe defaults, used until a valid remote/cached value exists. The ONLY place these literals live.
const defaultLinks = AppLinks(
  getInTouchUrl: 'https://aethryon-labs.sh010.workers.dev/',
  supportUrl: 'https://aethryon-labs.sh010.workers.dev/support/',
);

/// https only; a host is required; no embedded credentials; no whitespace; bounded length.
bool isSafeHttpsUrl(String? s) {
  if (s == null) return false;
  final t = s.trim();
  if (t.isEmpty || t.length > 2048 || RegExp(r'\s').hasMatch(t)) return false;
  final u = Uri.tryParse(t);
  return u != null &&
      u.scheme == 'https' &&
      u.host.isNotEmpty &&
      u.userInfo.isEmpty;
}

String? _pick(Map<dynamic, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String) return v;
  }
  return null;
}

/// Per-field merge: a valid remote value replaces the current one; an invalid or
/// missing one NEVER does. Returns null when nothing valid was found.
/// NOTE: the exact AUS `GET /v1/links` response shape was not available to this project;
/// this parser accepts the logical names `get_in_touch_url` / `support_url` (also camelCase),
/// at the top level or nested under `links` / `data`. Verify against docs/central-links.md.
AppLinks? mergeRemoteLinks(AppLinks current, Object? json) {
  if (json is! Map) return null;
  final sources = <Map<dynamic, dynamic>>[
    json,
    if (json['links'] is Map) json['links'] as Map,
    if (json['data'] is Map) json['data'] as Map,
  ];
  String? g;
  String? s;
  for (final m in sources) {
    g ??= _firstSafe(
      _pick(m, const ['get_in_touch_url', 'getInTouchUrl', 'get_in_touch']),
    );
    s ??= _firstSafe(_pick(m, const ['support_url', 'supportUrl', 'support']));
  }
  if (g == null && s == null) return null;
  return AppLinks(
    getInTouchUrl: g ?? current.getInTouchUrl,
    supportUrl: s ?? current.supportUrl,
  );
}

String? _firstSafe(String? v) => isSafeHttpsUrl(v) ? v!.trim() : null;

/// Single source of truth for Get In Touch / Support. UI reads [links]; AUS (or the
/// cache, or the defaults) feed it. Network work is background-only and failure-tolerant.
class LinkConfigService {
  final JsonSettings _cache;
  final http.Client _client;
  final String baseUrl; // AUS base URL; empty = remote refresh disabled
  final DateTime Function() _now;
  final Duration ttl;
  final Duration timeout;
  final StreamController<AppLinks> _changes =
      StreamController<AppLinks>.broadcast();
  AppLinks _links = defaultLinks;
  DateTime? _fetchedAt;

  LinkConfigService({
    required JsonSettings cache,
    required http.Client client,
    this.baseUrl = '',
    DateTime Function()? now,
    this.ttl = const Duration(hours: 6),
    this.timeout = const Duration(seconds: 10),
  }) : _cache = cache,
       _client = client,
       _now = now ?? (() => DateTime.now().toUtc());

  AppLinks get links => _links;
  Stream<AppLinks> get changes => _changes.stream;

  /// Loads the last valid cached configuration (works offline).
  Future<void> init() async {
    final m = await _cache.load();
    final g = m['getInTouchUrl'];
    final s = m['supportUrl'];
    final gs = g is String ? g : null; // a corrupted cache must never throw
    final ss = s is String ? s : null;
    _links = AppLinks(
      getInTouchUrl: isSafeHttpsUrl(gs)
          ? gs!.trim()
          : defaultLinks.getInTouchUrl,
      supportUrl: isSafeHttpsUrl(ss) ? ss!.trim() : defaultLinks.supportUrl,
    );
    final f = m['fetchedAt'];
    if (f is String) _fetchedAt = DateTime.tryParse(f);
  }

  /// Returns true when the links changed. Never throws.
  Future<bool> refresh({bool force = false}) async {
    if (baseUrl.isEmpty || !isSafeHttpsUrl(baseUrl)) return false;
    final last = _fetchedAt;
    if (!force && last != null && _now().difference(last) < ttl)
      return false; // avoid repeated requests
    try {
      final b = baseUrl.trim();
      final uri = Uri.parse(b.endsWith('/') ? '${b}v1/links' : '$b/v1/links');
      final resp = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (resp.statusCode != 200 || resp.bodyBytes.length > 64 * 1024)
        return false;
      _fetchedAt = _now();
      final merged = mergeRemoteLinks(
        _links,
        jsonDecode(utf8.decode(resp.bodyBytes)),
      );
      if (merged == null) return false;
      final changed = merged != _links;
      _links = merged;
      await _cache.save({
        'getInTouchUrl': _links.getInTouchUrl,
        'supportUrl': _links.supportUrl,
        'fetchedAt': _fetchedAt!.toIso8601String(),
      });
      if (changed && !_changes.isClosed) _changes.add(_links);
      return changed;
    } catch (_) {
      return false; // offline / malformed: keep the current valid configuration
    }
  }

  Future<void> dispose() => _changes.close();
}

/// Opens [url] in the user's browser only if it is a safe https URL. Never throws.
Future<bool> openLink(UrlOpener opener, String url) async {
  if (!isSafeHttpsUrl(url)) return false;
  try {
    await opener.open(Uri.parse(url.trim()));
    return true;
  } catch (_) {
    return false;
  }
}
