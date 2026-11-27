import 'dart:convert';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_brand/aethryon_brand.dart';
import 'package:drive_app/main.dart';
import 'package:drive_app/services.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Widget app({SecureStore? store, Future<DriveDb> Function()? openDb, RecordingOpener? opener}) =>
    DriveApp(services: testServices(store: store, openDb: openDb, opener: opener));

Future<void> openAccounts(WidgetTester t) async {
  await t.tap(find.text('Accounts'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('lists folders first, opens a folder, offers up-navigation', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('readme.md'), findsOneWidget);
    await t.tap(find.text('Documents'));
    await t.pumpAndSettle();
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.byTooltip('Up one folder'), findsOneWidget);
  });

  testWidgets('trash asks for confirmation and offers undo', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Move readme.md to trash'));
    await t.pumpAndSettle();
    expect(find.text('Move to trash'), findsOneWidget);
    await t.tap(find.text('Move to trash'));
    await t.pumpAndSettle();
    expect(find.text('readme.md'), findsNothing);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(find.text('readme.md'), findsOneWidget);
  });

  testWidgets('settings: provider status never shows unverified as supported; storage problem is explained', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    expect(find.text('unverified'), findsWidgets);
    expect(find.text('full'), findsNothing);
    expect(find.textContaining('disabled in tests'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('transfers and search show honest empty/unavailable states', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Transfers'));
    await t.pumpAndSettle();
    expect(find.text('No transfers yet.'), findsOneWidget);
    await t.tap(find.text('Search'));
    await t.pumpAndSettle();
    expect(find.textContaining('encrypted local database'), findsOneWidget);
  });

  testWidgets('experimental providers are hidden until switched on', (t) async {
    await t.pumpWidget(app());
    await openAccounts(t);
    await t.tap(find.text('Add account'));
    await t.pumpAndSettle();
    expect(find.text('WebDAV / Nextcloud'), findsOneWidget);
    expect(find.text('Dropbox (experimental)'), findsNothing);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('experimental')));
    await t.pumpAndSettle();
    await openAccounts(t);
    await t.tap(find.text('Add account'));
    await t.pumpAndSettle();
    expect(find.text('Dropbox (experimental)'), findsOneWidget);
    expect(find.text('OneDrive (experimental)'), findsOneWidget);
    await t.tap(find.text('Dropbox (experimental)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sign in with browser'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error')), findsOneWidget);
  });

  testWidgets('add-account form rejects empty input and insecure http', (t) async {
    await t.pumpWidget(app());
    await openAccounts(t);
    await t.tap(find.text('Add account'));
    await t.pumpAndSettle();
    await t.tap(find.text('WebDAV / Nextcloud'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error')), findsOneWidget);
    await t.enterText(find.byKey(const Key('label')), 'X');
    await t.enterText(find.byKey(const Key('url')), 'http://cloud.example/dav/');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.textContaining('https'), findsWidgets);
  });

  testWidgets('saved account is listed; the password lives only in the secure store', (t) async {
    final store = SeededStore.drive();
    await t.pumpWidget(app(store: store));
    await openAccounts(t);
    await t.tap(find.text('Add account'));
    await t.pumpAndSettle();
    await t.tap(find.text('WebDAV / Nextcloud'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('label')), 'Home NAS');
    await t.enterText(find.byKey(const Key('url')), 'https://nas.example/remote.php/dav/files/me/');
    await t.enterText(find.byKey(const Key('user')), 'me');
    await t.enterText(find.byKey(const Key('password')), 's3cret');
    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Home NAS'), findsOneWidget);
    expect(find.textContaining('s3cret'), findsNothing);
    final vault = AccountVault(store, 'aethryon.drive');
    final recs = await vault.list();
    expect(recs.single.settings.containsKey('password'), isFalse);
    expect(await vault.secret(recs.single.id), 's3cret');
    expect(await AccountVault(store, 'aethryon.mail').list(), isEmpty);
    expect(find.byTooltip('Run self-test for Home NAS'), findsOneWidget);
  });

  testWidgets('accessibility: tap targets and labels (Files screen)', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('welcome: shown on first launch only, closed by Get Started, stays closed after a restart', (t) async {
    final store = SeededStore.drive(welcomeDone: false);
    await t.pumpWidget(app(store: store));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Thank You for Choosing Our App'), findsOneWidget);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    await t.tap(find.text('Get Started'));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsNothing);
    expect(find.text('Documents'), findsOneWidget); // normal home screen, fully usable
    await t.pumpWidget(const SizedBox()); // "restart the app" with the same storage
    await t.pumpWidget(app(store: store));
    await t.pumpAndSettle();
    expect(find.text('Welcome!'), findsNothing);
    expect(jsonDecode(store.m['aethryon.drive.settings']!)['welcomeDone'], true);
  });

  testWidgets('welcome completion does not erase other saved preferences (and vice versa)', (t) async {
    final store = SeededStore({'aethryon.drive.settings': jsonEncode({'experimental': true})});
    await t.pumpWidget(app(store: store));
    await t.pumpAndSettle();
    await t.tap(find.text('Get Started'));
    await t.pumpAndSettle();
    final saved = jsonDecode(store.m['aethryon.drive.settings']!) as Map<String, dynamic>;
    expect(saved['welcomeDone'], true);
    expect(saved['experimental'], true);
  });

  testWidgets('about: credits and dynamic version; both actions open the configured urls', (t) async {
    final o = RecordingOpener();
    await t.pumpWidget(app(opener: o));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.text('About'));
    await t.pumpAndSettle();
    expect(find.text('DEVELOPED BY'), findsOneWidget);
    expect(find.text('Aethryon Labs'), findsWidgets);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('Md. Shakil Hossain'), findsOneWidget);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    await t.tap(find.byKey(const Key('about_get_in_touch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('about_support')));
    await t.pumpAndSettle();
    expect(o.opened.map((u) => u.toString()), [defaultLinks.getInTouchUrl, defaultLinks.supportUrl]);
  });

  testWidgets('the separate Support button (Files toolbar) opens the same support url and does not overlap the title', (t) async {
    final o = RecordingOpener();
    await t.pumpWidget(app(opener: o));
    await t.pumpAndSettle();
    final support = t.getRect(find.byKey(const Key('support_button')));
    final title = t.getRect(find.text('Aethryon Drive'));
    final bar = t.getRect(find.byType(AppBar));
    expect(support.overlaps(title), isFalse);
    expect(bar.contains(support.topLeft) && bar.contains(support.bottomRight), isTrue);
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
    expect(find.byKey(const Key('category')), findsOneWidget);
  });
}
