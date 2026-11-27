import 'dart:convert';

import 'package:aethryon_brand/aethryon_brand.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  @override
  Future<void> open(Uri url) async => opened.add(url);
}

class FakeInfo implements AppInfo {
  @override
  Future<AppVersion> load() async => const AppVersion('1.2.3', '45');
}

BrandServices services(
  RecordingOpener o, {
  http.Client? client,
  String aus = '',
}) {
  final c = client ?? MockClient((_) async => http.Response('{}', 500));
  return BrandServices.create(
    store: MemStore(),
    opener: o,
    httpClient: c,
    info: FakeInfo(),
    linksCacheKey: 'links',
    ausBaseUrl: aus,
    appId: 'com.aethryon.test_app',
  );
}

Widget host(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets(
    'welcome dialog shows the exact content, credits, logo, dynamic version and closes with Get Started',
    (t) async {
      final s = services(RecordingOpener());
      await t.pumpWidget(
        host(
          Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showWelcomeDialog(c, s),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('Thank You for Choosing Our App'), findsOneWidget);
      expect(
        find.textContaining("We're delighted to have you here!"),
        findsOneWidget,
      );
      expect(find.text('DEVELOPED BY'), findsOneWidget);
      expect(
        find.text('Aethryon Labs'),
        findsWidgets,
      ); // text credit (logo has an asset fallback too)
      expect(find.text('DEVELOPER'), findsOneWidget);
      expect(find.text('Md. Shakil Hossain'), findsOneWidget);
      expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
      expect(find.bySemanticsLabel('Aethryon Labs logo'), findsOneWidget);
      expect(
        find.textContaining('eedback'),
        findsNothing,
      ); // no feedback request or button in the welcome dialog
      expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
      await t.tap(find.text('Get Started'));
      await t.pumpAndSettle();
      expect(find.text('Welcome!'), findsNothing);
    },
  );

  testWidgets(
    'about: credits, dynamic version, both actions open the configured urls',
    (t) async {
      final o = RecordingOpener();
      await t.pumpWidget(host(AboutScreen(services: services(o))));
      await t.pumpAndSettle();
      expect(find.text('DEVELOPED BY'), findsOneWidget);
      expect(find.text('Md. Shakil Hossain'), findsOneWidget);
      expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
      await t.tap(find.byKey(const Key('about_get_in_touch')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('about_support')));
      await t.pumpAndSettle();
      expect(o.opened.map((u) => u.toString()), [
        defaultLinks.getInTouchUrl,
        defaultLinks.supportUrl,
      ]);
    },
  );

  testWidgets(
    'the separate Support button and About/Support open the SAME url, also after a remote update',
    (t) async {
      final o = RecordingOpener();
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'get_in_touch_url': 'https://aus.example/contact',
            'support_url': 'https://aus.example/help',
          }),
          200,
        ),
      );
      final s = services(o, client: client, aus: 'https://aus.example');
      await t.runAsync(() async {
        await s.links.init();
        await s.links.refresh();
      });
      await t.pumpWidget(
        host(
          Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              actions: [SupportButton(services: s)],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('support_button')));
      await t.pumpAndSettle();
      await t.pumpWidget(host(AboutScreen(services: s)));
      await t.tap(find.byKey(const Key('about_support')));
      await t.pumpAndSettle();
      expect(o.opened.map((u) => u.toString()), [
        'https://aus.example/help',
        'https://aus.example/help',
      ]);
    },
  );

  testWidgets(
    'support button sits in the AppBar corner without overlapping neighbours; tap target is large enough',
    (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(
        host(
          Scaffold(
            appBar: AppBar(
              title: const Text('Aethryon Mail'),
              actions: [
                SupportButton(services: services(RecordingOpener())),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Check for new mail',
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      final bar = t.getRect(find.byType(AppBar));
      final support = t.getRect(find.byKey(const Key('support_button')));
      final refresh = t.getRect(find.byTooltip('Check for new mail'));
      final title = t.getRect(find.text('Aethryon Mail'));
      expect(
        bar.contains(support.topLeft) && bar.contains(support.bottomRight),
        isTrue,
      );
      expect(support.overlaps(refresh), isFalse);
      expect(support.overlaps(title), isFalse);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    },
  );

  testWidgets('an unsafe configured url is never opened and the user is told', (
    t,
  ) async {
    final o = RecordingOpener();
    final s = BrandServices(
      links: _FixedLinks(
        const AppLinks(
          getInTouchUrl: 'javascript:alert(1)',
          supportUrl: 'http://insecure.example',
        ),
      ),
      opener: o,
      info: FakeInfo(),
      feedback: FeedbackClient(
        baseUrl: '',
        appId: '',
        client: MockClient((_) async => http.Response('', 500)),
      ),
    );
    await t.pumpWidget(host(AboutScreen(services: s)));
    await t.tap(find.byKey(const Key('about_get_in_touch')));
    await t.pumpAndSettle();
    expect(o.opened, isEmpty);
    expect(find.text('Could not open the link.'), findsOneWidget);
  });

  group('feedback screen', () {
    Future<void> fill(WidgetTester t, String text) async {
      await t.enterText(find.byKey(const Key('message')), text);
      await t.ensureVisible(find.text('Send'));
    }

    testWidgets('too-short text is rejected locally', (t) async {
      await t.pumpWidget(
        host(
          FeedbackScreen(
            services: services(RecordingOpener(), aus: 'https://aus.example'),
          ),
        ),
      );
      await fill(t, 'ab');
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(find.text('Please write at least 3 characters.'), findsOneWidget);
    });

    testWidgets('success clears the text; failure and rate limit keep it', (
      t,
    ) async {
      var code = 500;
      Map<String, dynamic>? body;
      final c = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', code);
      });
      await t.pumpWidget(
        host(
          FeedbackScreen(
            services: services(
              RecordingOpener(),
              client: c,
              aus: 'https://aus.example',
            ),
          ),
        ),
      );
      await fill(t, 'Please add dark mode');
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(find.textContaining('Your text is kept'), findsOneWidget);
      expect(find.text('Please add dark mode'), findsOneWidget);
      code = 429;
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(find.textContaining('too quickly'), findsOneWidget);
      expect(find.text('Please add dark mode'), findsOneWidget);
      code = 202;
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(find.text('Thank you! Your feedback was sent.'), findsOneWidget);
      expect(find.text('Please add dark mode'), findsNothing);
      expect(body!['source'], 'com.aethryon.test_app');
      expect(body!['appVersion'], '1.2.3');
      expect(body!.containsKey('contact'), isFalse);
    });

    testWidgets('without an AUS url the screen says feedback is not set up', (
      t,
    ) async {
      await t.pumpWidget(
        host(FeedbackScreen(services: services(RecordingOpener()))),
      );
      await fill(t, 'Hello there');
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(
        find.text('Feedback is not set up in this build.'),
        findsOneWidget,
      );
    });
  });
}

class _FixedLinks extends LinkConfigService {
  final AppLinks _fixed;
  _FixedLinks(this._fixed)
    : super(
        cache: JsonSettings(MemStore(), 'x'),
        client: MockClient((_) async => http.Response('', 500)),
      );
  @override
  AppLinks get links => _fixed;
}
