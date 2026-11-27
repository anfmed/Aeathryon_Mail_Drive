import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

void main() {
  late MemoryStorageAdapter a;
  setUp(() {
    a = MemoryStorageAdapter()
      ..seedFolder('x', '/Docs')
      ..seedFile('x', '/Docs/b.txt', [1, 2, 3])
      ..seedFile('x', '/Docs/A.txt', [1])
      ..seedFile('x', '/root.txt', [9, 9]);
  });

  test('list is scoped to account and parent', () async {
    final r = await a.listChildren('x', '/Docs');
    expect(r.items.map((e) => e.name).toSet(), {'b.txt', 'A.txt'});
    expect((await a.listChildren('other', '/Docs')).items, isEmpty);
  });
  test('sort: folders first, case-insensitive name', () async {
    final l = sortNodes((await a.listChildren('x', '/')).items);
    expect(l.map((e) => e.name), ['Docs', 'root.txt']);
    final d = sortNodes((await a.listChildren('x', '/Docs')).items);
    expect(d.map((e) => e.name), ['A.txt', 'b.txt']);
  });
  test('range download', () async {
    final bytes = await a.download('x', '/Docs/b.txt', start: 1, endInclusive: 2).expand((e) => e).toList();
    expect(bytes, [2, 3]);
  });
  test('trash is recoverable; permanent delete is not', () async {
    await a.trash('x', '/root.txt');
    expect((await a.listChildren('x', '/')).items.map((e) => e.name), ['Docs']);
    a.restore('x', '/root.txt');
    expect((await a.listChildren('x', '/')).items.length, 2);
    await a.permanentDelete('x', '/root.txt');
    await expectLater(a.metadata('x', '/root.txt'), throwsA(isA<ProviderHttpError>()));
  });
  test('move never overwrites silently', () async {
    await expectLater(a.move('x', '/root.txt', '/Docs', 'A.txt'), throwsA(isA<ProviderHttpError>()));
    await a.move('x', '/root.txt', '/Docs', 'moved.txt');
    expect((await a.metadata('x', '/Docs/moved.txt')).size, 2);
  });
  test('upload + quota', () async {
    await a.upload('x', '/', 'u.bin', Stream.value([1, 2, 3, 4]), 4);
    expect((await a.quota('x')).usedBytes, 3 + 1 + 2 + 4);
  });
  test('browse stack', () {
    var s = BrowseState.root('x').push('/Docs').push('/Docs/Sub');
    expect(s.current, '/Docs/Sub');
    expect(s.pop().current, '/Docs');
    expect(s.jumpTo(0).atRoot, isTrue);
    expect(BrowseState.root('x').pop().atRoot, isTrue);
  });
  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(null), '');
  });
}
