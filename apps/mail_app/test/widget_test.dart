import 'package:flutter_test/flutter_test.dart';
import 'package:mail_app/main.dart';

void main() {
  testWidgets('inbox syncs demo mail and flags the conversation', (t) async {
    await t.pumpWidget(const MailApp());
    await t.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Lunch?'), findsOneWidget);
    expect(find.text('Conversation'), findsNWidgets(2)); // Lunch? + Re: Lunch?
  });

  testWidgets('message view shows plain text only (scripts/images dropped)', (
    t,
  ) async {
    await t.pumpWidget(const MailApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Welcome'));
    await t.pumpAndSettle();
    expect(find.textContaining('Welcome to Aethryon Mail'), findsWidgets);
    expect(find.textContaining('alert'), findsNothing);
    expect(find.textContaining('tracker.example'), findsNothing);
  });

  testWidgets('compose rejects empty recipient', (t) async {
    await t.pumpWidget(const MailApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Compose'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    expect(find.text('Add at least one valid recipient.'), findsOneWidget);
  });

  testWidgets('Proton is shown as requiring a companion', (t) async {
    await t.pumpWidget(const MailApp());
    await t.tap(find.text('Providers'));
    await t.pumpAndSettle();
    expect(find.text('requiresCompanion'), findsOneWidget);
  });
}
