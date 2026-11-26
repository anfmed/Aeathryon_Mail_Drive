import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:drive_core/drive_core.dart';

String explainError(Object e) {
  if (e is ProviderHttpError) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return 'The server refused the login. Check the username and password.';
    }
    if (e.statusCode == 404) return 'This folder was not found on the server.';
    if (e.statusCode == 507) return 'The account is out of storage space.';
    return 'The server answered with an error (HTTP ${e.statusCode}).';
  }
  if (e is OAuthError) {
    if (e.code == 'reauth_required')
      return 'Please sign in again for this account.';
    if (e.code == 'access_denied') return 'Sign-in was cancelled.';
    return 'Sign-in failed (${e.code}).';
  }
  if (e is RetryExhausted)
    return 'The server did not respond. Check your connection and the address.';
  return 'Could not reach the server.';
}
