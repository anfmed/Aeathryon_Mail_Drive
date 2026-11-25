import 'package:aethryon_capability/aethryon_capability.dart';

import 'models.dart';

/// Feature keys used in the capability registry (stable identifiers).
class DriveFeature {
  static const browse = 'browse';
  static const download = 'download';
  static const rangeDownload = 'rangeDownload';
  static const upload = 'upload';
  static const resumableUpload = 'resumableUpload';
  static const mkdir = 'mkdir';
  static const move = 'move';
  static const trash = 'trash';
  static const permanentDelete = 'permanentDelete';
  static const share = 'share';
  static const serverSearch = 'serverSearch';
  static const changeFeed = 'changeFeed';
  static const quota = 'quota';
}

/// Provider-specific code lives only behind this interface (never in UI).
abstract class StorageAdapter {
  String get providerId;
  Capability capability(String feature);

  Future<Page<RemoteNode>> listChildren(
    String accountId,
    String parentId, {
    String? cursor,
  });
  Future<RemoteNode> metadata(String accountId, String id);

  /// Streams bytes; [start]/[endInclusive] only if rangeDownload is enabled.
  Stream<List<int>> download(
    String accountId,
    String id, {
    int? start,
    int? endInclusive,
  });

  Future<RemoteNode> upload(
    String accountId,
    String parentId,
    String name,
    Stream<List<int>> data,
    int length,
  );

  Future<void> mkdir(String accountId, String parentId, String name);
  Future<void> move(
    String accountId,
    String id,
    String newParentId,
    String newName,
  );

  /// Recoverable delete. Adapters that cannot trash MUST throw
  /// [UnsupportedOperation]; callers must not fall back to permanent delete
  /// without an explicit second user confirmation.
  Future<void> trash(String accountId, String id);
  Future<void> permanentDelete(String accountId, String id);

  Future<QuotaInfo> quota(String accountId);
}
