import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:test/test.dart';

class MemStore implements SecureStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

void main() {
  test('JsonSettings round-trips and tolerates corrupt data', () async {
    final s = MemStore();
    final j = JsonSettings(s, 'k');
    expect(await j.load(), isEmpty);
    await j.save({'a': 1, 'b': true});
    expect(await j.load(), {'a': 1, 'b': true});
    s.m['k'] = '{not json';
    expect(await j.load(), isEmpty);
  });
}
