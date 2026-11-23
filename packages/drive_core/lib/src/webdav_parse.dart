import 'dart:io' show HttpDate;
import 'package:xml/xml.dart';
import 'models.dart';

String _local(XmlElement e) => e.name.local;

Iterable<XmlElement> _kids(XmlElement e, String local) =>
    e.childElements.where((c) => _local(c) == local);

String _decodeHrefToPath(String href) {
  // href may be absolute URL or absolute path; keep path only, decode per segment.
  final uri = Uri.parse(href);
  final segs = uri.pathSegments; // already percent-decoded by Uri
  return '/${segs.join('/')}';
}

/// Parses a PROPFIND multistatus body. [requestedPath] (decoded, no trailing
/// slash handling required) is used to drop the self-entry and to compute parent.
/// Only propstat blocks with a 200 status contribute properties.
List<RemoteNode> parsePropfind(String body,
    {required String accountId, required String requestedPath}) {
  final doc = XmlDocument.parse(body);
  final self = _normalize(requestedPath);
  final out = <RemoteNode>[];

  for (final resp in doc.descendants.whereType<XmlElement>().where((e) => _local(e) == 'response')) {
    final hrefEl = _kids(resp, 'href').firstOrNull;
    if (hrefEl == null) continue;
    final rawPath = _decodeHrefToPath(hrefEl.innerText.trim());
    final path = _normalize(rawPath);
    if (path == self) continue;

    String? etag;
    int? size;
    DateTime? modified;
    var isFolder = false;

    for (final ps in _kids(resp, 'propstat')) {
      final status = _kids(ps, 'status').firstOrNull?.innerText ?? '';
      if (!status.contains(' 200')) continue;
      for (final prop in _kids(ps, 'prop')) {
        for (final p in prop.childElements) {
          switch (_local(p)) {
            case 'getetag':
              etag = p.innerText.trim().replaceAll('"', '');
              break;
            case 'getcontentlength':
              size = int.tryParse(p.innerText.trim());
              break;
            case 'getlastmodified':
              try {
                modified = HttpDate.parse(p.innerText.trim()).toUtc();
              } catch (_) {}
              break;
            case 'resourcetype':
              isFolder = p.childElements.any((c) => _local(c) == 'collection');
              break;
          }
        }
      }
    }

    final segs = path.split('/').where((s) => s.isNotEmpty).toList();
    final name = segs.isEmpty ? '/' : segs.last;
    final parent = segs.length <= 1 ? '/' : '/${segs.sublist(0, segs.length - 1).join('/')}';
    out.add(RemoteNode(
      accountId: accountId,
      id: path,
      parentId: parent,
      name: name,
      isFolder: isFolder,
      size: isFolder ? null : size,
      modifiedUtc: modified,
      etag: etag,
    ));
  }
  return out;
}

String _normalize(String p) {
  var s = p;
  if (!s.startsWith('/')) s = '/$s';
  while (s.length > 1 && s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
