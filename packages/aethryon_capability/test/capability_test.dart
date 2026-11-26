import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:test/test.dart';

void main() {
  test('FULL without sources is rejected', () {
    expect(() => Capability.full(sources: []), throwsArgumentError);
  });
  test('unverified/unsupported are never enabled in UI', () {
    expect(const Capability.unverified().enabledInUi, isFalse);
    expect(const Capability.unsupported().enabledInUi, isFalse);
    expect(const Capability.requiresCompanion().enabledInUi, isFalse);
  });
  test('registry falls back to unverified', () {
    final r = CapabilityRegistry();
    expect(r.lookup('x', 'y').status, CapabilityStatus.unverified);
  });
  test('runtime probe overrides manifest', () {
    final r = CapabilityRegistry()
      ..register('p', {
        'a': const Capability.unverified(),
      }, overall: const Capability.unverified());
    r.applyProbe('p', 'a', Capability.full(sources: ['probe']));
    expect(r.lookup('p', 'a').enabledInUi, isTrue);
  });
}
