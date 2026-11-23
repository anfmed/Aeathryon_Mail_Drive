import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  blockedTests();
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

void blockedTests() {
  test(
    'Proton: blocked on phones (companion) and on desktop (not implemented)',
    () {
      final p = profileById('proton_bridge')!;
      expect(
        connectBlockedReason(p, isMobile: true),
        contains('desktop companion'),
      );
      expect(
        connectBlockedReason(p, isMobile: false),
        contains('not implemented'),
      );
    },
  );
  test('OAuth-only providers are blocked; app-password providers are not', () {
    expect(
      connectBlockedReason(profileById('gmail')!, isMobile: false),
      contains('OAuth'),
    );
    expect(
      connectBlockedReason(profileById('outlook')!, isMobile: false),
      contains('OAuth'),
    );
    expect(
      connectBlockedReason(profileById('icloud')!, isMobile: true),
      isNull,
    );
    expect(
      connectBlockedReason(profileById('generic_imap')!, isMobile: false),
      isNull,
    );
    expect(
      connectBlockedReason(profileById('yahoo')!, isMobile: false),
      isNull,
    );
  });
}
