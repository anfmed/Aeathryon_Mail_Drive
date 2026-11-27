import 'dart:convert';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:drive_core/drive_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const fast = RetryPolicy(baseDelay: Duration(milliseconds: 1), maxDelay: Duration(milliseconds: 2));
DropboxAdapter dbx(MockClient c) => DropboxAdapter(accessToken: (_) async => 'TOK', client: c, retryPolicy: fast);

void main() {
  test('list_folder request shape, parsing and pagination', () async {
    final calls = <http.Request>[];
    final a = dbx(MockClient((req) async {
      calls.add(req);
      return http.Response(
          jsonEncode({
            'entries': [
              {'.tag': 'folder', 'name': 'Docs', 'path_display': '/Docs'},
              {'.tag': 'file', 'name': 'a.txt', 'path_display': '/Docs/a.txt', 'size': 3,
               'server_modified': '2026-01-02T03:04:05Z', 'rev': 'r1'},
            ],
            'cursor': 'C1',
            'has_more': true,
          }),
          200);
    }));
    final page = await a.listChildren('acc', '/');
    expect(calls.single.url.toString(), 'https://api.dropboxapi.com/2/files/list_folder');
    expect(jsonDecode(calls.single.body), {'path': '', 'limit': 200});
    expect(calls.single.headers['Authorization'], 'Bearer TOK');
    expect(page.items.map((e) => e.name), ['Docs', 'a.txt']);
    expect(page.items[0].isFolder, isTrue);
    expect(page.items[1].size, 3);
    expect(page.items[1].parentId, '/Docs');
    expect(page.items[1].modifiedUtc, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(page.nextCursor, 'C1');
    await a.listChildren('acc', '/', cursor: 'C1');
    expect(calls.last.url.path, '/2/files/list_folder/continue');
    expect(jsonDecode(calls.last.body), {'cursor': 'C1'});
  });

  test('asciiJson escapes non-ASCII for the Dropbox-API-Arg header', () {
    final s = asciiJson({'path': '/café/অর্থ'});
    expect(s.codeUnits.every((u) => u < 0x80), isTrue);
    expect(jsonDecode(s), {'path': '/café/অর্থ'});
  });

  test('download sends API-Arg and Range, never the token in the URL', () async {
    late http.Request r;
    final a = dbx(MockClient((req) async {
      r = req;
      return http.Response.bytes([1, 2], 206);
    }));
    final got = await a.download('acc', '/f', start: 5, endInclusive: 6).expand((e) => e).toList();
    expect(got, [1, 2]);
    expect(r.headers['Dropbox-API-Arg'], '{"path":"/f"}');
    expect(r.headers['Range'], 'bytes=5-6');
    expect(r.url.toString().contains('TOK'), isFalse);
  });

  test('401 is surfaced without retry', () async {
    var n = 0;
    final a = dbx(MockClient((_) async {
      n++;
      return http.Response('{"error":"x"}', 401);
    }));
    await expectLater(a.listChildren('acc', '/'), throwsA(isA<ProviderHttpError>()));
    expect(n, 1);
  });

  test('single upload refuses large files (RAM protection)', () async {
    final a = dbx(MockClient((_) async => http.Response('{}', 200)));
    await expectLater(
        a.upload('acc', '/', 'big', const Stream.empty(), DropboxAdapter.singleUploadLimit + 1), throwsArgumentError);
  });

  test('resumable flow: start -> append(0,4,8) -> finish(10)', () async {
    final log = <String>[];
    final a = dbx(MockClient((req) async {
      final arg = jsonDecode(req.headers['Dropbox-API-Arg'] ?? '{}') as Map<String, dynamic>;
      log.add('${req.url.pathSegments.last}:${(arg['cursor'] as Map?)?['offset'] ?? '-'}:${req.bodyBytes.length}');
      if (req.url.path.endsWith('upload_session/start')) return http.Response('{"session_id":"S1"}', 200);
      if (req.url.path.endsWith('upload_session/finish')) {
        expect((arg['commit'] as Map)['path'], '/dir/f.bin');
        return http.Response('{".tag":"file","name":"f.bin","path_display":"/dir/f.bin","size":10}', 200);
      }
      return http.Response('', 200);
    }));
    final node = await TransferRunner().upload(
        uploader: a, source: MemorySource(List.generate(10, (i) => i)),
        accountId: 'acc', parentId: '/dir', name: 'f.bin', preferredChunk: 4);
    expect(log, ['start:-:0', 'append_v2:0:4', 'append_v2:4:4', 'append_v2:8:2', 'finish:10:0']);
    expect(node.name, 'f.bin');
  });
}
