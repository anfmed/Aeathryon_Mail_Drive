import 'package:aethryon_platform/aethryon_platform.dart';

enum TransferKind { upload, download }

enum TransferState {
  queued,
  running,
  paused,
  waitingForNetwork,
  failed,
  completed,
  cancelled,
}

class TransferJob {
  final String id;
  final String accountId;
  final TransferKind kind;
  final String remoteId;
  final String localPath;
  final int totalBytes;
  final int transferredBytes; // provider-confirmed offset (resume point)
  final TransferState state;
  final int attempts;
  const TransferJob({
    required this.id,
    required this.accountId,
    required this.kind,
    required this.remoteId,
    required this.localPath,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.state = TransferState.queued,
    this.attempts = 0,
  });

  TransferJob copyWith({
    TransferState? state,
    int? transferredBytes,
    int? attempts,
  }) => TransferJob(
    id: id,
    accountId: accountId,
    kind: kind,
    remoteId: remoteId,
    localPath: localPath,
    totalBytes: totalBytes,
    transferredBytes: transferredBytes ?? this.transferredBytes,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
  );

  bool get isTerminal =>
      state == TransferState.completed ||
      state == TransferState.cancelled ||
      state == TransferState.failed;
}

class TransferPolicy {
  final bool wifiOnly;
  final bool allowMetered;
  final int minBatteryPercent; // ignored while charging
  final bool pauseOnBatterySaver;
  const TransferPolicy({
    this.wifiOnly = false,
    this.allowMetered = true,
    this.minBatteryPercent = 0,
    this.pauseOnBatterySaver = false,
  });
}

bool policyAllows(TransferPolicy p, NetworkState n, PowerState w) {
  if (!n.online) return false;
  if (p.wifiOnly && !n.wifi) return false;
  if (!p.allowMetered && n.metered) return false;
  if (p.pauseOnBatterySaver && w.batterySaver && !w.charging) return false;
  if (!w.charging && w.batteryPercent < p.minBatteryPercent) return false;
  return true;
}

/// Pure scheduling decision: which jobs may start now. Account isolation:
/// per-account cap + round-robin so one account cannot starve the others.
List<TransferJob> pickRunnable(
  List<TransferJob> jobs, {
  required int maxConcurrent,
  required int maxPerAccount,
  required TransferPolicy policy,
  required NetworkState network,
  required PowerState power,
}) {
  if (!policyAllows(policy, network, power)) return const [];
  final running = jobs.where((j) => j.state == TransferState.running).toList();
  var slots = maxConcurrent - running.length;
  if (slots <= 0) return const [];

  final perAccount = <String, int>{};
  for (final j in running) {
    perAccount[j.accountId] = (perAccount[j.accountId] ?? 0) + 1;
  }
  final waiting = jobs
      .where(
        (j) =>
            j.state == TransferState.queued ||
            j.state == TransferState.waitingForNetwork,
      )
      .toList();

  final byAccount = <String, List<TransferJob>>{};
  for (final j in waiting) {
    byAccount.putIfAbsent(j.accountId, () => []).add(j);
  }
  final order = byAccount.keys.toList();
  final picked = <TransferJob>[];
  var progress = true;
  while (slots > 0 && progress) {
    progress = false;
    for (final acc in order) {
      if (slots == 0) break;
      final q = byAccount[acc]!;
      if (q.isEmpty) continue;
      if ((perAccount[acc] ?? 0) >= maxPerAccount) continue;
      picked.add(q.removeAt(0));
      perAccount[acc] = (perAccount[acc] ?? 0) + 1;
      slots--;
      progress = true;
    }
  }
  return picked;
}
