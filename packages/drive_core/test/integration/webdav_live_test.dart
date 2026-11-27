// Runs only when WEBDAV_URL is set (CI starts a local wsgidav server).
// Until this passes in CI, WebDAV capabilities stay UNVERIFIED.
import 'dart:io';
import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

void main() {
  final url = Platform.environment['WEBDAV_URL'];
  if (url == null) {
    test('webdav live (skipped: WEBDAV_URL not set)', () {}, skip: 'no server');
    return;
  }
  final a = WebDavAdapter(baseUrl: Uri.parse(url), authorizationHeader: (_) async => null);
  const acc = 'live';
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final dir = 'it_$stamp';

  test('mkdir, upload, list, ranged download, move, delete', () async {
    await a.mkdir(acc, '/', dir);
    final data = List<int>.generate(1000, (i) => i % 251);
    await a.upload(acc, '/$dir', 'file one.bin', Stream.value(data), data.length);

    final listed = await a.listChildren(acc, '/$dir');
    expect(listed.items.map((e) => e.name), ['file one.bin']);
    expect(listed.items.single.size, 1000);

    final part = await a.download(acc, '/$dir/file one.bin', start: 10, endInclusive: 19).expand((e) => e).toList();
    expect(part, data.sublist(10, 20));

    await a.move(acc, '/$dir/file one.bin', '/$dir', 'moved.bin');
    expect((await a.listChildren(acc, '/$dir')).items.map((e) => e.name), ['moved.bin']);

    await a.permanentDelete(acc, '/$dir');
  });

  test('missing resource surfaces a 404 error', () async {
    await expectLater(a.metadata(acc, '/does-not-exist-$stamp'), throwsA(isA<ProviderHttpError>()));
  });
}
