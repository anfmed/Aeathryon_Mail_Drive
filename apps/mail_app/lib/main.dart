import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_secure_store_flutter/aethryon_secure_store_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mail_core/mail_core.dart';

import 'accounts.dart';
import 'demo.dart';

void main() => runApp(MailApp(secureStore: FlutterSecureStore()));

class MailApp extends StatelessWidget {
  final SecureStore secureStore;
  const MailApp({super.key, required this.secureStore});
  static const seed = Color(0xFF00897B);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aethryon Mail',
    theme: buildAethryonTheme(seed, Brightness.light),
    darkTheme: buildAethryonTheme(seed, Brightness.dark),
    themeMode: ThemeMode.system,
    home: Shell(accounts: MailAccounts(secureStore)),
  );
}

class Shell extends StatefulWidget {
  final MailAccounts accounts;
  const Shell({super.key, required this.accounts});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  List<AccountRecord> _recs = [];
  String _selected = demoAccount;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final r = await widget.accounts.list();
    if (!mounted) return;
    setState(() {
      _recs = r;
      if (_selected != demoAccount && !r.any((x) => x.id == _selected))
        _selected = demoAccount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.accounts.sessionFor(_selected, _recs);
    final pages = [
      InboxScreen(
        key: ValueKey(_selected),
        accountId: _selected,
        session: session,
        isDemo: _selected == demoAccount,
      ),
      AccountsScreen(
        records: _recs,
        selected: _selected,
        vault: widget.accounts.vault,
        onChanged: _reload,
        onSelect: (id) => setState(() {
          _selected = id;
          _i = 0;
        }),
        onRemove: (id) async {
          await widget.accounts.remove(id);
          await _reload();
        },
      ),
      const ProfilesScreen(),
    ];
    const dests = [
      (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
      (Icons.manage_accounts_outlined, Icons.manage_accounts, 'Accounts'),
      (Icons.dns_outlined, Icons.dns, 'Providers'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final body = IndexedStack(index: _i, children: pages);
        if (c.maxWidth >= 840) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _i,
                  onDestinationSelected: (v) => setState(() => _i = v),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in dests)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$3),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _i,
            onDestinationSelected: (v) => setState(() => _i = v),
            destinations: [
              for (final d in dests)
                NavigationDestination(
                  icon: Icon(d.$1),
                  selectedIcon: Icon(d.$2),
                  label: d.$3,
                ),
            ],
          ),
        );
      },
    );
  }
}

class InboxScreen extends StatefulWidget {
  final String accountId;
  final MailSession session;
  final bool isDemo;
  const InboxScreen({
    super.key,
    required this.accountId,
    required this.session,
    required this.isDemo,
  });
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<HeaderInfo>> _future = _sync();

  Future<List<HeaderInfo>> _sync() async {
    await MailSyncService(
      widget.session.transport,
      widget.session.store,
    ).syncFolder(widget.accountId, 'INBOX');
    return widget.session.store.headers(widget.accountId, 'INBOX');
  }

  void _refresh() => setState(() => _future = _sync());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aethryon Mail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check for new mail',
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComposeScreen(
              transport: widget.session.transport,
              fromAddress: widget.session.fromAddress,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<HeaderInfo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not check for mail.\nCheck the server names, ports and app password.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.s),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          final list = snap.data!;
          if (list.isEmpty)
            return const Center(child: Text('Your inbox is empty.'));
          final threads = threadHeaders(list);
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final h = list[i];
              final inThread =
                  threads.values.where((t) => t == threads[h.uid]).length > 1;
              return ListTile(
                title: Text(
                  h.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: inThread ? const Text('Conversation') : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MessageScreen(
                      header: h,
                      html: widget.isDemo ? (demoBodies[h.uid] ?? '') : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  final HeaderInfo header;
  final String?
  html; // null = body download not implemented for this account type yet
  const MessageScreen({super.key, required this.header, required this.html});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(header.subject, overflow: TextOverflow.ellipsis),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(Space.l),
      // Plain text only: no HTML engine, no scripts, no remote images.
      child: SelectableText(
        html == null
            ? 'Message body download is not implemented yet. Only the subject line is shown.'
            : htmlToPlainText(html!),
      ),
    ),
  );
}

class ComposeScreen extends StatefulWidget {
  final MailTransport transport;
  final String fromAddress;
  const ComposeScreen({
    super.key,
    required this.transport,
    required this.fromAddress,
  });
  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _to = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _to.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.contains('@'))
        .toList();
    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid recipient.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.transport.sendPlain(
        fromName: widget.fromAddress,
        fromAddress: widget.fromAddress,
        to: to,
        subject: _subject.text,
        body: _body.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the message. Nothing was sent.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Compose'),
      actions: [
        IconButton(
          icon: const Icon(Icons.send),
          tooltip: 'Send',
          onPressed: _sending ? null : _send,
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        TextField(
          controller: _to,
          decoration: const InputDecoration(labelText: 'To'),
          keyboardType: TextInputType.emailAddress,
        ),
        TextField(
          controller: _subject,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        TextField(
          controller: _body,
          decoration: const InputDecoration(labelText: 'Message'),
          minLines: 6,
          maxLines: null,
        ),
      ],
    ),
  );
}

Tone _tone(CapabilityStatus s) => switch (s) {
  CapabilityStatus.full => Tone.good,
  CapabilityStatus.partial => Tone.warn,
  CapabilityStatus.unverified => Tone.neutral,
  _ => Tone.bad,
};

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Providers')),
    body: ListView.separated(
      itemCount: profiles.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = profiles[i];
        return ListTile(
          title: Text(p.displayName),
          subtitle: Text(p.userNote ?? p.overall.note ?? ''),
          trailing: StatusBadge(
            p.overall.status.name,
            tone: _tone(p.overall.status),
          ),
        );
      },
    ),
  );
}
