import 'dart:convert';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:drive_core/drive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo.dart';
import 'errors.dart';
import 'services.dart';

/// Owns the vault (OS secure store) and builds adapters. The UI never sees providers.
class DriveAccounts {
  final DriveServices services;
  final AccountVault vault;
  final MemoryStorageAdapter demo = buildDemoAdapter();
  final Map<String, StorageAdapter> _cache = {};
  DriveAccounts(this.services)
    : vault = AccountVault(services.secureStore, 'aethryon.drive');

  Future<List<AccountRecord>> list() => vault.list();

  static WebDavAdapter buildWebDav(
    String url,
    String user,
    Future<String?> Function() password,
  ) => WebDavAdapter(
    baseUrl: Uri.parse(url),
    authorizationHeader: (_) async {
      final pw = await password() ?? '';
      return 'Basic ${base64Encode(utf8.encode('$user:$pw'))}';
    },
  );

  StorageAdapter adapterFor(String id, List<AccountRecord> records) {
    if (id == demoAccount) return demo;
    final r = records.firstWhere((e) => e.id == id);
    return _cache.putIfAbsent(id, () {
      if (r.kind == 'webdav') {
        return buildWebDav(
          r.settings['url']!,
          r.settings['username']!,
          () => vault.secret(id),
        );
      }
      final cfg = oauthProviderById(
        r.kind == 'dropbox' ? 'dropbox' : 'microsoft_onedrive',
      )!;
      final src = OAuthTokenSource(
        tokens: SecureTokenStore(services.secureStore, 'aethryon.drive'),
        client: services.httpClient,
        tokenEndpoint: cfg.tokenEndpoint,
        clientId: r.settings['clientId']!,
        clientSecretProvider: () => vault.secret(id),
      );
      return r.kind == 'dropbox'
          ? DropboxAdapter(
              accessToken: src.accessToken,
              client: services.httpClient,
            )
          : OneDriveAdapter(
              accessToken: src.accessToken,
              client: services.httpClient,
            );
    });
  }

  Future<void> remove(String id, {DriveStore? store}) async {
    _cache.remove(id);
    await SecureTokenStore(services.secureStore, 'aethryon.drive').delete(id);
    store?.removeAccount(id);
    await vault.remove(id);
  }
}

String kindLabel(String kind) => switch (kind) {
  'webdav' => 'WebDAV / Nextcloud',
  'dropbox' => 'Dropbox (experimental)',
  'onedrive' => 'OneDrive (experimental)',
  _ => kind,
};

class AccountsScreen extends StatelessWidget {
  final DriveAccounts accounts;
  final List<AccountRecord> records;
  final String selected;
  final bool experimental;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onRemove;
  final Future<void> Function() onChanged;
  const AccountsScreen({
    super.key,
    required this.accounts,
    required this.records,
    required this.selected,
    required this.experimental,
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
          'This removes the account, its saved password/sign-in and its offline copy from this device. Your files on the server are not touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await onRemove(r.id);
  }

  Future<void> _selfTest(BuildContext context, AccountRecord r) async {
    await showDialog<void>(
      context: context,
      builder: (c) => _SelfTestDialog(accounts: accounts, record: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => AddAccountScreen(
                accounts: accounts,
                experimental: experimental,
              ),
            ),
          );
          if (ok == true) await onChanged();
        },
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Demo account'),
            subtitle: const Text('In-memory sample files'),
            selected: selected == demoAccount,
            onTap: () => onSelect(demoAccount),
          ),
          for (final r in records)
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(r.label),
              subtitle: Text(kindLabel(r.kind)),
              selected: selected == r.id,
              onTap: () => onSelect(r.id),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fact_check_outlined),
                    tooltip: 'Run self-test for ${r.label}',
                    onPressed: () => _selfTest(context, r),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove ${r.label}',
                    onPressed: () => _confirmRemove(context, r),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SelfTestDialog extends StatefulWidget {
  final DriveAccounts accounts;
  final AccountRecord record;
  const _SelfTestDialog({required this.accounts, required this.record});
  @override
  State<_SelfTestDialog> createState() => _SelfTestDialogState();
}

class _SelfTestDialogState extends State<_SelfTestDialog> {
  String? _result;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    String text;
    try {
      final recs = await widget.accounts.list();
      final a = widget.accounts.adapterFor(widget.record.id, recs);
      final steps = await runAdapterSelfTest(a, widget.record.id);
      text = formatSelfTest(widget.record.kind, steps);
    } catch (e) {
      text = 'Self-test could not start: ${explainError(e)}';
    }
    if (mounted) setState(() => _result = text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Account self-test'),
    content: _result == null
        ? const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          )
        : SingleChildScrollView(child: SelectableText(_result!)),
    actions: [
      if (_result != null)
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: _result!)),
          child: const Text('Copy'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class AddAccountScreen extends StatelessWidget {
  final DriveAccounts accounts;
  final bool experimental;
  const AddAccountScreen({
    super.key,
    required this.accounts,
    required this.experimental,
  });

  Future<void> _go(BuildContext context, Widget screen) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute<bool>(builder: (_) => screen));
    if (ok == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add account')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: const Text('WebDAV / Nextcloud'),
          subtitle: const Text('Your own server. Use an app password.'),
          onTap: () => _go(context, AddWebDavScreen(vault: accounts.vault)),
        ),
        if (experimental) ...[
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Dropbox (experimental)'),
            subtitle: const Text(
              'Not verified against a real account yet. Use the self-test.',
            ),
            onTap: () => _go(
              context,
              AddOAuthDriveScreen(accounts: accounts, kind: 'dropbox'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('OneDrive (experimental)'),
            subtitle: const Text(
              'Not verified against a real account yet. Use the self-test.',
            ),
            onTap: () => _go(
              context,
              AddOAuthDriveScreen(accounts: accounts, kind: 'onedrive'),
            ),
          ),
        ],
      ],
    ),
  );
}

