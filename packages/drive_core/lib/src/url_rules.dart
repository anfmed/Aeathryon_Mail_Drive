/// Server-URL safety rule for user-entered endpoints: https only, except
/// loopback hosts (local testing). Returns an error message, or null if OK.
String? validateServerUrl(String input) {
  final s = input.trim();
  if (s.isEmpty) return 'Enter the server address.';
  final u = Uri.tryParse(s);
  if (u == null || !u.hasScheme || u.host.isEmpty)
    return 'This is not a valid web address.';
  final local =
      u.host == 'localhost' ||
      u.host == '127.0.0.1' ||
      u.host == '::1' ||
      u.host == '[::1]';
  if (u.scheme == 'https') return null;
  if (u.scheme == 'http' && local) return null;
  if (u.scheme == 'http')
    return 'Use https:// — passwords must not travel unencrypted.';
  return 'Only https:// addresses are supported.';
}
