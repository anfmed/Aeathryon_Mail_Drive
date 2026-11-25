import 'adapter.dart';
import 'chunk_planner.dart';
import 'models.dart';
import 'transfer.dart';

abstract class ResumableSession {
  String get ref; // provider session reference (persist for resume - Phase 8)
  Future<int> confirmedOffset();
  Future<void> putChunk(ChunkRange range, List<int> bytes, {required int total});
  Future<RemoteNode> finish();
}

abstract class ResumableUploader {
  ChunkConstraint get constraint;
  Future<ResumableSession> begin(String accountId, String parentId, String name, int totalBytes);
}

abstract class LocalSink {
  Future<int> length();
  Future<void> truncate();
  Future<void> append(List<int> bytes);
}

abstract class LocalSource {
  Future<int> length();
  Future<List<int>> read(int start, int endInclusive);
}

class MemorySink implements LocalSink {
  final List<int> data;
  MemorySink([List<int>? initial]) : data = List.of(initial ?? const []);
  @override
  Future<int> length() async => data.length;
  @override
  Future<void> truncate() async => data.clear();
  @override
  Future<void> append(List<int> bytes) async => data.addAll(bytes);
}

class MemorySource implements LocalSource {
  final List<int> data;
  MemorySource(this.data);
  @override
  Future<int> length() async => data.length;
  @override
  Future<List<int>> read(int start, int endInclusive) async => data.sublist(start, endInclusive + 1);
}

class TransferCancelled implements Exception {
  @override
  String toString() => 'TransferCancelled';
}

class TransferRunner {
  /// Resumes a download at the job's confirmed offset when the partial file
  /// matches it AND the adapter supports ranges; otherwise restarts from zero
  /// (never appends to a file whose length does not match the offset).
  Future<int> download({
    required StorageAdapter adapter,
    required TransferJob job,
    required LocalSink sink,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    var offset = job.transferredBytes;
    final have = await sink.length();
    final canRange = adapter.capability(DriveFeature.rangeDownload).enabledInUi;
    if (offset > 0 && (have != offset || !canRange)) {
      await sink.truncate();
      offset = 0;
    } else if (offset == 0 && have > 0) {
      await sink.truncate();
    }
    var written = offset;
    await for (final chunk in adapter.download(job.accountId, job.remoteId, start: offset > 0 ? offset : null)) {
      if (isCancelled?.call() == true) throw TransferCancelled();
      await sink.append(chunk);
      written += chunk.length;
      onProgress?.call(written, job.totalBytes);
    }
    if (job.totalBytes >= 0 && written != job.totalBytes) {
      throw StateError('download size mismatch: $written of ${job.totalBytes}');
    }
    return written;
  }

  Future<RemoteNode> upload({
    required ResumableUploader uploader,
    required LocalSource source,
    required String accountId,
    required String parentId,
    required String name,
    int preferredChunk = 4 * 1024 * 1024,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final total = await source.length();
    final session = await uploader.begin(accountId, parentId, name, total);
    final start = await session.confirmedOffset();
    final plan = planChunks(
        totalBytes: total, preferred: preferredChunk, constraint: uploader.constraint, startOffset: start);
    for (final r in plan) {
      if (isCancelled?.call() == true) throw TransferCancelled();
      final bytes = await source.read(r.start, r.endInclusive);
      await session.putChunk(r, bytes, total: total);
      onProgress?.call(r.endInclusive + 1, total);
    }
    return session.finish();
  }
}
