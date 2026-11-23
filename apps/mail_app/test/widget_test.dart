import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mail_app/main.dart';

Widget app([MemorySecureStore? s]) => MailApp(secureStore: s ?? MemorySecureStore());

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

  testWidgets('message view shows plain text only (scripts/images dropped)', (t) async {
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

  testWidgets('Proton is shown as requiring a companion', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Providers'));
    await t.pumpAndSettle();
    expect(find.text('requiresCompanion'), findsOneWidget);
  });

  testWidgets('Proton cannot be added on a phone (default test platform = Android)', (t) async {
    await t.pumpWidget(app());
    await openAddAccount(t);
    await choose(t, 'Proton Mail (via Bridge)');
    expect(find.byKey(const Key('blocked')), findsOneWidget);
    expect(find.textContaining('desktop companion'), findsOneWidget);
  });

  testWidgets('Gmail is blocked with an honest OAuth explanation', (t) async {
    await t.pumpWidget(app());
    await openAddAccount(t);
    await choose(t, 'Gmail');
    expect(find.textContaining('OAuth'), findsOneWidget);
  });

  testWidgets('Proton on desktop: still blocked (Bridge not implemented)', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await t.pumpWidget(app());
      await openAddAccount(t);
      await choose(t, 'Proton Mail (via Bridge)');
      expect(find.textContaining('not implemented'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iCloud prefills verified servers; account saved, password only in secure store', (t) async {
    final store = MemorySecureStore();
    await t.pumpWidget(app(store));
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
    expect(await vault.secret(r.id), 'abcd-efgh');
    expect(await AccountVault(store, 'aethryon.drive').list(), isEmpty);
  });
}
