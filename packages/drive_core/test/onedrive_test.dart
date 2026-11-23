import 'dart:convert';

import 'package:aethryon_net/aethryon_net.dart';
import 'package:drive_core/drive_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const fast = RetryPolicy(
  baseDelay: Duration(milliseconds: 1),
  maxDelay: Duration(milliseconds: 2),
);
OneDriveAdapter od(MockClient c) => OneDriveAdapter(
  accessToken: (_) async => 'TOK',
  client: c,
  retryPolicy: fast,
);

void main() {
  test('list children: folders vs files, nextLink as cursor', () async {
    final urls = <String>[];
    final a = od(
      MockClient((req) async {
        urls.add(req.url.toString());
        return http.Response(
          jsonEncode({
            'value': [
              {
                'id': '1',
                'name': 'Docs',
                'folder': {'childCount': 1},
                'parentReference': {'id': 'R'},
              },
              {
                'id': '2',
                'name': 'a.txt',
                'size': 4,
                'file': {},
                'eTag': 'e',
                'lastModifiedDateTime': '2026-01-02T03:04:05Z',
              },
            ],
            '@odata.nextLink': 'https://graph.microsoft.com/v1.0/next',
          }),
          200,
        );
      }),
    );
    final p = await a.listChildren('acc', '/');
    expect(
      urls.single,
      'https://graph.microsoft.com/v1.0/me/drive/root/children',
    );
    expect(p.items[0].isFolder, isTrue);
    expect(p.items[0].size, isNull);
    expect(p.items[1].size, 4);
    expect(p.items[1].etag, 'e');
    expect(p.nextCursor, 'https://graph.microsoft.com/v1.0/next');
    await a.listChildren('acc', '1', cursor: p.nextCursor);
    expect(urls.last, 'https://graph.microsoft.com/v1.0/next');
    await a.listChildren('acc', 'abc');
    expect(
      urls.last,
      'https://graph.microsoft.com/v1.0/me/drive/items/abc/children',
    );
  });

  test(
    'download follows the redirect WITHOUT forwarding the bearer token',
    () async {
      final seen = <http.Request>[];
      final a = od(
        MockClient((req) async {
          seen.add(req);
          if (seen.length == 1) {
            return http.Response(
              '',
              302,
              headers: {'location': 'https://dl.example/blob'},
            );
          }
          return http.Response.bytes([7, 8], 206);
        }),
      );
      final got = await a
          .download('acc', 'item1', start: 3, endInclusive: 4)
          .expand((e) => e)
          .toList();
      expect(got, [7, 8]);
      expect(seen[0].headers['Authorization'], 'Bearer TOK');
      expect(seen[0].url.path, '/v1.0/me/drive/items/item1/content');
      expect(seen[1].url.host, 'dl.example');
      expect(seen[1].headers.containsKey('Authorization'), isFalse);
      expect(seen[1].headers['Range'], 'bytes=3-4');
    },
  );

  test('resumable upload: 320 KiB multiples, no bearer on the upload URL, final item returned', () async {
    final puts = <http.Request>[];
    http.Request? begin;
    final a = od(
      MockClient((req) async {
        if (req.url.path.endsWith('createUploadSession')) {
          begin = req;
          return http.Response('{"uploadUrl":"https://up.example/u1"}', 200);
        }
        if (req.method == 'GET' && req.url.host == 'up.example') {
          return http.Response('{"nextExpectedRanges":["0-"]}', 200);
        }
        puts.add(req);
        final last = req.headers['Content-Range']!.contains('655360-799999');
        return last
            ? http.Response(
                '{"id":"9","name":"big file.bin","size":800000,"file":{}}',
                201,
              )
            : http.Response('{"nextExpectedRanges":["x-"]}', 202);
      }),
    );
    final node = await TransferRunner().upload(
      uploader: a,
      source: MemorySource(List.filled(800000, 1)),
      accountId: 'acc',
      parentId: '/',
      name: 'big file.bin',
      preferredChunk: 327680,
    );
    expect(
      begin!.url.toString(),
      contains(':/big%20file.bin:/createUploadSession'),
    );
    expect(puts.map((r) => r.headers['Content-Range']), [
      'bytes 0-327679/800000',
      'bytes 327680-655359/800000',
      'bytes 655360-799999/800000',
    ]);
    expect(puts.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    expect(node.name, 'big file.bin');
  });

  test(
    'finish before the server returned the final item is an error',
    () async {
      final a = od(
        MockClient((req) async {
          if (req.url.path.endsWith('createUploadSession'))
            return http.Response('{"uploadUrl":"https://up.example/u"}', 200);
          return http.Response('{"nextExpectedRanges":["0-"]}', 202);
        }),
      );
      final s = await a.begin('acc', '/', 'f', 10);
      await expectLater(s.finish(), throwsStateError);
    },
  );

  test('delete maps to DELETE on the item; 404 is permanent', () async {
    final a = od(
      MockClient(
        (req) async => req.method == 'DELETE'
            ? http.Response('', 404)
            : http.Response('{}', 200),
      ),
    );
    await expectLater(
      a.permanentDelete('acc', 'zzz'),
      throwsA(isA<ProviderHttpError>()),
    );
  });

  test('provider capabilities stay conservative', () {
    final a = od(MockClient((_) async => http.Response('{}', 200)));
    expect(a.capability(DriveFeature.share).enabledInUi, isFalse);
    expect(a.capability(DriveFeature.trash).enabledInUi, isFalse);
  });
}
