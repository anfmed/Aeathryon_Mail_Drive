import 'dart:async';
import 'dart:math' as math;

enum FailureKind { transient, throttled, auth, permanent }

/// 403 is deliberately `permanent`: providers overload it (quota vs. forbidden),
/// so adapters may reclassify with provider-specific knowledge.
FailureKind classifyStatus(int code) {
  if (code == 429) return FailureKind.throttled;
  if (code == 401) return FailureKind.auth;
  if (code == 408 || code == 500 || code == 502 || code == 503 || code == 504) {
    return FailureKind.transient;
  }
  return FailureKind.permanent;
}

/// Parses delta-seconds form of Retry-After only. HTTP-date form -> null.
Duration? parseRetryAfter(String? value) {
  if (value == null) return null;
  final s = int.tryParse(value.trim());
  if (s == null || s < 0) return null;
  return Duration(seconds: s);
}

class RetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  const RetryPolicy({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 60),
  });

  /// attempt is 1-based (delay applied after attempt N failed). Equal jitter.
  Duration delayFor(
    int attempt, {
    required math.Random random,
    Duration? retryAfter,
  }) {
    if (retryAfter != null)
      return retryAfter > maxDelay ? maxDelay : retryAfter;
    final shift = math.min(math.max(attempt - 1, 0), 20);
    final exp = baseDelay.inMilliseconds * (1 << shift);
    final capped = math.min(exp, maxDelay.inMilliseconds);
    final jittered = (capped * (0.5 + random.nextDouble() / 2)).round();
    return Duration(milliseconds: jittered);
  }
}

class RetryExhausted implements Exception {
  final Object lastError;
  final int attempts;
  RetryExhausted(this.lastError, this.attempts);
  @override
  String toString() => 'RetryExhausted(attempts: $attempts, last: $lastError)';
}

Future<T> retry<T>({
  required RetryPolicy policy,
  required Future<T> Function() op,
  required FailureKind Function(Object error) classify,
  Duration? Function(Object error)? retryAfterOf,
  Future<void> Function(Duration d)? sleep,
  math.Random? random,
}) async {
  final rnd = random ?? math.Random();
  final doSleep = sleep ?? (Duration d) => Future<void>.delayed(d);
  for (var attempt = 1; ; attempt++) {
    try {
      return await op();
    } catch (e) {
      final kind = classify(e);
      if (kind == FailureKind.permanent || kind == FailureKind.auth) rethrow;
      if (attempt >= policy.maxAttempts) throw RetryExhausted(e, attempt);
      await doSleep(
        policy.delayFor(
          attempt,
          random: rnd,
          retryAfter: retryAfterOf?.call(e),
        ),
      );
    }
  }
}

/// Reservation-style token bucket. `acquire` returns how long the caller must
/// wait before proceeding; tokens may go negative (queued reservations).
class TokenBucket {
  final double capacity;
  final double refillPerSecond;
  final DateTime Function() _now;
  double _tokens;
  DateTime _last;

  TokenBucket({
    required this.capacity,
    required this.refillPerSecond,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _tokens = capacity,
       _last = (now ?? DateTime.now)();

  Duration acquire([double cost = 1]) {
    final t = _now();
    final dt = t.difference(_last).inMicroseconds / 1e6;
    _last = t;
    _tokens = math.min(capacity, _tokens + dt * refillPerSecond);
    _tokens -= cost;
    if (_tokens >= 0) return Duration.zero;
    return Duration(microseconds: ((-_tokens / refillPerSecond) * 1e6).ceil());
  }
}

typedef TimerFactory = Timer Function(Duration d, void Function() cb);

/// Foreground polling (no background service: lightweight by design). Doubles the
/// delay after each failure (max [maxBackoff]) and resets after a success.
class PollScheduler {
  final Duration interval;
  final Duration maxBackoff;
  final Future<void> Function() task;
  final TimerFactory _timer;
  Timer? _t;
  int _failures = 0;
  bool _running = false;
  bool _inFlight = false;

  PollScheduler({
    required this.interval,
    required this.task,
    this.maxBackoff = const Duration(hours: 1),
    TimerFactory? timerFactory,
  }) : _timer = timerFactory ?? ((d, cb) => Timer(d, cb));

  bool get running => _running;
  int get failures => _failures;

  Duration get nextDelay {
    final shift = math.min(_failures, 10);
    final d = interval * (1 << shift);
    return d > maxBackoff ? maxBackoff : d;
  }

  void start() {
    if (_running) return;
    _running = true;
    _schedule();
  }

  void stop() {
    _running = false;
    _t?.cancel();
    _t = null;
  }

  void _schedule() {
    _t?.cancel();
    if (!_running) return;
    _t = _timer(nextDelay, _tick);
  }

  Future<void> _tick() async {
    if (!_running || _inFlight) return;
    _inFlight = true;
    try {
      await task();
      _failures = 0;
    } catch (_) {
      _failures++;
    } finally {
      _inFlight = false;
      _schedule();
    }
  }

  /// Run now (e.g. user pulled to refresh) without waiting for the timer.
  Future<void> triggerNow() => _tick();
}
