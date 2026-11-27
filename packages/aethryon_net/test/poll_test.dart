import 'dart:async';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:test/test.dart';

class FakeTimer implements Timer {
  final Duration d;
  final void Function() cb;
  bool cancelled = false;
  FakeTimer(this.d, this.cb);
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  test('schedules at the interval; failures back off; success resets', () async {
    final timers = <FakeTimer>[];
    var fail = true;
    final p = PollScheduler(
      interval: const Duration(minutes: 5),
      task: () async {
        if (fail) throw StateError('x');
      },
      timerFactory: (d, cb) {
        final t = FakeTimer(d, cb);
        timers.add(t);
        return t;
      },
    );
    p.start();
    expect(timers.last.d, const Duration(minutes: 5));
    timers.last.cb();
    await Future<void>.delayed(Duration.zero);
    expect(p.failures, 1);
    expect(timers.last.d, const Duration(minutes: 10));
    timers.last.cb();
    await Future<void>.delayed(Duration.zero);
    expect(timers.last.d, const Duration(minutes: 20));
    fail = false;
    timers.last.cb();
    await Future<void>.delayed(Duration.zero);
    expect(p.failures, 0);
    expect(timers.last.d, const Duration(minutes: 5));
  });

  test('backoff is capped; stop cancels and prevents further runs', () async {
    var runs = 0;
    final timers = <FakeTimer>[];
    final p = PollScheduler(
      interval: const Duration(minutes: 30),
      maxBackoff: const Duration(hours: 1),
      task: () async {
        runs++;
        throw StateError('x');
      },
      timerFactory: (d, cb) {
        final t = FakeTimer(d, cb);
        timers.add(t);
        return t;
      },
    );
    p.start();
    for (var i = 0; i < 5; i++) {
      timers.last.cb();
      await Future<void>.delayed(Duration.zero);
    }
    expect(timers.last.d, const Duration(hours: 1));
    p.stop();
    expect(timers.last.cancelled, isTrue);
    final before = runs;
    timers.last.cb();
    await Future<void>.delayed(Duration.zero);
    expect(runs, before);
    expect(p.running, isFalse);
  });

  test('overlapping runs are skipped', () async {
    var runs = 0;
    final gate = Completer<void>();
    final p = PollScheduler(
      interval: const Duration(minutes: 1),
      task: () async {
        runs++;
        await gate.future;
      },
      timerFactory: (d, cb) => FakeTimer(d, cb),
    )..start();
    final a = p.triggerNow();
    final b = p.triggerNow();
    gate.complete();
    await Future.wait([a, b]);
    expect(runs, 1);
  });
}
