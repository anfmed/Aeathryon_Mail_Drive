import 'dart:convert';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_brand/aethryon_brand.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mail_app/main.dart';

import 'helpers.dart';

Widget app([SecureStore? s, RecordingOpener? o]) => MailApp(services: testServices(store: s, opener: o));

Future<void> openAddAccount(WidgetTester t) async {
  await t.tap(find.text('Accounts'));
  await t.pumpAndSettle();
  await t.tap(find.text('Add account'));
  await t.pumpAndSettle();
}

Future<void> choose(WidgetTester t, String provider) async {
  await t.tap(find.byKey(const Key('profile')));
  await t.pumpAndSettle();
  await t.tap(find.text(provider).last);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('inbox syncs demo mail and flags the conversation', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Lunch?'), findsOneWidget);
    expect(find.text('Conversation'), findsNWidgets(2));
  });

  testWidgets('message view downloads the body and shows plain text only', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Welcome'));
    await t.pumpAndSettle();
    expect(find.textContaining('Welcome to Aethryon Mail'), findsWidgets);
    expect(find.textContaining('alert'), findsNothing);
    expect(find.textContaining('tracker.example'), findsNothing);
  });

  testWidgets('compose rejects empty recipient', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Compose'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    expect(find.text('Add at least one valid recipient.'), findsOneWidget);
  });

  testWidgets('settings: Proton shown as requiring a companion; storage problem explained', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    expect(find.text('requiresCompanion'), findsOneWidget);
    expect(find.textContaining('disabled in tests'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('auto-refresh preference is saved', (t) async {
    final store = SeededStore.mail();
    await t.pumpWidget(app(store));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('autorefresh')));
    await t.pumpAndSettle();
    await t.tap(find.text('Every 15 min').last);
    await t.pumpAndSettle();
    expect((await JsonSettings(store, 'aethryon.mail.settings').load())['autoRefreshMinutes'], 15);
    // leave the screen so the poll timer is disposed with the widget tree
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Proton cannot be added on a phone (default test platform = Android)', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await openAddAccount(t);
    await choose(t, 'Proton Mail (via Bridge)');
    expect(find.byKey(const Key('blocked')), findsOneWidget);
    expect(find.textContaining('desktop companion'), findsOneWidget);
  });

  testWidgets('Gmail offers browser sign-in with your own client ID (no password field)', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await openAddAccount(t);
    await choose(t, 'Gmail');
    expect(find.byKey(const Key('blocked')), findsNothing);
    expect(find.byKey(const Key('clientId')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsNothing);
    await t.tap(find.text('Sign in with browser'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error')), findsOneWidget);
  });

  testWidgets('Proton on desktop: still blocked (Bridge not implemented)', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await openAddAccount(t);
      await choose(t, 'Proton Mail (via Bridge)');
      expect(find.textContaining('not implemented'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iCloud prefills verified servers; password only in secure store', (t) async {
    final store = SeededStore.mail();
    await t.pumpWidget(app(store));
    await t.pumpAndSettle();
    await openAddAccount(t);
    await choose(t, 'iCloud Mail');
    expect(find.text('imap.mail.me.com'), findsOneWidget);
    await t.enterText(find.byKey(const Key('label')), 'My iCloud');
    await t.enterText(find.byKey(const Key('user')), 'me@icloud.com');
    await t.enterText(find.byKey(const Key('password')), 'abcd-efgh');
    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('My iCloud'), findsOneWidget);
    expect(find.textContaining('abcd-efgh'), findsNothing);
    final vault = AccountVault(store, 'aethryon.mail');
    final r = (await vault.list()).single;
    expect(r.settings.containsKey('password'), isFalse);
    expect(r.settings['auth'], 'password');
    expect(await vault.secret(r.id), 'abcd-efgh');
    expect(await AccountVault(store, 'aethryon.drive').list(), isEmpty);
  });

  testWidgets('accessibility: tap targets and labels (Inbox)', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('welcome: shown on first launch only, closed by Get Started, stays closed after a restart', (t) async {
    final store = SeededStore.mail(welcomeDone: false);
    await t.pumpWidget(app(store));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    await t.tap(find.text('Get Started'));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget); // the demo inbox message — the normal home screen works
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(app(store));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsNothing);
    expect(jsonDecode(store.m['aethryon.mail.settings']!)['welcomeDone'], true);
  });

  testWidgets('saving the auto-refresh interval keeps the welcome flag', (t) async {
    final store = SeededStore.mail();
    await t.pumpWidget(app(store));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('autorefresh')));
    await t.pumpAndSettle();
    await t.tap(find.text('Every 30 min').last);
    await t.pumpAndSettle();
    final saved = jsonDecode(store.m['aethryon.mail.settings']!) as Map<String, dynamic>;
    expect(saved['autoRefreshMinutes'], 30);
    expect(saved['welcomeDone'], true);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('about: credits, dynamic version; both actions open the configured urls', (t) async {
    final o = RecordingOpener();
    await t.pumpWidget(app(null, o));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.text('About'));
    await t.pumpAndSettle();
    expect(find.text('Md. Shakil Hossain'), findsOneWidget);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    await t.tap(find.byKey(const Key('about_get_in_touch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('about_support')));
    await t.pumpAndSettle();
    expect(o.opened.map((u) => u.toString()), [defaultLinks.getInTouchUrl, defaultLinks.supportUrl]);
  });

  testWidgets('Support button sits in the Inbox toolbar corner, beside (not over) the refresh action, and opens the same url', (t) async {
    final o = RecordingOpener();
    await t.pumpWidget(app(null, o));
    await t.pumpAndSettle();
    final support = t.getRect(find.byKey(const Key('support_button')));
    final refresh = t.getRect(find.byTooltip('Check for new mail'));
    final title = t.getRect(find.text('Aethryon Mail'));
    expect(support.overlaps(refresh), isFalse);
    expect(support.overlaps(title), isFalse);
    expect(support.right <= refresh.left + 1, isTrue); // Support sits to the left of Refresh
    await t.tap(find.byKey(const Key('support_button')));
    await t.pumpAndSettle();
    expect(o.opened.single.toString(), defaultLinks.supportUrl);
  });

  testWidgets('settings offers Send feedback', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.text('Send feedback'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('message')), findsOneWidget);
  });
}
