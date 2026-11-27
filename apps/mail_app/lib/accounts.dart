import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mail_core/mail_core.dart';
import 'package:mail_imap/mail_imap.dart';

import 'demo.dart';
import 'services.dart';

class MailSession {
  final MailTransport transport;
  final MailStore store;
  final String fromAddress;
  final bool persistent;
  MailSession(this.transport, this.store, this.fromAddress, {this.persistent = false});
}

/// Which OAuth configuration (if any) serves a mail profile.
String? oauthIdForProfile(String profileId) => switch (profileId) {
      'gmail' => 'google_mail',
      'outlook' => 'microsoft_mail',
      _ => null,
    };

class MailAccounts {
  final MailServices services;
  final AccountVault vault;
  final Map<String, MailSession> _sessions = {};
  MailAccounts(this.services) : vault = AccountVault(services.secureStore, 'aethryon.mail');

  Future<List<AccountRecord>> list() => vault.list();

  MailSession demoSession() => _sessions.putIfAbsent(
      demoAccount, () => MailSession(buildDemoTransport(), MemoryMailStore(), 'demo@example.invalid'));

  MailSession sessionFor(String id, List<AccountRecord> records, MailDb db) {
    if (id == demoAccount) return demoSession();
    final r = records.firstWhere((e) => e.id == id);
    return _sessions.putIfAbsent(id, () {
      final s = r.settings;
      final config = ImapSmtpConfig(
        imapHost: s['imapHost']!,
        imapPort: int.parse(s['imapPort']!),
        smtpHost: s['smtpHost']!,
        smtpPort: int.parse(s['smtpPort']!),
        smtpSecure: s['smtpSecure'] == 'true',
        username: s['username']!,
      );
      final ImapSmtpTransport transport;
      if (s['auth'] == 'oauth') {
        final cfg = oauthProviderById(s['oauthProvider']!)!;
        final src = OAuthTokenSource(
          tokens: SecureTokenStore(services.secureStore, 'aethryon.mail'),
          client: services.httpClient,
          tokenEndpoint: cfg.tokenEndpoint,
          clientId: s['clientId']!,
          clientSecretProvider: () => vault.secret(id),
        );
        transport = ImapSmtpTransport(config, () => src.accessToken(id), useOAuth: true);
      } else {
        transport = ImapSmtpTransport(config, () async => (await vault.secret(id)) ?? '');
      }
      final persisted = db.store;
      if (persisted != null) {
        persisted.registerAccount(id, s['profile'] ?? 'generic_imap', s['username']!);
        return MailSession(transport, persisted, s['username']!, persistent: true);
      }
      return MailSession(transport, MemoryMailStore(), s['username']!);
    });
  }

  Future<void> remove(String id, MailDb db) async {
    _sessions.remove(id);
    await SecureTokenStore(services.secureStore, 'aethryon.mail').delete(id);
    db.store?.removeAccount(id);
    await vault.remove(id);
  }
}

bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

String explainMailError(Object e) {
  if (e is OAuthError) {
    if (e.code == 'reauth_required') return 'Please sign in again for this account.';
    if (e.code == 'access_denied') return 'Sign-in was cancelled.';
    return 'Sign-in failed (${e.code}).';
  }
  return 'Could not reach the mail server. Check the server names, ports and sign-in details.';
}

class AccountsScreen extends StatelessWidget {
  final MailAccounts accounts;
  final List<AccountRecord> records;
  final String selected;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onRemove;
  final Future<void> Function() onChanged;
  const AccountsScreen({
    super.key,
    required this.accounts,
    required this.records,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onChanged,
  });

  Future<void> _confirmRemove(BuildContext context, AccountRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove "${r.label}"?'),
        content: const Text(
            'This removes the account, its saved password/sign-in and its saved mail headers from this device. Your mailbox is not touched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await onRemove(r.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
        onPressed: () async {
          final ok = await Navigator.of(context)
              .push<bool>(MaterialPageRoute<bool>(builder: (_) => AddMailScreen(accounts: accounts)));
          if (ok == true) await onChanged();
        },
      ),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.science_outlined),
          title: const Text('Demo account'),
          subtitle: const Text('In-memory sample mail'),
          selected: selected == demoAccount,
          onTap: () => onSelect(demoAccount),
        ),
        for (final r in records)
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(r.label),
            subtitle: Text(r.settings['username'] ?? ''),
            selected: selected == r.id,
            onTap: () => onSelect(r.id),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove ${r.label}',
              onPressed: () => _confirmRemove(context, r),
            ),
          ),
      ]),
    );
  }
}

class AddMailScreen extends StatefulWidget {
  final MailAccounts accounts;
  const AddMailScreen({super.key, required this.accounts});
  @override
  State<AddMailScreen> createState() => _AddMailScreenState();
}

class _AddMailScreenState extends State<AddMailScreen> {
  ProviderProfile _profile = profileById('generic_imap')!;
  final _label = TextEditingController();
  final _user = TextEditingController();
  final _imapHost = TextEditingController();
  final _imapPort = TextEditingController(text: '993');
  final _smtpHost = TextEditingController();
  final _smtpPort = TextEditingController(text: '465');
  final _password = TextEditingController();
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  String? _error;
  bool _busy = false;

  String? get _oauthId => oauthIdForProfile(_profile.id);
  bool get _oauthOnly => _oauthId != null && !_profile.auth.contains(AuthMethod.appPassword) && !_profile.auth.contains(AuthMethod.password);

