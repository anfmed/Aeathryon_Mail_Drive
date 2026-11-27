import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

class BadDownload extends MemoryStorageAdapter {
  @override
  Stream<List<int>> download(
    String accountId,
    String id, {
    int? start,
    int? endInclusive,
  }) => Stream.error(StateError('boom: secret-name.txt'));
}

void main() {
  test(
    'all steps pass on a healthy adapter and the test folder is removed',
    () async {
      final a = MemoryStorageAdapter();
      final steps = await runAdapterSelfTest(a, 'acc');
      expect(steps.where((s) => !s.ok), isEmpty);
      expect(
        steps.map((s) => s.name),
        containsAll([
          'create folder',
          'upload 2 KB file',
          'clean up (delete the test folder)',
        ]),
      );
      expect((await a.listChildren('acc', '/')).items, isEmpty);
      expect(
        formatSelfTest('memory', steps),
        contains('RESULT: all required steps passed'),
      );
    },
  );

  test('a failing step is reported without leaking messages, and cleanup still runs', () async {
    final a = BadDownload();
    final steps = await runAdapterSelfTest(a, 'acc');
    final dl = steps.firstWhere((s) => s.name == 'download the whole file');
    expect(dl.ok, isFalse);
    expect(dl.detail, 'StateError');
    expect(dl.detail.contains('secret'), isFalse);
    expect(steps.last.name, 'clean up (delete the test folder)');
    expect(steps.last.ok, isTrue);
    expect((await a.listChildren('acc', '/')).items, isEmpty);
    expect(
      formatSelfTest('memory', steps),
      contains('required step(s) failed'),
    );
  });
}
