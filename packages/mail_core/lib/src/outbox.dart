import 'dart:math' as math;
import 'package:aethryon_net/aethryon_net.dart';

enum OutboxState { pending, sending, sent, failedRetryable, failedPermanent }

class OutboxItem {
  final String id;
  final String accountId;
  final OutboxState state;
  final int attempts;
  final DateTime? nextAttemptUtc;
  const OutboxItem({
    required this.id,
    required this.accountId,
    this.state = OutboxState.pending,
    this.attempts = 0,
    this.nextAttemptUtc,
  });

  OutboxItem copyWith({OutboxState? state, int? attempts, DateTime? nextAttemptUtc}) =>
      OutboxItem(
        id: id,
        accountId: accountId,
        state: state ?? this.state,
        attempts: attempts ?? this.attempts,
        nextAttemptUtc: nextAttemptUtc ?? this.nextAttemptUtc,
      );
}

/// Items due for sending now. A `sending` item is never re-picked (prevents
/// duplicate sends after a crash only if the caller resets stale `sending`
/// items explicitly — see [recoverStaleSending]).
List<OutboxItem> dueItems(List<OutboxItem> items, DateTime nowUtc) => items
    .where((i) =>
        (i.state == OutboxState.pending || i.state == OutboxState.failedRetryable) &&
        (i.nextAttemptUtc == null || !i.nextAttemptUtc!.isAfter(nowUtc)))
    .toList();

OutboxItem onSendFailure(
  OutboxItem item,
  FailureKind kind,
  DateTime nowUtc, {
  RetryPolicy policy = const RetryPolicy(maxAttempts: 6),
  math.Random? random,
}) {
  final attempts = item.attempts + 1;
  if (kind == FailureKind.permanent || kind == FailureKind.auth || attempts >= policy.maxAttempts) {
    return item.copyWith(state: OutboxState.failedPermanent, attempts: attempts);
  }
  final d = policy.delayFor(attempts, random: random ?? math.Random());
  return item.copyWith(
      state: OutboxState.failedRetryable, attempts: attempts, nextAttemptUtc: nowUtc.add(d));
}

/// After an app crash an item may be stuck in `sending`. We DO NOT auto-resend
/// (a duplicate e-mail is worse than a delayed one): surface it as retryable
/// only after the user confirms. This helper just lists them.
List<OutboxItem> recoverStaleSending(List<OutboxItem> items) =>
    items.where((i) => i.state == OutboxState.sending).toList();
