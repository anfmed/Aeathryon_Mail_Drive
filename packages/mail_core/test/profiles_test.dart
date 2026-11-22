import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  test('Proton is companion-only and not offered on mobile', () {
    final p = profileById('proton_bridge')!;
    expect(p.overall.status, CapabilityStatus.requiresCompanion);
    expect(p.mobileSupported, isFalse);
    expect(p.canAutofillSilently, isFalse);
  });
  test('unverified hosts are never auto-filled silently', () {
    for (final p in profiles.where((p) => !p.hostsVerified)) {
      expect(p.canAutofillSilently, isFalse);
    }
  });
  test('iCloud uses app-specific password only', () {
    expect(profileById('icloud')!.auth, [AuthMethod.appPassword]);
  });
}
