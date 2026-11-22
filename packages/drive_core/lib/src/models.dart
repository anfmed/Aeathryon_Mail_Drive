class RemoteNode {
  final String accountId;
  final String id; // provider id, or path for WebDAV
  final String? parentId;
  final String name;
  final bool isFolder;
  final int? size;
  final DateTime? modifiedUtc;
  final String? etag;
  const RemoteNode({
    required this.accountId,
    required this.id,
    this.parentId,
    required this.name,
    required this.isFolder,
    this.size,
    this.modifiedUtc,
    this.etag,
  });
}

class Page<T> {
  final List<T> items;
  final String? nextCursor; // null => last page
  const Page(this.items, {this.nextCursor});
}

class QuotaInfo {
  final int? usedBytes;
  final int? totalBytes;
  const QuotaInfo({this.usedBytes, this.totalBytes});
}

/// Thrown for operations a provider does not support (UI should have been
/// disabled via capabilities; this is the safety net, not the primary path).
class UnsupportedOperation implements Exception {
  final String feature;
  UnsupportedOperation(this.feature);
  @override
  String toString() => 'UnsupportedOperation($feature)';
}

class ProviderHttpError implements Exception {
  final int statusCode;
  final String? retryAfterHeader;
  final String message;
  ProviderHttpError(this.statusCode, this.message, {this.retryAfterHeader});
  @override
  String toString() => 'ProviderHttpError($statusCode, $message)';
}
