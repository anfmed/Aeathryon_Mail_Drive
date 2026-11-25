import 'adapter.dart';
import 'models.dart';

class SelfTestStep {
  final String name;
  final bool ok;
  final String detail;
  const SelfTestStep(this.name, this.ok, [this.detail = '']);
}

String _short(Object e) {
  if (e is ProviderHttpError) return 'HTTP ${e.statusCode}';
  if (e is UnsupportedOperation) return 'unsupported';
  return e.runtimeType.toString(); // never the message: it could contain names/URLs
}

/// Safe, self-cleaning check of a REAL account: everything happens inside one
/// uniquely named temporary folder that is deleted at the end. Results contain no
/// secrets or file names - they are meant to be pasted into a bug report.
Future<List<SelfTestStep>> runAdapterSelfTest(StorageAdapter a, String accountId, {String rootId = '/'}) async {
  final steps = <SelfTestStep>[];
  Future<T?> step<T>(String name, Future<T> Function() f, {bool optional = false}) async {
    try {
      final v = await f();
      steps.add(SelfTestStep(name, true));
      return v;
    } catch (e) {
      steps.add(SelfTestStep(name, false, optional ? 'not available (${_short(e)})' : _short(e)));
      return null;
    }
  }

  final folderName = 'aethryon_selftest_${DateTime.now().millisecondsSinceEpoch}';
  final data = List<int>.generate(2048, (i) => i % 251);
  String? folderId;

  folderId = await step<String>('create folder', () async {
    await a.mkdir(accountId, rootId, folderName);
    final l = await a.listChildren(accountId, rootId);
    return l.items.firstWhere((n) => n.name == folderName && n.isFolder).id;
  });

  if (folderId != null) {
    final up = await step<RemoteNode>('upload 2 KB file', () => a.upload(accountId, folderId!, 'a.bin', Stream.value(data), data.length));
    await step<void>('list shows the file with the right size', () async {
      final l = await a.listChildren(accountId, folderId!);
      final f = l.items.firstWhere((n) => n.name == 'a.bin');
      if (f.size != data.length) throw StateError('size mismatch');
    });
    if (up != null) {
      await step<void>('download the whole file', () async {
        final got = await a.download(accountId, up.id).expand((e) => e).toList();
        if (got.length != data.length || !_same(got, data)) throw StateError('content mismatch');
      });
      await step<void>('download a byte range', () async {
        final got = await a.download(accountId, up.id, start: 100, endInclusive: 199).expand((e) => e).toList();
        if (!_same(got, data.sublist(100, 200))) throw StateError('range mismatch');
      }, optional: true);
      await step<void>('rename/move', () async {
        await a.move(accountId, up.id, folderId!, 'b.bin');
        final l = await a.listChildren(accountId, folderId);
        if (!l.items.any((n) => n.name == 'b.bin')) throw StateError('not renamed');
      });
    }
    await step<void>('quota', () async => a.quota(accountId), optional: true);
    await step<void>('clean up (delete the test folder)', () => a.permanentDelete(accountId, folderId!));
  }
  return steps;
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String formatSelfTest(String providerId, List<SelfTestStep> steps) {
  final b = StringBuffer('Aethryon self-test - provider: $providerId\n');
  for (final s in steps) {
    b.writeln('${s.ok ? 'PASS' : 'FAIL'}  ${s.name}${s.detail.isEmpty ? '' : ' - ${s.detail}'}');
  }
  final failed = steps.where((s) => !s.ok && !s.detail.startsWith('not available')).length;
  b.write(failed == 0 ? 'RESULT: all required steps passed' : 'RESULT: $failed required step(s) failed');
  return b.toString();
}
