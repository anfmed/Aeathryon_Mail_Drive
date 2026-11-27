import 'dart:io';

import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

class FakePicked implements PickedFile {
  @override
  final String name;
  final List<int> bytes;
  FakePicked(this.name, this.bytes);
  @override
  Future<int> length() async => bytes.length;
  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      Stream.value(bytes.sublist(start ?? 0, end ?? bytes.length));
}

class FakeFiles implements FilePlatform {
  final Directory dir;
  final PickedFile? picked;
  FakeFiles(this.dir, [this.picked]);
  @override
  Future<PickedFile?> pickFile() async => picked;
  @override
  Future<String> appDataDir() async => dir.path;
  @override
  Future<String> downloadsDir() async => dir.path;
}

class BrokenAdapter extends MemoryStorageAdapter {
  @override
  Stream<List<int>> download(
    String accountId,
    String id, {
    int? start,
    int? endInclusive,
  }) async* {
    yield [1, 2];
    throw StateError('network died');
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('aeth_tc_'));
  tearDown(() => dir.deleteSync(recursive: true));
  String ex(Object e) => 'failed: ${e.runtimeType}';

  test(
    'download writes a uniquely named file inside the downloads folder',
    () async {
      final a = MemoryStorageAdapter()
        ..seedFile('x', '/Docs/../evil.txt'.replaceAll('/../', '/'), [1, 2, 3]);
      final c = TransferController(FakeFiles(dir), explain: ex);
      final node = RemoteNode(
        accountId: 'x',
        id: '/Docs/evil.txt',
        name: '../../evil.txt',
        isFolder: false,
        size: 3,
      );
      final item = await c.download(a, node);
      expect(item.status, TransferStatus.done);
      expect(File(item.localPath!).readAsBytesSync(), [1, 2, 3]);
      expect(
        File(item.localPath!).parent.path,
        dir.path,
      ); // traversal neutralised
      final second = await c.download(a, node);
      expect(second.localPath, isNot(item.localPath));
    },
  );

  test('failed download leaves no partial file and a readable error', () async {
    final a = BrokenAdapter();
    final c = TransferController(FakeFiles(dir), explain: ex);
    final item = await c.download(
      a,
      const RemoteNode(
        accountId: 'x',
        id: '/f',
        name: 'f.bin',
        isFolder: false,
        size: 9,
      ),
    );
    expect(item.status, TransferStatus.failed);
    expect(item.error, 'failed: StateError');
    expect(dir.listSync(), isEmpty);
  });

  test('cancel before start removes the partial file', () async {
    final a = MemoryStorageAdapter()
      ..seedFile('x', '/f.bin', List.filled(10, 1));
    final c = TransferController(FakeFiles(dir), explain: ex);
    final fut = c.download(
      a,
      const RemoteNode(
        accountId: 'x',
        id: '/f.bin',
        name: 'f.bin',
        isFolder: false,
        size: 10,
      ),
    );
    c.cancel(c.items.first);
    final item = await fut;
    expect(item.status, TransferStatus.cancelled);
    expect(dir.listSync(), isEmpty);
  });

  test('unknown size (null) still downloads', () async {
    final a = MemoryStorageAdapter()..seedFile('x', '/f.bin', [1, 2]);
    final c = TransferController(FakeFiles(dir), explain: ex);
    final item = await c.download(
      a,
      const RemoteNode(
        accountId: 'x',
        id: '/f.bin',
        name: 'f.bin',
        isFolder: false,
      ),
    );
    expect(item.status, TransferStatus.done);
  });

  test(
    'small upload goes through the adapter; progress reaches 100%',
    () async {
      final a = MemoryStorageAdapter();
      final c = TransferController(FakeFiles(dir), explain: ex);
      final item = await c.upload(a, 'x', '/', FakePicked('up.bin', [5, 6, 7]));
      expect(item.status, TransferStatus.done);
      expect(item.done, 3);
      expect((await a.listChildren('x', '/')).items.single.name, 'up.bin');
    },
  );

  test(
    'upload errors are reported, clearFinished keeps running items',
    () async {
      final a = _Failing();
      final c = TransferController(FakeFiles(dir), explain: ex);
      final item = await c.upload(a, 'x', '/', FakePicked('up.bin', [1]));
      expect(item.status, TransferStatus.failed);
      expect(item.error, 'failed: ProviderHttpError');
      c.clearFinished();
      expect(c.items, isEmpty);
    },
  );

  test('changes stream notifies listeners', () async {
    final c = TransferController(FakeFiles(dir), explain: ex);
    var n = 0;
    final sub = c.changes.listen((_) => n++);
    await c.upload(MemoryStorageAdapter(), 'x', '/', FakePicked('a', [1]));
    await Future<void>.delayed(Duration.zero);
    expect(n, greaterThan(0));
    await sub.cancel();
    await c.dispose();
  });
}

class _Failing extends MemoryStorageAdapter {
  @override
  Future<RemoteNode> upload(
    String accountId,
    String parentId,
    String name,
    Stream<List<int>> data,
    int length,
  ) => throw ProviderHttpError(507, 'full');
}
