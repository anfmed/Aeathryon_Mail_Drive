import 'dart:convert';
import 'package:aethryon_brand_core/aethryon_brand_core.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class MemStore implements SecureStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

class RecordingOpener implements UrlOpener {
  final opened = <Uri>[];
  bool fail = false;
  @override
  Future<void> open(Uri url) async {
    if (fail) throw StateError('no browser');
    opened.add(url);
  }
}

LinkConfigService svc(MemStore s, http.Client c, {String base = 'https://aus.example', DateTime Function()? now, Duration ttl = const Duration(hours: 6)}) =>
    LinkConfigService(cache: JsonSettings(s, 'links'), client: c, baseUrl: base, now: now, ttl: ttl);

http.Response ok(Object body) => http.Response(jsonEncode(body), 200);

void main() {
  test('default links are the documented fallbacks', () {
    expect(defaultLinks.getInTouchUrl, 'https://aethryon-labs.sh010.workers.dev/');
    expect(defaultLinks.supportUrl, 'https://aethryon-labs.sh010.workers.dev/support/');
    expect(svc(MemStore(), MockClient((_) async => http.Response('', 500))).links, defaultLinks);
  });

  test('isSafeHttpsUrl accepts https only and rejects unsafe values', () {
    for (final good in ['https://a.example', 'https://a.example/p?q=1', ' https://a.example/x ']) {
      expect(isSafeHttpsUrl(good), isTrue, reason: good);
    }
    for (final bad in [null, '', 'http://a.example', 'javascript:alert(1)', 'file:///etc/passwd', 'intent://x#Intent;end',
      'https://user:pw@a.example', 'https://', 'https://a b.example', 'mailto:a@b.c', '//a.example', 'https://${'a' * 2100}.example']) {
      expect(isSafeHttpsUrl(bad), isFalse, reason: '$bad');
    }
  });

  test('a valid remote configuration replaces BOTH urls, is cached, and notifies', () async {
    final store = MemStore();
    final s = svc(store, MockClient((req) async {
      expect(req.url.toString(), 'https://aus.example/v1/links');
      return ok({'get_in_touch_url': 'https://new.example/contact', 'support_url': 'https://new.example/help'});
    }));
    await s.init();
    final seen = <AppLinks>[];
    s.changes.listen(seen.add);
    expect(await s.refresh(), isTrue);
    expect(s.links.getInTouchUrl, 'https://new.example/contact');
    expect(s.links.supportUrl, 'https://new.example/help');
    await Future<void>.delayed(Duration.zero);
    expect(seen.single, s.links);
    expect(jsonDecode(store.m['links']!)['supportUrl'], 'https://new.example/help');
  });

  test('camelCase and nested shapes are understood', () async {
    final a = svc(MemStore(), MockClient((_) async => ok({'getInTouchUrl': 'https://x.example/a', 'supportUrl': 'https://x.example/b'})));
    await a.refresh();
    expect(a.links.supportUrl, 'https://x.example/b');
    final b = svc(MemStore(), MockClient((_) async => ok({'links': {'get_in_touch_url': 'https://y.example/a', 'support_url': 'https://y.example/b'}})));
    await b.refresh();
    expect(b.links.getInTouchUrl, 'https://y.example/a');
  });

  test('invalid remote values never replace a valid configuration (per field)', () async {
    final store = MemStore();
    var body = <String, Object?>{'get_in_touch_url': 'https://good.example/c', 'support_url': 'https://good.example/s'};
    final s = svc(store, MockClient((_) async => ok(body)), ttl: Duration.zero);
    await s.refresh();
    body = {'get_in_touch_url': 'javascript:alert(1)', 'support_url': 'https://good2.example/s'};
    await s.refresh();
    expect(s.links.getInTouchUrl, 'https://good.example/c'); // unsafe value ignored
    expect(s.links.supportUrl, 'https://good2.example/s'); // valid one applied
    body = {'get_in_touch_url': 42, 'support_url': ''};
    expect(await s.refresh(), isFalse);
    body = {'unrelated': true};
    expect(await s.refresh(), isFalse);
    expect(s.links.getInTouchUrl, 'https://good.example/c');
  });

  test('malformed JSON, non-200 and exceptions keep the current links', () async {
    for (final c in <http.Client>[
      MockClient((_) async => http.Response('not json', 200)),
      MockClient((_) async => http.Response('{}', 500)),
      MockClient((_) async => throw StateError('offline')),
      MockClient((_) async => http.Response('[1,2]', 200)),
    ]) {
      final s = svc(MemStore(), c);
      expect(await s.refresh(), isFalse);
      expect(s.links, defaultLinks);
    }
  });

  test('cached configuration survives a restart and works offline', () async {
    final store = MemStore();
    final first = svc(store, MockClient((_) async => ok({'support_url': 'https://cached.example/s', 'get_in_touch_url': 'https://cached.example/c'})));
    await first.refresh();
    final second = svc(store, MockClient((_) async => throw StateError('offline'))); // new "launch", no network
    await second.init();
    expect(second.links.supportUrl, 'https://cached.example/s');
    await second.refresh(force: true);
    expect(second.links.supportUrl, 'https://cached.example/s');
  });

  test('a corrupted cache falls back to defaults without throwing', () async {
    final store = MemStore()..m['links'] = jsonEncode({'getInTouchUrl': 5, 'supportUrl': 'http://insecure.example'});
    final s = svc(store, MockClient((_) async => http.Response('', 500)));
    await s.init();
    expect(s.links, defaultLinks);
  });

  test('requests are throttled by the ttl; force bypasses it', () async {
    var calls = 0;
    var t = DateTime.utc(2026);
    final s = svc(MemStore(), MockClient((_) async {
      calls++;
      return ok({'support_url': 'https://t.example/$calls'});
    }), now: () => t);
    await s.refresh();
    await s.refresh();
    expect(calls, 1);
    t = t.add(const Duration(hours: 7));
    await s.refresh();
    expect(calls, 2);
    await s.refresh(force: true);
    expect(calls, 3);
  });

  test('no AUS base url (or an insecure one) means no network at all', () async {
    var calls = 0;
    final c = MockClient((_) async {
      calls++;
      return ok({});
    });
    expect(await svc(MemStore(), c, base: '').refresh(), isFalse);
    expect(await svc(MemStore(), c, base: 'http://aus.example').refresh(), isFalse);
    expect(calls, 0);
  });

  test('openLink opens safe urls only and never throws', () async {
    final o = RecordingOpener();
    expect(await openLink(o, 'https://ok.example/x'), isTrue);
    expect(o.opened.single.host, 'ok.example');
    expect(await openLink(o, 'javascript:alert(1)'), isFalse);
    expect(await openLink(o, 'http://insecure.example'), isFalse);
    expect(o.opened.length, 1);
    o.fail = true;
    expect(await openLink(o, 'https://ok.example/x'), isFalse);
  });

  test('credits keep the organisation and the developer separate', () {
    expect(aethryonCredits.organization, 'Aethryon Labs');
    expect(aethryonCredits.developers, ['Md. Shakil Hossain']);
    expect(aethryonCredits.developers, isNot(contains('Aethryon Labs')));
    expect(const AppVersion('1.2.3', '45').display, '1.2.3 (45)');
    expect(const AppVersion('1.2.3').display, '1.2.3');
  });
}
