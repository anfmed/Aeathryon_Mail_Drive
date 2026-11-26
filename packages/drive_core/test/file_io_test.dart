import 'dart:io';

import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('aeth_io_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('sanitizeFileName blocks traversal, reserved names and junk', () {
    expect(sanitizeFileName('../../etc/passwd'), isNot(contains('/')));
    expect(sanitizeFileName('..\\..\\win.ini'), isNot(contains('\\')));
    expect(sanitizeFileName('..hidden'), startsWith('_'));
    expect(sanitizeFileName('CON.txt'), '_CON.txt');
    expect(sanitizeFileName('a:b*c?.txt'), 'a_b_c_.txt');
    expect(sanitizeFileName('   '), 'file');
    expect(sanitizeFileName('${'x' * 300}.pdf').length, 120);
    expect(sanitizeFileName('${'x' * 300}.pdf'), endsWith('.pdf'));
    expect(sanitizeFileName('অর্থ.txt'), 'অর্থ.txt');
  });

  test('uniqueFile never overwrites', () {
    File('${dir.path}/a.txt').writeAsStringSync('1');
    final f2 = uniqueFile(dir.path, 'a.txt');
    expect(f2.path, endsWith('a (1).txt'));
    f2.writeAsStringSync('2');
    expect(uniqueFile(dir.path, 'a.txt').path, endsWith('a (2).txt'));
    expect(uniqueFile(dir.path, '../a.txt').path.startsWith(dir.path), isTrue);
  });

  test(
    'FileSink appends, reports length, truncates; FileSource reads ranges',
    () async {
      final f = File('${dir.path}/d.bin');
      final sink = FileSink(f);
      expect(await sink.length(), 0);
      await sink.append([1, 2, 3]);
      await sink.append([4, 5]);
      expect(await sink.length(), 5);
      await sink.truncate();
      expect(await sink.length(), 0);
      await sink.append([9, 8, 7, 6]);
      await sink.close();
      expect(f.readAsBytesSync(), [9, 8, 7, 6]);
      final src = FileSource(f);
      expect(await src.length(), 4);
      expect(await src.read(1, 2), [8, 7]);
    },
  );

  test('TransferRunner downloads into a real file and resumes', () async {
    final a = MemoryStorageAdapter()
      ..seedFile('x', '/f.bin', [1, 2, 3, 4, 5, 6]);
    final f = File('${dir.path}/f.bin')..writeAsBytesSync([1, 2, 3]);
    final sink = FileSink(f);
    const job = TransferJob(
      id: 'j',
      accountId: 'x',
      kind: TransferKind.download,
      remoteId: '/f.bin',
      localPath: '',
      totalBytes: 6,
      transferredBytes: 3,
    );
    await TransferRunner().download(adapter: a, job: job, sink: sink);
    await sink.close();
    expect(f.readAsBytesSync(), [1, 2, 3, 4, 5, 6]);
  });
}