  @override
  void dispose() {
    for (final c in [_label, _user, _imapHost, _imapPort, _smtpHost, _smtpPort, _password, _clientId, _clientSecret]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pick(ProviderProfile p) {
    setState(() {
      _profile = p;
      _error = null;
      _imapHost.text = p.imap?.host ?? '';
      _imapPort.text = '${p.imap?.port ?? 993}';
      _smtpHost.text = p.smtp?.host ?? '';
      _smtpPort.text = '${p.smtp?.port ?? 465}';
    });
  }

  String? _validate({required bool oauth}) {
    if (_label.text.trim().isEmpty) return 'Give this account a name.';
    if (!_user.text.contains('@')) return 'Enter the full e-mail address as the username.';
    if (_imapHost.text.trim().isEmpty || _smtpHost.text.trim().isEmpty) return 'Enter the IMAP and SMTP server names.';
    if (int.tryParse(_imapPort.text) == null || int.tryParse(_smtpPort.text) == null) return 'Ports must be numbers.';
    if (oauth) {
      if (_clientId.text.trim().isEmpty) return 'Enter your own app\'s client ID (Aethryon ships none).';
    } else if (_password.text.isEmpty) {
      return 'Enter the app password.';
    }
    return null;
  }

  Map<String, String> _settings() => {
        'profile': _profile.id,
        'username': _user.text.trim(),
        'imapHost': _imapHost.text.trim(),
        'imapPort': _imapPort.text.trim(),
        'smtpHost': _smtpHost.text.trim(),
        'smtpPort': _smtpPort.text.trim(),
        'smtpSecure': '${_smtpPort.text.trim() == '465'}',
      };

  Future<void> _savePassword() async {
    final err = _validate(oauth: false);
    if (err != null) return setState(() => _error = err);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await widget.accounts.vault.save(
      AccountRecord(id: id, kind: 'imap', label: _label.text.trim(), settings: {..._settings(), 'auth': 'password'}),
      secret: _password.text, // OS secure store only
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _signIn() async {
    final err = _validate(oauth: true);
    if (err != null) return setState(() => _error = err);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = widget.accounts.services;
      final cfg = oauthProviderById(_oauthId!)!;
      final secret = _clientSecret.text.trim().isEmpty ? null : _clientSecret.text.trim();
      final tokens = await oauthSignIn(
          provider: cfg, clientId: _clientId.text.trim(), clientSecret: secret,
          openUrl: s.opener.open, httpClient: s.httpClient);
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await SecureTokenStore(s.secureStore, 'aethryon.mail').write(id, tokens);
      await widget.accounts.vault.save(
        AccountRecord(
            id: id, kind: 'imap', label: _label.text.trim(),
            settings: {..._settings(), 'auth': 'oauth', 'oauthProvider': cfg.id, 'clientId': _clientId.text.trim()}),
        secret: secret ?? '',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = explainMailError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = connectBlockedReason(_profile, isMobile: isMobilePlatform, oauthAvailable: _oauthId != null);
    return Scaffold(
      appBar: AppBar(title: const Text('Add mail account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DropdownButtonFormField<String>(
            key: const Key('profile'),
            initialValue: _profile.id,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: [for (final p in profiles) DropdownMenuItem(value: p.id, child: Text(p.displayName))],
            onChanged: (v) => _pick(profileById(v!)!),
          ),
          if (_profile.userNote != null) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(_profile.userNote!)),
          if (!_profile.hostsVerified && _profile.imap != null)
            const Padding(
                padding: EdgeInsets.only(top: Space.s),
                child: Text('These server names are suggestions — please confirm them with your provider.')),
          if (blocked != null)
            Padding(
                padding: const EdgeInsets.only(top: Space.m),
                child: Text(blocked, key: const Key('blocked'), style: TextStyle(color: Theme.of(context).colorScheme.error))),
          TextField(key: const Key('label'), controller: _label, decoration: const InputDecoration(labelText: 'Name')),
          TextField(
              key: const Key('user'),
              controller: _user,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail address (username)')),
          TextField(key: const Key('imapHost'), controller: _imapHost, decoration: const InputDecoration(labelText: 'IMAP server')),
          TextField(key: const Key('imapPort'), controller: _imapPort, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'IMAP port (SSL)')),
          TextField(key: const Key('smtpHost'), controller: _smtpHost, decoration: const InputDecoration(labelText: 'SMTP server')),
          TextField(key: const Key('smtpPort'), controller: _smtpPort, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SMTP port (465 = SSL)')),
          if (_oauthOnly) ...[
            TextField(key: const Key('clientId'), controller: _clientId, decoration: const InputDecoration(labelText: 'Client ID (your own app registration)')),
            TextField(key: const Key('clientSecret'), controller: _clientSecret, obscureText: true, decoration: const InputDecoration(labelText: 'Client secret (only if the provider gave you one)')),
          ] else
            TextField(key: const Key('password'), controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'App password')),
          const SizedBox(height: Space.m),
          if (_error != null) Text(_error!, key: const Key('error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: Space.m),
          if (_oauthOnly)
            FilledButton(onPressed: (blocked == null && !_busy) ? _signIn : null, child: Text(_busy ? 'Waiting for the browser…' : 'Sign in with browser'))
          else
            FilledButton(onPressed: blocked == null ? _savePassword : null, child: const Text('Save')),
        ]),
      ),
    );
  }
}
