class OAuthProviderConfig {
  final String id;
  final String displayName;
  final Uri authEndpoint;
  final Uri tokenEndpoint;
  final List<String> scopes;
  final Map<String, String> extraAuthParams;
  /// Scope strings backed by a Phase-0 primary source (S-ids). Endpoint URLs are
  /// from general knowledge and NOT yet verified against official pages.
  final List<String> scopeSources;
  final bool endpointsVerified;
  const OAuthProviderConfig({
    required this.id,
    required this.displayName,
    required this.authEndpoint,
    required this.tokenEndpoint,
    required this.scopes,
    this.extraAuthParams = const {},
    this.scopeSources = const [],
    this.endpointsVerified = false,
  });
}

/// The user supplies their OWN client id (ADR-009). No client id/secret is shipped.
final oauthProviders = <OAuthProviderConfig>[
  OAuthProviderConfig(
    id: 'microsoft_mail',
    displayName: 'Outlook / Microsoft 365 (mail)',
    authEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/authorize'),
    tokenEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
    scopes: const [
      'https://outlook.office.com/IMAP.AccessAsUser.All',
      'https://outlook.office.com/SMTP.Send',
      'offline_access',
    ],
    scopeSources: const ['S09'],
  ),
  OAuthProviderConfig(
    id: 'microsoft_onedrive',
    displayName: 'OneDrive',
    authEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/authorize'),
    tokenEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
    scopes: const ['Files.ReadWrite', 'offline_access'],
    scopeSources: const ['S11'],
  ),
  OAuthProviderConfig(
    id: 'google_mail',
    displayName: 'Gmail',
    authEndpoint: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
    tokenEndpoint: Uri.parse('https://oauth2.googleapis.com/token'),
    scopes: const ['https://mail.google.com/'],
    extraAuthParams: const {'access_type': 'offline', 'prompt': 'consent'},
    scopeSources: const ['S04'],
  ),
  OAuthProviderConfig(
    id: 'google_drive',
    displayName: 'Google Drive',
    authEndpoint: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
    tokenEndpoint: Uri.parse('https://oauth2.googleapis.com/token'),
    scopes: const ['https://www.googleapis.com/auth/drive'],
    extraAuthParams: const {'access_type': 'offline', 'prompt': 'consent'},
    scopeSources: const ['S01', 'S02'],
  ),
  OAuthProviderConfig(
    id: 'dropbox',
    displayName: 'Dropbox',
    authEndpoint: Uri.parse('https://www.dropbox.com/oauth2/authorize'),
    tokenEndpoint: Uri.parse('https://api.dropboxapi.com/oauth2/token'),
    scopes: const [],
    extraAuthParams: const {'token_access_type': 'offline'},
  ),
];

OAuthProviderConfig? oauthProviderById(String id) {
  for (final p in oauthProviders) {
    if (p.id == id) return p;
  }
  return null;
}
