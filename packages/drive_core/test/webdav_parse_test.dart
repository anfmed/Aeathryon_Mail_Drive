import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

const body = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
 <d:response><d:href>/remote.php/dav/files/u/Docs/</d:href>
  <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
  <d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
 <d:response><d:href>/remote.php/dav/files/u/Docs/My%20File.txt</d:href>
  <d:propstat><d:prop><d:resourcetype/><d:getcontentlength>42</d:getcontentlength>
  <d:getlastmodified>Wed, 21 Oct 2026 07:28:00 GMT</d:getlastmodified>
  <d:getetag>"abc123"</d:getetag></d:prop>
  <d:status>HTTP/1.1 200 OK</d:status></d:propstat>
  <d:propstat><d:prop><d:foo/></d:prop><d:status>HTTP/1.1 404 Not Found</d:status></d:propstat></d:response>
 <d:response><d:href>/remote.php/dav/files/u/Docs/Sub/</d:href>
  <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
  <d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';

void main() {
  test('parses files and folders, skips self', () {
    final n = parsePropfind(
      body,
      accountId: 'acc',
      requestedPath: '/remote.php/dav/files/u/Docs/',
    );
    expect(n.length, 2);
    final f = n.firstWhere((e) => !e.isFolder);
    expect(f.name, 'My File.txt');
    expect(f.size, 42);
    expect(f.etag, 'abc123');
    expect(f.modifiedUtc, DateTime.utc(2026, 10, 21, 7, 28));
    expect(f.parentId, '/remote.php/dav/files/u/Docs');
    expect(n.firstWhere((e) => e.isFolder).name, 'Sub');
  });
}
