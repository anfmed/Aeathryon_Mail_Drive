import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

class FakeSession implements ResumableSession {
  final List<ChunkRange> chunks = [];
  final List<List<int>> payload = [];
  bool finished = false;
  final int start;
  FakeSession(this.start);
  @override
  String get ref => 'fake';
  @override
  Future<int> confirmedOffset() async => start;
  @override
  Future<void> putChunk(ChunkRange range, List<int> bytes, {required int total}) async {
    chunks.add(range);
    payload.add(bytes);
  }

  @override
  Future<RemoteNode> finish() async {
    finished = true;
    return const RemoteNode(accountId: 'a', id: '/f', name: 'f', isFolder: false);
  }
}

class FakeUploader implements ResumableUploader {
  final FakeSession session;
  FakeUploader(this.session);
  @override
  ChunkConstraint get constraint => const ChunkConstraint(maxChunk: 4);
  @override
  Future<ResumableSession> begin(String a, String p, String n, int t) async => session;
}

TransferJob job({int done = 0, int total = 6}) => TransferJob(
    id: 'j', accountId: 'x', kind: TransferKind.download, remoteId: '/f.bin', localPath: '/t', totalBytes: total, transferredBytes: done);

MemoryStorageAdapter source() => MemoryStorageAdapter()..seedFile('x', '/f.bin', [1, 2, 3, 4, 5, 6]);

void main() {
  test('download from scratch', () async {
    final sink = MemorySink();
    expect(await TransferRunner().download(adapter: source(), job: job(), sink: sink), 6);
    expect(sink.data, [1, 2, 3, 4, 5, 6]);
  });

  test('download resumes at the confirmed offset when the partial file matches', () async {
    final sink = MemorySink([1, 2, 3]);
    await TransferRunner().download(adapter: source(), job: job(done: 3), sink: sink);
    expect(sink.data, [1, 2, 3, 4, 5, 6]);
  });

  test('mismatched partial file is discarded, not appended to', () async {
    final sink = MemorySink([9, 9]); // job says 3 bytes done, file has 2
    await TransferRunner().download(adapter: source(), job: job(done: 3), sink: sink);
    expect(sink.data, [1, 2, 3, 4, 5, 6]);
  });

  test('stale partial file with offset 0 is truncated', () async {
    final sink = MemorySink([7, 7, 7]);
    await TransferRunner().download(adapter: source(), job: job(), sink: sink);
    expect(sink.data, [1, 2, 3, 4, 5, 6]);
  });

  test('size mismatch is an error, cancellation stops the transfer', () async {
    await expectLater(
        TransferRunner().download(adapter: source(), job: job(total: 99), sink: MemorySink()), throwsStateError);
    await expectLater(
        TransferRunner().download(adapter: source(), job: job(), sink: MemorySink(), isCancelled: () => true),
        throwsA(isA<TransferCancelled>()));
  });

  test('resumable upload covers every byte exactly once, then finishes', () async {
    final s = FakeSession(0);
    final src = MemorySource(List.generate(10, (i) => i));
    final seen = <int>[];
    final node = await TransferRunner().upload(
        uploader: FakeUploader(s), source: src, accountId: 'a', parentId: '/', name: 'f',
        preferredChunk: 4, onProgress: (d, t) => seen.add(d));
    expect(s.chunks, [const ChunkRange(0, 3), const ChunkRange(4, 7), const ChunkRange(8, 9)]);
    expect([for (final p in s.payload) ...p], List.generate(10, (i) => i));
    expect(seen, [4, 8, 10]);
    expect(s.finished, isTrue);
    expect(node.name, 'f');
  });

  test('upload resumes from the server-confirmed offset', () async {
    final s = FakeSession(4);
    await TransferRunner().upload(
        uploader: FakeUploader(s), source: MemorySource(List.generate(10, (i) => i)),
        accountId: 'a', parentId: '/', name: 'f', preferredChunk: 4);
    expect(s.chunks.first.start, 4);
  });

  test('empty file: no chunks, still finishes', () async {
    final s = FakeSession(0);
    await TransferRunner().upload(
        uploader: FakeUploader(s), source: MemorySource([]), accountId: 'a', parentId: '/', name: 'f');
    expect(s.chunks, isEmpty);
    expect(s.finished, isTrue);
  });

  test('upload cancellation', () async {
    await expectLater(
        TransferRunner().upload(
            uploader: FakeUploader(FakeSession(0)), source: MemorySource([1, 2]),
            accountId: 'a', parentId: '/', name: 'f', isCancelled: () => true),
        throwsA(isA<TransferCancelled>()));
  });
}
