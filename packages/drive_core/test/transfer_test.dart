import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

TransferJob j(
  String id,
  String acc, {
  TransferState s = TransferState.queued,
}) => TransferJob(
  id: id,
  accountId: acc,
  kind: TransferKind.download,
  remoteId: '/x',
  localPath: '/tmp/x',
  totalBytes: 10,
  state: s,
);

const wifi = NetworkState(online: true, metered: false, wifi: true);
const cell = NetworkState(online: true, metered: true, wifi: false);
const okPower = PowerState(
  batteryPercent: 80,
  charging: false,
  batterySaver: false,
);

void main() {
  test('wifiOnly blocks on cellular', () {
    final r = pickRunnable(
      [j('1', 'a')],
      maxConcurrent: 2,
      maxPerAccount: 2,
      policy: const TransferPolicy(wifiOnly: true),
      network: cell,
      power: okPower,
    );
    expect(r, isEmpty);
  });
  test('offline blocks everything', () {
    final r = pickRunnable(
      [j('1', 'a')],
      maxConcurrent: 2,
      maxPerAccount: 2,
      policy: const TransferPolicy(),
      network: const NetworkState(online: false, metered: false, wifi: false),
      power: okPower,
    );
    expect(r, isEmpty);
  });
  test('round-robin across accounts (isolation)', () {
    final jobs = [j('a1', 'a'), j('a2', 'a'), j('a3', 'a'), j('b1', 'b')];
    final r = pickRunnable(
      jobs,
      maxConcurrent: 2,
      maxPerAccount: 2,
      policy: const TransferPolicy(),
      network: wifi,
      power: okPower,
    );
    expect(r.map((e) => e.id).toSet(), {'a1', 'b1'});
  });
  test('per-account cap respected', () {
    final jobs = [
      j('a1', 'a', s: TransferState.running),
      j('a2', 'a'),
      j('b1', 'b'),
    ];
    final r = pickRunnable(
      jobs,
      maxConcurrent: 3,
      maxPerAccount: 1,
      policy: const TransferPolicy(),
      network: wifi,
      power: okPower,
    );
    expect(r.map((e) => e.id), ['b1']);
  });
  test('low battery blocks unless charging', () {
    const low = PowerState(
      batteryPercent: 10,
      charging: false,
      batterySaver: false,
    );
    const lowCharging = PowerState(
      batteryPercent: 10,
      charging: true,
      batterySaver: false,
    );
    const pol = TransferPolicy(minBatteryPercent: 20);
    expect(
      pickRunnable(
        [j('1', 'a')],
        maxConcurrent: 1,
        maxPerAccount: 1,
        policy: pol,
        network: wifi,
        power: low,
      ),
      isEmpty,
    );
    expect(
      pickRunnable(
        [j('1', 'a')],
        maxConcurrent: 1,
        maxPerAccount: 1,
        policy: pol,
        network: wifi,
        power: lowCharging,
      ),
      hasLength(1),
    );
  });
}
