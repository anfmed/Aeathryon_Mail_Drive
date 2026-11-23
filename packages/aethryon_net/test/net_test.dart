import 'dart:math';

import 'package:aethryon_net/aethryon_net.dart';
import 'package:test/test.dart';

void main() {
  test('classify', () {
    expect(classifyStatus(429), FailureKind.throttled);
    expect(classifyStatus(401), FailureKind.auth);
    expect(classifyStatus(503), FailureKind.transient);
    expect(classifyStatus(404), FailureKind.permanent);
    expect(classifyStatus(403), FailureKind.permanent);
  });
  test('Retry-After seconds', () {
    expect(parseRetryAfter('7'), const Duration(seconds: 7));
    expect(parseRetryAfter('Wed, 21 Oct 2026 07:28:00 GMT'), isNull);
    expect(parseRetryAfter(null), isNull);
  });
  test('delay bounded by maxDelay and honours Retry-After', () {
    const p = RetryPolicy(maxDelay: Duration(seconds: 10));
    final r = Random(1);
    for (var a = 1; a < 30; a++) {
      expect(p.delayFor(a, random: r) <= const Duration(seconds: 10), isTrue);
    }
    expect(
      p.delayFor(1, random: r, retryAfter: const Duration(seconds: 99)),
      const Duration(seconds: 10),
    );
  });
  test('retry succeeds after transient failures', () async {
    var calls = 0;
    final v = await retry<int>(
      policy: const RetryPolicy(maxAttempts: 4),
      op: () async {
        calls++;
        if (calls < 3) throw StateError('x');
        return 42;
      },
      classify: (_) => FailureKind.transient,
      sleep: (_) async {},
    );
    expect(v, 42);
    expect(calls, 3);
  });
  test('retry stops on permanent', () async {
    var calls = 0;
    await expectLater(
      retry<int>(
        policy: const RetryPolicy(),
        op: () async {
          calls++;
          throw StateError('x');
        },
        classify: (_) => FailureKind.permanent,
        sleep: (_) async {},
      ),
      throwsStateError,
    );
    expect(calls, 1);
  });
  test('token bucket reserves', () {
    var t = DateTime.utc(2026);
    final b = TokenBucket(capacity: 2, refillPerSecond: 1, now: () => t);
    expect(b.acquire(), Duration.zero);
    expect(b.acquire(), Duration.zero);
    expect(b.acquire(), const Duration(seconds: 1));
    t = t.add(const Duration(seconds: 3));
    expect(b.acquire(), Duration.zero);
  });
}
