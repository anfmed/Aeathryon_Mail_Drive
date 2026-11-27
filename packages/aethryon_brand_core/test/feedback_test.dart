import 'dart:convert';

import 'package:aethryon_brand_core/aethryon_brand_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

FeedbackClient client(
  http.Client c, {
  String base = 'https://aus.example',
  String app = 'com.aethryon.drive_app',
}) => FeedbackClient(baseUrl: base, appId: app, client: c);

Future<FeedbackOutcome> send(
  FeedbackClient c, {
  String message = 'Nice app',
  String category = 'praise',
  String contact = '',
}) => c.send(
  message: message,
  category: category,
  contact: contact,
  appVersion: '1.2.3',
  platform: 'android',
);

void main() {
  test(
    'request matches the AUS contract exactly and sends nothing else',
    () async {
      late http.Request req;
      final r = await send(
        client(
          MockClient((q) async {
            req = q;
            return http.Response('', 202);
          }),
        ),
        message: '  Great work  ',
        contact: ' me@example.com ',
      );
      expect(r, FeedbackOutcome.sent);
      expect(req.method, 'POST');
      expect(req.url.toString(), 'https://aus.example/v1/feedback');
      expect(req.headers['Content-Type'], contains('application/json'));
      final j = jsonDecode(req.body) as Map<String, dynamic>;
      expect(j.keys.toSet(), {
        'source',
        'message',
        'category',
        'contact',
        'appVersion',
        'platform',
        'website',
      });
      expect(j['source'], 'com.aethryon.drive_app');
      expect(j['message'], 'Great work');
      expect(j['contact'], 'me@example.com');
      expect(j['website'], '');
      expect(j['appVersion'], '1.2.3');
      expect(j['platform'], 'android');
    },
  );

  test('empty contact is omitted', () async {
    late Map<String, dynamic> j;
    await send(
      client(
        MockClient((q) async {
          j = jsonDecode(q.body) as Map<String, dynamic>;
          return http.Response('', 202);
        }),
      ),
    );
    expect(j.containsKey('contact'), isFalse);
  });

  test('status mapping: 202 sent, 429 rateLimited, 400 invalid, 500 failed, exception failed', () async {
    Future<FeedbackOutcome> with_(int code) =>
        send(client(MockClient((_) async => http.Response('', code))));
    expect(await with_(202), FeedbackOutcome.sent);
    expect(await with_(429), FeedbackOutcome.rateLimited);
    expect(await with_(400), FeedbackOutcome.invalid);
    expect(await with_(500), FeedbackOutcome.failed);
    expect(
      await send(client(MockClient((_) async => throw StateError('offline')))),
      FeedbackOutcome.failed,
    );
  });

  test('validation happens before any network call', () async {
    var calls = 0;
    final c = client(
      MockClient((_) async {
        calls++;
        return http.Response('', 202);
      }),
    );
    expect(await send(c, message: 'ab'), FeedbackOutcome.invalid);
    expect(await send(c, message: '   a  '), FeedbackOutcome.invalid);
    expect(await send(c, message: 'x' * 2001), FeedbackOutcome.invalid);
    expect(await send(c, category: 'spam'), FeedbackOutcome.invalid);
    expect(await send(c, contact: 'c' * 201), FeedbackOutcome.invalid);
    expect(calls, 0);
    expect(await send(c, message: 'abc'), FeedbackOutcome.sent);
    expect(await send(c, message: 'x' * 2000), FeedbackOutcome.sent);
    expect(calls, 2);
  });

  test(
    'not configured (no AUS url or app id) never touches the network',
    () async {
      var calls = 0;
      final http_ = MockClient((_) async {
        calls++;
        return http.Response('', 202);
      });
      expect(
        await send(client(http_, base: '')),
        FeedbackOutcome.notConfigured,
      );
      expect(await send(client(http_, app: '')), FeedbackOutcome.notConfigured);
      expect(calls, 0);
    },
  );

  test('message validation text', () {
    expect(FeedbackClient.validateMessage('ab'), isNotNull);
    expect(FeedbackClient.validateMessage('abc'), isNull);
    expect(FeedbackClient.validateMessage('x' * 2001), isNotNull);
  });
}
