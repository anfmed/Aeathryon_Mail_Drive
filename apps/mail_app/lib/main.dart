import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_host_flutter/aethryon_host_flutter.dart';
import 'package:aethryon_net/aethryon_net.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_secure_store_flutter/aethryon_secure_store_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mail_core/mail_core.dart';

import 'accounts.dart';
import 'demo.dart';
import 'services.dart';

void main() {
  StartupTimer.start();
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimer.install();
  final store = FlutterSecureStore();
  final files = FlutterFilePlatform();
  runApp(MailApp(
    services: MailServices(
      secureStore: store,
      files: files,
      opener: FlutterUrlOpener(),
      httpClient: http.Client(),
      openDb: () => openProductionDb(store, files),
    ),
  ));
}

class MailApp extends StatelessWidget {
  final MailServices services;
  const MailApp({super.key, required this.services});
  static const seed = Color(0xFF00897B);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aethryon Mail',
        theme: buildAethryonTheme(seed, Brightness.light),
        darkTheme: buildAethryonTheme(seed, Brightness.dark),
        themeMode: ThemeMode.system,
        home: Shell(services: services),
      );
}

class Shell extends StatefulWidget {
  final MailServices services;
  const Shell({super.key, required this.services});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final MailAccounts _accounts = MailAccounts(widget.services);
  late final JsonSettings _prefs = JsonSettings(widget.services.secureStore, 'aethryon.mail.settings');
  int _i = 0;
  bool _ready = false;
  List<AccountRecord> _recs = [];
  String _selected = demoAccount;
  int _autoRefreshMinutes = 0;
  MailDb _db = const MailDb();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await _prefs.load();
    final db = await widget.services.openDb(); // sessions are built only AFTER the DB state is known
    final r = await _accounts.list();
    if (!mounted) return;
    setState(() {
      _autoRefreshMinutes = (s['autoRefreshMinutes'] as int?) ?? 0;
      _db = db;
      _recs = r;
      _ready = true;
    });
  }

  Future<void> _reload() async {
    final r = await _accounts.list();
    if (!mounted) return;
    setState(() {
      _recs = r;
      if (_selected != demoAccount && !r.any((x) => x.id == _selected)) _selected = demoAccount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = _accounts.sessionFor(_selected, _recs, _db);
    final pages = [
      InboxScreen(
        key: ValueKey(_selected),
        accountId: _selected,
        session: session,
        autoRefreshMinutes: _autoRefreshMinutes,
      ),
      AccountsScreen(
        accounts: _accounts,
        records: _recs,
        selected: _selected,
        onChanged: _reload,
        onSelect: (id) => setState(() {
          _selected = id;
          _i = 0;
        }),
        onRemove: (id) async {
          await _accounts.remove(id, _db);
          await _reload();
        },
      ),
      SettingsScreen(
        autoRefreshMinutes: _autoRefreshMinutes,
        db: _db,
        onAutoRefresh: (m) async {
          setState(() => _autoRefreshMinutes = m);
          await _prefs.save({'autoRefreshMinutes': m});
        },
      ),
    ];
    const dests = [
      (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
      (Icons.manage_accounts_outlined, Icons.manage_accounts, 'Accounts'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];
    return LayoutBuilder(builder: (context, c) {
      final body = IndexedStack(index: _i, children: pages);
      if (c.maxWidth >= 840) {
        return Scaffold(
          body: Row(children: [
            NavigationRail(
              selectedIndex: _i,
              onDestinationSelected: (v) => setState(() => _i = v),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in dests)
                  NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ]),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: [
            for (final d in dests)
              NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        ),
      );
    });
  }
}

class _InboxData {
  final List<HeaderInfo> list;
  final bool offline;
  const _InboxData(this.list, this.offline);
}

class InboxScreen extends StatefulWidget {
  final String accountId;
  final MailSession session;
  final int autoRefreshMinutes;
  const InboxScreen({super.key, required this.accountId, required this.session, required this.autoRefreshMinutes});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<_InboxData> _future = _load();
  PollScheduler? _poll;
  AppLifecycleListener? _life;

  MailSyncService get _svc => MailSyncService(widget.session.transport, widget.session.store);

  Future<_InboxData> _load() async {
    final store = widget.session.store;
    try {
      await _svc.syncFolder(widget.accountId, 'INBOX');
      return _InboxData(await store.headers(widget.accountId, 'INBOX'), false);
    } catch (e) {
      final cached = await store.headers(widget.accountId, 'INBOX');
      if (cached.isNotEmpty) return _InboxData(cached, true); // offline: show what we saved
      rethrow;
    }
  }

  void _setupPoll() {
    _poll?.stop();
    _poll = null;
    final m = widget.autoRefreshMinutes;
    if (m <= 0) return;
    _poll = PollScheduler(
      interval: Duration(minutes: m),
      task: () async {
        await _svc.syncFolder(widget.accountId, 'INBOX');
        final list = await widget.session.store.headers(widget.accountId, 'INBOX');
        if (mounted) setState(() => _future = Future.value(_InboxData(list, false)));
      },
    )..start();
  }

  @override
  void initState() {
    super.initState();
    _setupPoll();
    // No background service: polling only while the app is in the foreground.
    _life = AppLifecycleListener(onStateChange: (s) {
      if (s == AppLifecycleState.resumed) {
        _poll?.start();
      } else {
        _poll?.stop();
      }
    });
  }

  @override
  void didUpdateWidget(InboxScreen old) {
    super.didUpdateWidget(old);
    if (old.autoRefreshMinutes != widget.autoRefreshMinutes) _setupPoll();
  }

  @override
  void dispose() {
    _poll?.stop();
    _life?.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aethryon Mail'), actions: [
        IconButton(icon: const Icon(Icons.refresh), tooltip: 'Check for new mail', onPressed: _refresh),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ComposeScreen(transport: widget.session.transport, fromAddress: widget.session.fromAddress))),
      ),
      body: FutureBuilder<_InboxData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not check for mail.\nCheck the server names, ports and sign-in details.', textAlign: TextAlign.center),
                const SizedBox(height: Space.s),
                FilledButton(onPressed: _refresh, child: const Text('Try again')),
              ]),
            );
          }
          final data = snap.data!;
          final list = data.list;
          final threads = threadHeaders(list);
          return Column(children: [
            if (data.offline)
              const MaterialBanner(
                content: Text('Offline — showing mail saved on this device.'),
                actions: [SizedBox.shrink()],
              ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Your inbox is empty.'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final h = list[i];
                        final inThread = threads.values.where((t) => t == threads[h.uid]).length > 1;
                        return ListTile(
                          title: Text(h.subject, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: h.flags.contains('seen') ? null : const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: inThread ? const Text('Conversation') : null,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => MessageScreen(transport: widget.session.transport, header: h, offline: data.offline))),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class MessageScreen extends StatefulWidget {
  final MailTransport transport;
  final HeaderInfo header;
  final bool offline;
  const MessageScreen({super.key, required this.transport, required this.header, required this.offline});
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late Future<String> _future = _load();

  Future<String> _load() async {
    if (widget.offline) throw StateError('offline');
    final b = await widget.transport.fetchBody('INBOX', widget.header.uid);
    final t = b.text;
    // Plain text only: no HTML engine, no scripts, no remote images (tracking pixels never load).
    return (t != null && t.trim().isNotEmpty) ? t : htmlToPlainText(b.html ?? '');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.header.subject, overflow: TextOverflow.ellipsis)),
        body: FutureBuilder<String>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.offline ? 'You are offline. The message text is not saved on this device.' : 'Could not load this message.',
                      textAlign: TextAlign.center),
                  if (!widget.offline) ...[
                    const SizedBox(height: Space.s),
                    FilledButton(onPressed: () => setState(() => _future = _load()), child: const Text('Try again')),
                  ],
                ]),
              );
            }
            return SingleChildScrollView(padding: const EdgeInsets.all(Space.l), child: SelectableText(snap.data!));
          },
        ),
      );
}

