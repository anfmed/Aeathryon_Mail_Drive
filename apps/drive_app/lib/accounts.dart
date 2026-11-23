import 'dart:convert';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:drive_core/drive_core.dart';
import 'package:flutter/material.dart';

import 'demo.dart';

/// Owns the vault (OS secure store) and builds adapters. The UI never sees providers.
class DriveAccounts {
  final AccountVault vault;
  final MemoryStorageAdapter demo = buildDemoAdapter();
  final Map<String, StorageAdapter> _cache = {};
  DriveAccounts(SecureStore store) : vault = AccountVault(store, 'aethryon.drive');

  Future<List<AccountRecord>> list() => vault.list();

  static WebDavAdapter buildWebDav(String url, String user, Future<String?> Function() password) =>
      WebDavAdapter(
        baseUrl: Uri.parse(url),
        authorizationHeader: (_) async {
          final pw = await password() ?? '';
          return 'Basic ${base64Encode(utf8.encode('$user:$pw'))}';
        },
      );

  StorageAdapter adapterFor(String id, List<AccountRecord> records) {
    if (id == demoAccount) return demo;
    final r = records.firstWhere((e) => e.id == id);
    return _cache.putIfAbsent(
        id, () => buildWebDav(r.settings['url']!, r.settings['username']!, () => vault.secret(id)));
  }

  Future<void> remove(String id) async {
    _cache.remove(id);
    await vault.remove(id);
  }
}

String explainError(Object e) {
  if (e is ProviderHttpError) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return 'The server refused the login. Check the username and password.';
    }
    if (e.statusCode == 404) return 'This folder was not found on the server.';
    return 'The server answered with an error (HTTP ${e.statusCode}).';
  }
  if (e is RetryExhausted) return 'The server did not respond. Check your connection and the address.';
  return 'Could not reach the server.';
}

class AccountsScreen extends StatelessWidget {
  final List<AccountRecord> records;
  final String selected;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onRemove;
  final AccountVault vault;
  final Future<void> Function() onChanged;
  const AccountsScreen({
    super.key,
    required this.records,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.vault,
    required this.onChanged,
  });

  Future<void> _confirmRemove(BuildContext context, AccountRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove "${r.label}"?'),
        content: const Text(
            'This only removes the account from this device. Your files on the server are not touched.'),
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
          final ok = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => AddWebDavScreen(vault: vault)));
          if (ok == true) await onChanged();
        },
      ),
      body: ListView(children: [
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
            subtitle: Text(Uri.tryParse(r.settings['url'] ?? '')?.host ?? ''),
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
    if (_password.text.isEmpty) return 'Enter the password (an app password is best).';
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
      final a = DriveAccounts.buildWebDav(_url.text.trim(), _user.text.trim(), () async => _password.text);
      final page = await a.listChildren('test', '/');
      if (mounted) setState(() => _info = 'Connected. Found ${page.items.length} items.');
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nextcloud: use https://YOUR-SERVER/remote.php/dav/files/USERNAME/ and an app password '
              '(created in your Nextcloud security settings).'),
          const SizedBox(height: Space.m),
          TextField(key: const Key('label'), controller: _label, decoration: const InputDecoration(labelText: 'Name')),
          TextField(
              key: const Key('url'),
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Server address (https://…)')),
          TextField(key: const Key('user'), controller: _user, decoration: const InputDecoration(labelText: 'Username')),
          TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password / app password')),
          const SizedBox(height: Space.m),
          if (_error != null) Text(_error!, key: const Key('error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_info != null) Text(_info!, key: const Key('info')),
          const SizedBox(height: Space.m),
          Row(children: [
            OutlinedButton(onPressed: _busy ? null : _test, child: const Text('Test connection')),
            const SizedBox(width: Space.m),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
          ]),
        ]),
      ),
    );
  }
}
