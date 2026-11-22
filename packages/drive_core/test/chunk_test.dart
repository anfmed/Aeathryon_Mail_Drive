import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

void main() {
  test('OneDrive: all but last chunk are multiples of 320 KiB', () {
    final plan = planChunks(
        totalBytes: 25 * 1024 * 1024 + 123,
        preferred: 5 * 1024 * 1024 + 7, // not a multiple on purpose
        constraint: ChunkConstraint.oneDrive);
    for (final c in plan.sublist(0, plan.length - 1)) {
      expect(c.length % 327680, 0);
    }
    expect(plan.first.start, 0);
    expect(plan.last.endInclusive, 25 * 1024 * 1024 + 122);
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].start, plan[i - 1].endInclusive + 1);
    }
  });
  test('resume starts at confirmed offset', () {
    final plan = planChunks(
        totalBytes: 1000,
        preferred: 300,
        constraint: const ChunkConstraint(maxChunk: 1000),
        startOffset: 600);
    expect(plan, [const ChunkRange(600, 899), const ChunkRange(900, 999)]);
  });
  test('empty and finished transfers produce no chunks', () {
    expect(
        planChunks(totalBytes: 0, preferred: 10, constraint: const ChunkConstraint(maxChunk: 10)),
        isEmpty);
    expect(
        planChunks(totalBytes: 10, preferred: 10, constraint: const ChunkConstraint(maxChunk: 10), startOffset: 10),
        isEmpty);
  });
  test('invalid offset rejected', () {
    expect(
        () => planChunks(totalBytes: 10, preferred: 5, constraint: const ChunkConstraint(maxChunk: 5), startOffset: 11),
        throwsArgumentError);
  });
}
