import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:drive_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app([MemorySecureStore? s]) =>
    DriveApp(secureStore: s ?? MemorySecureStore());

void main() {
  testWidgets('lists folders first, opens a folder, offers up-navigation', (
    t,
  ) async {
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

  testWidgets('providers screen never shows unverified as supported', (
    t,
  ) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Providers'));
    await t.pumpAndSettle();
    expect(find.text('unverified'), findsWidgets);
    expect(find.text('full'), findsNothing);
  });

  testWidgets('add-account form rejects empty input and insecure http', (
    t,
  ) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Accounts'));
    await t.pumpAndSettle();
    await t.tap(find.text('Add account'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error')), findsOneWidget);
    await t.enterText(find.byKey(const Key('label')), 'X');
    await t.enterText(
      find.byKey(const Key('url')),
      'http://cloud.example/dav/',
    );
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.textContaining('https'), findsWidgets);
  });

  testWidgets(
    'saved account is listed; the password lives only in the secure store',
    (t) async {
      final store = MemorySecureStore();
      await t.pumpWidget(app(store));
      await t.tap(find.text('Accounts'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add account'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('label')), 'Home NAS');
      await t.enterText(
        find.byKey(const Key('url')),
        'https://nas.example/remote.php/dav/files/me/',
      );
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
      // the Mail namespace cannot see Drive's account
      expect(await AccountVault(store, 'aethryon.mail').list(), isEmpty);
    },
  );
}
