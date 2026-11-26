import 'package:aethryon_net/aethryon_net.dart';
import 'package:drive_core/drive_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const multistatus = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
 <d:response><d:href>/dav/Docs/</d:href><d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
 <d:response><d:href>/dav/Docs/My%20File.txt</d:href><d:propstat><d:prop><d:resourcetype/><d:getcontentlength>5</d:getcontentlength></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';

const fast = RetryPolicy(
  baseDelay: Duration(milliseconds: 1),
  maxDelay: Duration(milliseconds: 2),
);

WebDavAdapter adapter(http.Client c) => WebDavAdapter(
  baseUrl: Uri.parse('https://h.example/dav/'),
  authorizationHeader: (_) async => 'Basic x',
  client: c,
  retryPolicy: fast,
);

void main() {
  test(
    'retry replays the SAME body on every attempt (regression: stream reuse)',
    () async {
      final bodies = <String>[];
      var n = 0;
      final a = adapter(
        MockClient((req) async {
          bodies.add(req.body);
          n++;
          return n == 1
              ? http.Response('', 503)
              : http.Response(multistatus, 207);
        }),
      );
      final r = await a.listChildren('acc', '/Docs');
      expect(n, 2);
      expect(bodies[0], bodies[1]);
      expect(bodies[0], contains('propfind'));
      expect(r.items.map((e) => e.name), [
        'My File.txt',
      ]); // decoded name, self entry skipped
    },
  );

  test('request carries method, depth and auth', () async {
    late http.Request seen;
    final a = adapter(
      MockClient((req) async {
        seen = req;
        return http.Response(multistatus, 207);
      }),
    );
    await a.listChildren('acc', '/Docs');
    expect(seen.method, 'PROPFIND');
    expect(seen.headers['Depth'], '1');
    expect(seen.headers['Authorization'], 'Basic x');
    expect(seen.url.toString(), 'https://h.example/dav/Docs');
  });

  test('404 is permanent: one attempt, ProviderHttpError', () async {
    var n = 0;
    final a = adapter(
      MockClient((_) async {
        n++;
        return http.Response('', 404);
      }),
    );
    await expectLater(
      a.metadata('acc', '/nope'),
      throwsA(
        isA<ProviderHttpError>().having((e) => e.statusCode, 'status', 404),
      ),
    );
    expect(n, 1);
  });

  test('401 is not retried', () async {
    var n = 0;
    final a = adapter(
      MockClient((_) async {
        n++;
        return http.Response('', 401);
      }),
    );
    await expectLater(
      a.listChildren('acc', '/'),
      throwsA(
        isA<ProviderHttpError>().having((e) => e.statusCode, 'status', 401),
      ),
    );
    expect(n, 1);
  });

  test('persistent 503 ends as RetryExhausted after maxAttempts', () async {
    var n = 0;
    final a = adapter(
      MockClient((_) async {
        n++;
        return http.Response('', 503);
      }),
    );
    await expectLater(
      a.listChildren('acc', '/'),
      throwsA(isA<RetryExhausted>()),
    );
    expect(n, fast.maxAttempts);
  });

  test('upload is never auto-retried (one-shot stream)', () async {
    var n = 0;
    final a = adapter(
      MockClient((_) async {
        n++;
        return http.Response('', 503);
      }),
    );
    await expectLater(
      a.upload('acc', '/', 'f.bin', Stream.value([1, 2, 3]), 3),
      throwsA(isA<ProviderHttpError>()),
    );
    expect(n, 1);
  });

  test('upload sends PUT with the exact bytes', () async {
    late http.Request put;
    final a = adapter(
      MockClient((req) async {
        if (req.method == 'PUT') {
          put = req;
          return http.Response('', 201);
        }
        return http.Response(multistatus, 207); // follow-up metadata PROPFIND
      }),
    );
    await a.upload('acc', '/Docs', 'My File.txt', Stream.value([1, 2, 3]), 3);
    expect(put.bodyBytes, [1, 2, 3]);
    expect(put.url.path, '/dav/Docs/My%20File.txt');
  });

  test('ranged download sends Range header', () async {
    late http.Request req0;
    final a = adapter(
      MockClient((req) async {
        req0 = req;
        return http.Response.bytes([9, 9], 206);
      }),
    );
    final got = await a
        .download('acc', '/f', start: 5, endInclusive: 6)
        .expand((e) => e)
        .toList();
    expect(req0.headers['Range'], 'bytes=5-6');
    expect(got, [9, 9]);
  });

  test('validateServerUrl: https only, http only for loopback', () {
    expect(
      validateServerUrl('https://cloud.example/remote.php/dav/files/u/'),
      isNull,
    );
    expect(validateServerUrl('http://localhost:8081/'), isNull);
    expect(validateServerUrl('http://cloud.example/'), isNotNull);
    expect(validateServerUrl('ftp://x/'), isNotNull);
    expect(validateServerUrl(''), isNotNull);
    expect(validateServerUrl('not a url'), isNotNull);
  });
}
