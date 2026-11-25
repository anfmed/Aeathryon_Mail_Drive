import 'dart:math';

import 'package:aethryon_net/aethryon_net.dart';
import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);
  test('transient failure schedules retry in the future', () {
    final r = onSendFailure(
      const OutboxItem(id: '1', accountId: 'a'),
      FailureKind.transient,
      now,
      random: Random(1),
    );
    expect(r.state, OutboxState.failedRetryable);
    expect(r.nextAttemptUtc!.isAfter(now), isTrue);
    expect(dueItems([r], now), isEmpty);
    expect(dueItems([r], r.nextAttemptUtc!), hasLength(1));
  });
  test('permanent/auth failure is terminal', () {
    expect(
      onSendFailure(
        const OutboxItem(id: '1', accountId: 'a'),
        FailureKind.permanent,
        now,
      ).state,
      OutboxState.failedPermanent,
    );
    expect(
      onSendFailure(
        const OutboxItem(id: '1', accountId: 'a'),
        FailureKind.auth,
        now,
      ).state,
      OutboxState.failedPermanent,
    );
  });
  test('attempt cap makes failure terminal', () {
    var it = const OutboxItem(id: '1', accountId: 'a');
    for (var i = 0; i < 6; i++) {
      it = onSendFailure(it, FailureKind.transient, now, random: Random(i));
    }
    expect(it.state, OutboxState.failedPermanent);
  });
  test('sending items are never auto-picked (no duplicate sends)', () {
    const it = OutboxItem(id: '1', accountId: 'a', state: OutboxState.sending);
    expect(dueItems([it], now), isEmpty);
    expect(recoverStaleSending([it]), hasLength(1));
  });
}