class ComposeScreen extends StatefulWidget {
  final MailTransport transport;
  final String fromAddress;
  const ComposeScreen({super.key, required this.transport, required this.fromAddress});
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
    final to = _to.text.split(',').map((e) => e.trim()).where((e) => e.contains('@')).toList();
    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one valid recipient.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.transport.sendPlain(
          fromName: widget.fromAddress, fromAddress: widget.fromAddress, to: to, subject: _subject.text, body: _body.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send the message. Nothing was sent.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Compose'), actions: [
          IconButton(icon: const Icon(Icons.send), tooltip: 'Send', onPressed: _sending ? null : _send),
        ]),
        body: ListView(padding: const EdgeInsets.all(Space.l), children: [
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'To'), keyboardType: TextInputType.emailAddress),
          TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject')),
          TextField(controller: _body, decoration: const InputDecoration(labelText: 'Message'), minLines: 6, maxLines: null),
        ]),
      );
}

Tone _tone(CapabilityStatus s) => switch (s) {
      CapabilityStatus.full => Tone.good,
      CapabilityStatus.partial => Tone.warn,
      CapabilityStatus.unverified => Tone.neutral,
      _ => Tone.bad,
    };

class SettingsScreen extends StatelessWidget {
  final int autoRefreshMinutes;
  final MailDb db;
  final ValueChanged<int> onAutoRefresh;
  const SettingsScreen({super.key, required this.autoRefreshMinutes, required this.db, required this.onAutoRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(Space.m), children: [
        ListTile(
          title: const Text('Check for new mail automatically'),
          subtitle: const Text('Only while the app is open. There is no background service (saves battery).'),
          trailing: DropdownButton<int>(
            key: const Key('autorefresh'),
            value: autoRefreshMinutes,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Off')),
              DropdownMenuItem(value: 5, child: Text('Every 5 min')),
              DropdownMenuItem(value: 15, child: Text('Every 15 min')),
              DropdownMenuItem(value: 30, child: Text('Every 30 min')),
            ],
            onChanged: (v) => onAutoRefresh(v ?? 0),
          ),
        ),
        ListTile(
          title: const Text('Local storage'),
          subtitle: Text(db.store != null
              ? 'Encrypted mail-header cache is active (message text is never saved).${db.recreated ? ' (The cache was reset.)' : ''}'
              : 'Offline mail is off: ${db.problem ?? 'starting…'}'),
        ),
        const DiagnosticsCard(appName: 'Aethryon Mail'),
        const Padding(padding: EdgeInsets.only(top: Space.l, bottom: Space.s), child: Text('Provider status')),
        for (final p in profiles)
          ListTile(
            title: Text(p.displayName),
            subtitle: Text(p.userNote ?? p.overall.note ?? ''),
            trailing: StatusBadge(p.overall.status.name, tone: _tone(p.overall.status)),
          ),
      ]),
    );
  }
}
