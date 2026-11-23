import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mail_core/mail_core.dart';
import 'package:mail_imap/mail_imap.dart';

import 'demo.dart';

class MailSession {
  final MailTransport transport;
  final MailStore store;
  final String fromAddress;
  MailSession(this.transport, this.store, this.fromAddress);
}

class MailAccounts {
  final AccountVault vault;
  final Map<String, MailSession> _sessions = {};
  MailAccounts(SecureStore store)
    : vault = AccountVault(store, 'aethryon.mail');

  Future<List<AccountRecord>> list() => vault.list();

  MailSession demoSession() => _sessions.putIfAbsent(
    demoAccount,
    () => MailSession(
      buildDemoTransport(),
      MemoryMailStore(),
      'demo@example.invalid',
    ),
  );

  MailSession sessionFor(String id, List<AccountRecord> records) {
    if (id == demoAccount) return demoSession();
    final r = records.firstWhere((e) => e.id == id);
    return _sessions.putIfAbsent(id, () {
      final s = r.settings;
      final transport = ImapSmtpTransport(
        ImapSmtpConfig(
          imapHost: s['imapHost']!,
          imapPort: int.parse(s['imapPort']!),
          smtpHost: s['smtpHost']!,
          smtpPort: int.parse(s['smtpPort']!),
          smtpSecure: s['smtpSecure'] == 'true',
          username: s['username']!,
        ),
        () async =>
            (await vault.secret(id)) ??
            '', // password is read only at connect time
      );
      return MailSession(transport, MemoryMailStore(), s['username']!);
    });
  }

  Future<void> remove(String id) async {
    _sessions.remove(id);
    await vault.remove(id);
  }
}

bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

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
          'This only removes the account from this device. Your mailbox is not touched.',
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
              builder: (_) => AddMailScreen(vault: vault),
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
        ],
      ),
    );
  }
}

class AddMailScreen extends StatefulWidget {
  final AccountVault vault;
  const AddMailScreen({super.key, required this.vault});
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
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _label,
      _user,
      _imapHost,
      _imapPort,
      _smtpHost,
      _smtpPort,
      _password,
    ]) {
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

  String? _validate() {
    if (_label.text.trim().isEmpty) return 'Give this account a name.';
    if (!_user.text.contains('@'))
      return 'Enter the full e-mail address as the username.';
    if (_imapHost.text.trim().isEmpty || _smtpHost.text.trim().isEmpty)
      return 'Enter the IMAP and SMTP server names.';
    if (int.tryParse(_imapPort.text) == null ||
        int.tryParse(_smtpPort.text) == null)
      return 'Ports must be numbers.';
    if (_password.text.isEmpty) return 'Enter the app password.';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await widget.vault.save(
      AccountRecord(
        id: id,
        kind: 'imap',
        label: _label.text.trim(),
        settings: {
          'profile': _profile.id,
          'username': _user.text.trim(),
          'imapHost': _imapHost.text.trim(),
          'imapPort': _imapPort.text.trim(),
          'smtpHost': _smtpHost.text.trim(),
          'smtpPort': _smtpPort.text.trim(),
          'smtpSecure': '${_smtpPort.text.trim() == '465'}',
        },
      ),
      secret: _password.text, // OS secure store only
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = connectBlockedReason(_profile, isMobile: isMobilePlatform);
    return Scaffold(
      appBar: AppBar(title: const Text('Add mail account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('profile'),
              initialValue: _profile.id,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                for (final p in profiles)
                  DropdownMenuItem(value: p.id, child: Text(p.displayName)),
              ],
              onChanged: (v) => _pick(profileById(v!)!),
            ),
            if (_profile.userNote != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text(_profile.userNote!),
              ),
            if (!_profile.hostsVerified && _profile.imap != null)
              const Padding(
                padding: EdgeInsets.only(top: Space.s),
                child: Text(
                  'These server names are suggestions — please confirm them with your provider.',
                ),
              ),
            if (blocked != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.m),
                child: Text(
                  blocked,
                  key: const Key('blocked'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextField(
              key: const Key('label'),
              controller: _label,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              key: const Key('user'),
              controller: _user,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail address (username)',
              ),
            ),
            TextField(
              key: const Key('imapHost'),
              controller: _imapHost,
              decoration: const InputDecoration(labelText: 'IMAP server'),
            ),
            TextField(
              key: const Key('imapPort'),
              controller: _imapPort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'IMAP port (SSL)'),
            ),
            TextField(
              key: const Key('smtpHost'),
              controller: _smtpHost,
              decoration: const InputDecoration(labelText: 'SMTP server'),
            ),
            TextField(
              key: const Key('smtpPort'),
              controller: _smtpPort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SMTP port (465 = SSL)',
              ),
            ),
            TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'App password'),
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
              onPressed: blocked == null ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
