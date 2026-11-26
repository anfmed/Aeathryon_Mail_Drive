import 'dart:async';
import 'dart:io';

import 'package:aethryon_platform/aethryon_platform.dart';

import 'adapter.dart';
import 'file_io.dart';
import 'models.dart';
import 'resumable.dart';
import 'transfer.dart';

enum TransferStatus { running, done, failed, cancelled }

class TransferItem {
  final int id;
  final String name;
  final bool isUpload;
  int done = 0;
  int total;
  TransferStatus status = TransferStatus.running;
  String? error;
  String? localPath;
  bool cancelRequested = false;
  TransferItem(this.id, this.name, this.isUpload, this.total);
}

/// Runs downloads/uploads one request at a time per call, reports progress through
/// [changes]. Pure Dart (no Flutter): fully unit-testable.
class TransferController {
  final FilePlatform files;
  final String Function(Object error) explain;
  final List<TransferItem> items = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _n = 0;
  TransferController(this.files, {required this.explain});

  Stream<void> get changes => _changes.stream;
  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void cancel(TransferItem i) {
    i.cancelRequested = true;
    _notify();
  }

  void clearFinished() {
    items.removeWhere((i) => i.status != TransferStatus.running);
    _notify();
  }

  Future<void> dispose() => _changes.close();

  Future<TransferItem> download(StorageAdapter adapter, RemoteNode node) async {
    final item = TransferItem(++_n, node.name, false, node.size ?? -1);
    items.insert(0, item);
    _notify();
    File? file;
    FileSink? sink;
    try {
      final dir = await files.downloadsDir();
      file = uniqueFile(dir, node.name);
      sink = FileSink(file);
      item.localPath = file.path;
      final job = TransferJob(
        id: '${item.id}',
        accountId: node.accountId,
        kind: TransferKind.download,
        remoteId: node.id,
        localPath: file.path,
        totalBytes: node.size ?? -1,
      );
      await TransferRunner().download(
        adapter: adapter,
        job: job,
        sink: sink,
        onProgress: (d, t) {
          item.done = d;
          _notify();
        },
        isCancelled: () => item.cancelRequested,
      );
      await sink.close();
      item.status = TransferStatus.done;
    } on TransferCancelled {
      await _discard(sink, file);
      item.status = TransferStatus.cancelled;
    } catch (e) {
      await _discard(sink, file);
      item.status = TransferStatus.failed;
      item.error = explain(e);
    }
    _notify();
    return item;
  }

  Future<void> _discard(FileSink? sink, File? file) async {
    try {
      await sink?.close();
      if (file != null && await file.exists())
        await file.delete(); // never leave a half-written file
    } catch (_) {}
  }

  /// [resumableThreshold]: files larger than this use the adapter's resumable session
  /// (if it has one); smaller files use a single streamed request.
  Future<TransferItem> upload(
    StorageAdapter adapter,
    String accountId,
    String parentId,
    PickedFile file, {
    int resumableThreshold = 4 * 1024 * 1024,
  }) async {
    final length = await file.length();
    final item = TransferItem(++_n, file.name, true, length);
    items.insert(0, item);
    _notify();
    try {
      if (adapter is ResumableUploader && length > resumableThreshold) {
        await TransferRunner().upload(
          uploader: adapter as ResumableUploader,
          source: PickedFileSource(file),
          accountId: accountId,
          parentId: parentId,
          name: file.name,
          onProgress: (d, t) {
            item.done = d;
            _notify();
          },
          isCancelled: () => item.cancelRequested,
        );
      } else {
        if (item.cancelRequested) throw TransferCancelled();
        await adapter.upload(
          accountId,
          parentId,
          file.name,
          file.openRead(),
          length,
        );
        item.done = length;
      }
      item.status = TransferStatus.done;
    } on TransferCancelled {
      item.status = TransferStatus.cancelled;
    } catch (e) {
      item.status = TransferStatus.failed;
      item.error = explain(e);
    }
    _notify();
    return item;
  }
}