class AddOAuthDriveScreen extends StatefulWidget {
  final DriveAccounts accounts;
  final String kind; // 'dropbox' | 'onedrive'
  const AddOAuthDriveScreen({
    super.key,
    required this.accounts,
    required this.kind,
  });
  @override
  State<AddOAuthDriveScreen> createState() => _AddOAuthDriveScreenState();
}

class _AddOAuthDriveScreenState extends State<AddOAuthDriveScreen> {
  final _label = TextEditingController();
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_label.text.trim().isEmpty)
      return setState(() => _error = 'Give this account a name.');
    if (_clientId.text.trim().isEmpty)
      return setState(
        () => _error = 'Enter your app\'s client ID (see docs/GOOGLE_BYO_CLIENT_GUIDE.md for the idea).',
      );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = widget.accounts.services;
      final cfg = oauthProviderById(
        widget.kind == 'dropbox' ? 'dropbox' : 'microsoft_onedrive',
      )!;
      final secret = _clientSecret.text.trim().isEmpty
          ? null
          : _clientSecret.text.trim();
      final tokens = await oauthSignIn(
        provider: cfg,
        clientId: _clientId.text.trim(),
        clientSecret: secret,
        openUrl: s.opener.open,
        httpClient: s.httpClient,
      );
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await SecureTokenStore(s.secureStore, 'aethryon.drive').write(id, tokens);
      await widget.accounts.vault.save(
        AccountRecord(
          id: id,
          kind: widget.kind,
          label: _label.text.trim(),
          settings: {'clientId': _clientId.text.trim()},
        ),
        secret: secret ?? '',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = explainError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Add ${kindLabel(widget.kind)}')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You create your own app registration with the provider and paste its client ID here. '
            'Aethryon ships no shared client ID. Sign-in happens in your browser.',
          ),
          const SizedBox(height: Space.m),
          TextField(
            key: const Key('label'),
            controller: _label,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            key: const Key('clientId'),
            controller: _clientId,
            decoration: const InputDecoration(labelText: 'Client ID'),
          ),
          TextField(
            key: const Key('clientSecret'),
            controller: _clientSecret,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Client secret (only if the provider gave you one)',
            ),
          ),
          const SizedBox(height: Space.m),
          if (_error != null)
            Text(
              _error!,
              key: const Key('error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: Space.m),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child: Text(
              _busy ? 'Waiting for the browser…' : 'Sign in with browser',
            ),
          ),
        ],
      ),
    ),
  );
}

class AddWebDavScreen extends StatefulWidget {
  final AccountVault vault;
  const AddWebDavScreen({super.key, required this.vault});
  @override
  State<AddWebDavScreen> createState() => _AddWebDavScreenState();
}

class _AddWebDavScreenState extends State<AddWebDavScreen> {
  final _label = TextEditingController();
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _info;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_label.text.trim().isEmpty) return 'Give this account a name.';
    final u = validateServerUrl(_url.text);
    if (u != null) return u;
    if (_user.text.trim().isEmpty) return 'Enter the username.';
    if (_password.text.isEmpty)
      return 'Enter the password (an app password is best).';
    return null;
  }

  Future<void> _test() async {
    final err = _validate();
    if (err != null) {
      setState(() {
        _error = err;
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final a = DriveAccounts.buildWebDav(
        _url.text.trim(),
        _user.text.trim(),
        () async => _password.text,
      );
      final page = await a.listChildren('test', '/');
      if (mounted)
        setState(() => _info = 'Connected. Found ${page.items.length} items.');
    } catch (e) {
      if (mounted) setState(() => _error = explainError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() {
        _error = err;
        _info = null;
      });
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await widget.vault.save(
      AccountRecord(
        id: id,
        kind: 'webdav',
        label: _label.text.trim(),
        settings: {'url': _url.text.trim(), 'username': _user.text.trim()},
      ),
      secret: _password.text, // OS secure store only
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add WebDAV / Nextcloud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nextcloud: use https://YOUR-SERVER/remote.php/dav/files/USERNAME/ and an app password '
              '(created in your Nextcloud security settings).',
            ),
            const SizedBox(height: Space.m),
            TextField(
              key: const Key('label'),
              controller: _label,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              key: const Key('url'),
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Server address (https://…)',
              ),
            ),
            TextField(
              key: const Key('user'),
              controller: _user,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password / app password',
              ),
            ),
            const SizedBox(height: Space.m),
            if (_error != null)
              Text(
                _error!,
                key: const Key('error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_info != null) Text(_info!, key: const Key('info')),
            const SizedBox(height: Space.m),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _test,
                  child: const Text('Test connection'),
                ),
                const SizedBox(width: Space.m),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
