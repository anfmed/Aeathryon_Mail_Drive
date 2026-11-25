import 'package:aethryon_capability/aethryon_capability.dart';

enum AuthMethod { oauth2, appPassword, password, bridgeCredential }
enum Security { ssl, startTls }

class ServerSpec {
  final String host;
  final int port;
  final Security security;
  const ServerSpec(this.host, this.port, this.security);
}

class ProviderProfile {
  final String id;
  final String displayName;
  final ServerSpec? imap;
  final ServerSpec? smtp;
  final List<AuthMethod> auth;
  /// true only when host/port were confirmed from a primary source in Phase 0/1.
  final bool hostsVerified;
  final List<String> sources;
  final Capability overall;
  final bool mobileSupported;
  final String? userNote;
  const ProviderProfile({
    required this.id,
    required this.displayName,
    this.imap,
    this.smtp,
    required this.auth,
    required this.hostsVerified,
    this.sources = const [],
    required this.overall,
    this.mobileSupported = true,
    this.userNote,
  });

  /// Auto-fill is only offered for verified hosts; unverified ones are shown as
  /// "suggested - please confirm" in UI (Phase 4).
  bool get canAutofillSilently => hostsVerified && imap != null;
}

/// Phase 0 sources: S18 (Apple), S17 (Proton), S19 (Yahoo, secondary),
/// S04 (Gmail OAuth), S09 (Microsoft OAuth).
const profiles = <ProviderProfile>[
  ProviderProfile(
    id: 'icloud',
    displayName: 'iCloud Mail',
    imap: ServerSpec('imap.mail.me.com', 993, Security.ssl),
    smtp: ServerSpec('smtp.mail.me.com', 587, Security.startTls),
    auth: [AuthMethod.appPassword],
    hostsVerified: true,
    sources: ['S18'],
    overall: Capability.partial(evidence: Evidence.primary, sources: ['S18']),
    userNote: 'App-specific password required.',
  ),
  ProviderProfile(
    id: 'yahoo',
    displayName: 'Yahoo Mail',
    imap: ServerSpec('imap.mail.yahoo.com', 993, Security.ssl),
    smtp: ServerSpec('smtp.mail.yahoo.com', 465, Security.ssl),
    auth: [AuthMethod.appPassword, AuthMethod.oauth2],
    hostsVerified: false, // S19 is secondary
    sources: ['S19'],
    overall: Capability.requiresPermission(sources: ['S19'], note: 'OAuth needs Yahoo approval (secondary source)'),
  ),
  ProviderProfile(
    id: 'gmail',
    displayName: 'Gmail',
    imap: ServerSpec('imap.gmail.com', 993, Security.ssl),
    smtp: ServerSpec('smtp.gmail.com', 465, Security.ssl),
    auth: [AuthMethod.oauth2],
    hostsVerified: false, // hosts not re-verified this phase; OAuth scope per S04
    sources: ['S04'],
    overall: Capability.requiresPermission(sources: ['S01', 'S04'], note: 'restricted scope; BYO client path (ADR-009)'),
  ),
  ProviderProfile(
    id: 'outlook',
    displayName: 'Outlook / Microsoft 365',
    imap: ServerSpec('outlook.office365.com', 993, Security.ssl),
    smtp: ServerSpec('smtp.office365.com', 587, Security.startTls),
    auth: [AuthMethod.oauth2],
    hostsVerified: false, // OAuth scopes per S09; hosts not re-verified
    sources: ['S09'],
    overall: Capability.partial(evidence: Evidence.primary, sources: ['S09']),
  ),
  ProviderProfile(
    id: 'proton_bridge',
    displayName: 'Proton Mail (via Bridge)',
    imap: null, // host is 127.0.0.1, ports are chosen by the user's Bridge install
    smtp: null,
    auth: [AuthMethod.bridgeCredential],
    hostsVerified: false,
    sources: ['S17'],
    overall: Capability.requiresCompanion(sources: ['S17'], note: 'desktop only; paid Proton plan'),
    mobileSupported: false,
    userNote: 'Needs the official Proton Mail Bridge running on this computer.',
  ),
  ProviderProfile(
    id: 'generic_imap',
    displayName: 'Other (IMAP/SMTP)',
    auth: [AuthMethod.password, AuthMethod.appPassword, AuthMethod.oauth2],
    hostsVerified: false,
    overall: Capability.partial(evidence: Evidence.none, note: 'capabilities discovered at runtime'),
  ),
];

ProviderProfile? profileById(String id) {
  for (final p in profiles) {
    if (p.id == id) return p;
  }
  return null;
}

/// Why this profile cannot be connected RIGHT NOW (null = it can). Honest by design:
/// an unsupported path is explained, never offered.
String? connectBlockedReason(ProviderProfile p, {required bool isMobile, bool oauthAvailable = false}) {
  if (!p.mobileSupported && isMobile) {
    return 'This provider needs a desktop companion app and cannot be used on a phone.';
  }
  if (p.auth.contains(AuthMethod.bridgeCredential)) {
    return 'Connecting through Proton Mail Bridge is not implemented yet.';
  }
  if (!(p.auth.contains(AuthMethod.appPassword) || p.auth.contains(AuthMethod.password)) && !oauthAvailable) {
    return 'Signing in to ${p.displayName} needs OAuth, which is not connected to the app yet.';
  }
  return null;
}
