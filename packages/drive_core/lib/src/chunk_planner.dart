class ChunkConstraint {
  final int multipleOf; // all chunks except the last must be a multiple
  final int minChunk;
  final int maxChunk;
  const ChunkConstraint(
      {this.multipleOf = 1, this.minChunk = 1, required this.maxChunk});

  /// Verified (Phase 0, source S11, Microsoft Graph createUploadSession):
  /// fragment size must be a multiple of 320 KiB. maxChunk is a conservative
  /// planning value, NOT a documented limit (UNVERIFIED).
  static const oneDrive =
      ChunkConstraint(multipleOf: 327680, minChunk: 327680, maxChunk: 10 * 1024 * 1024);

  /// Dropbox (S13, SDK doc): <=150 MB per request. We stay at/below 100 MiB.
  static const dropbox = ChunkConstraint(maxChunk: 100 * 1024 * 1024);
}

class ChunkRange {
  final int start;
  final int endInclusive;
  const ChunkRange(this.start, this.endInclusive);
  int get length => endInclusive - start + 1;
  @override
  bool operator ==(Object o) =>
      o is ChunkRange && o.start == start && o.endInclusive == endInclusive;
  @override
  int get hashCode => Object.hash(start, endInclusive);
  @override
  String toString() => 'ChunkRange($start-$endInclusive)';
}

/// Plans contiguous ranges covering [startOffset, totalBytes). Resume = pass the
/// provider-confirmed offset as [startOffset].
List<ChunkRange> planChunks({
  required int totalBytes,
  required int preferred,
  required ChunkConstraint constraint,
  int startOffset = 0,
}) {
  if (totalBytes < 0 || startOffset < 0 || startOffset > totalBytes) {
    throw ArgumentError('invalid sizes');
  }
  var size = preferred.clamp(constraint.minChunk, constraint.maxChunk);
  if (constraint.multipleOf > 1) {
    size = (size ~/ constraint.multipleOf) * constraint.multipleOf;
    if (size < constraint.multipleOf) size = constraint.multipleOf;
  }
  final out = <ChunkRange>[];
  var pos = startOffset;
  while (pos < totalBytes) {
    final end = (pos + size < totalBytes) ? pos + size - 1 : totalBytes - 1;
    out.add(ChunkRange(pos, end));
    pos = end + 1;
  }
  return out;
}
