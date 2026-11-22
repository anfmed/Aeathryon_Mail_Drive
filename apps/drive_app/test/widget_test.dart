import 'package:drive_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists folders first, opens a folder, shows empty/up navigation', (t) async {
    await t.pumpWidget(const DriveApp());
    await t.pumpAndSettle();
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('readme.md'), findsOneWidget);
    await t.tap(find.text('Documents'));
    await t.pumpAndSettle();
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.byTooltip('Up one folder'), findsOneWidget);
  });

  testWidgets('trash asks for confirmation and offers undo', (t) async {
    await t.pumpWidget(const DriveApp());
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

  testWidgets('providers screen never shows unverified as supported', (t) async {
    await t.pumpWidget(const DriveApp());
    await t.tap(find.text('Providers'));
    await t.pumpAndSettle();
    expect(find.text('unverified'), findsWidgets);
    expect(find.text('full'), findsNothing);
  });
}
