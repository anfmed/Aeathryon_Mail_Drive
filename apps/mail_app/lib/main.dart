import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:flutter/material.dart';
import 'package:mail_core/mail_core.dart';

import 'demo.dart';

void main() => runApp(const MailApp());

class MailApp extends StatelessWidget {
  const MailApp({super.key});
  static const seed = Color(0xFF00897B);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aethryon Mail',
        theme: buildAethryonTheme(seed, Brightness.light),
        darkTheme: buildAethryonTheme(seed, Brightness.dark),
        themeMode: ThemeMode.system,
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  final MemoryMailTransport _transport = buildDemoTransport();
  final MemoryMailStore _store = MemoryMailStore();

  @override
  Widget build(BuildContext context) {
    final pages = [
      InboxScreen(transport: _transport, store: _store),
      const ProfilesScreen(),
    ];
    const dests = [
      (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
      (Icons.dns_outlined, Icons.dns, 'Providers'),
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

class InboxScreen extends StatefulWidget {
  final MemoryMailTransport transport;
  final MemoryMailStore store;
  const InboxScreen({super.key, required this.transport, required this.store});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<HeaderInfo>> _future = _sync();

  Future<List<HeaderInfo>> _sync() async {
    await MailSyncService(widget.transport, widget.store).syncFolder(demoAccount, 'INBOX');
    return widget.store.headers(demoAccount, 'INBOX');
  }

  void _refresh() => setState(() => _future = _sync());

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
            builder: (_) => ComposeScreen(transport: widget.transport))),
      ),
      body: FutureBuilder<List<HeaderInfo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not check for mail.'),
                const SizedBox(height: Space.s),
                FilledButton(onPressed: _refresh, child: const Text('Try again')),
              ]),
            );
          }
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Your inbox is empty.'));
          final threads = threadHeaders(list);
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final h = list[i];
              final inThread = threads.values.where((t) => t == threads[h.uid]).length > 1;
              return ListTile(
                title: Text(h.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: inThread ? const Text('Conversation') : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => MessageScreen(header: h, html: demoBodies[h.uid] ?? ''))),
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
  final String html;
  const MessageScreen({super.key, required this.header, required this.html});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(header.subject, overflow: TextOverflow.ellipsis)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.l),
          // Plain text only: no HTML engine, no scripts, no remote images.
          child: SelectableText(htmlToPlainText(html)),
        ),
      );
}

class ComposeScreen extends StatefulWidget {
  final MemoryMailTransport transport;
  const ComposeScreen({super.key, required this.transport});
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
          fromName: 'Demo', fromAddress: 'demo@example.invalid', to: to, subject: _subject.text, body: _body.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send. Saved to outbox to retry.')));
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
              trailing: StatusBadge(p.overall.status.name, tone: _tone(p.overall.status)),
            );
          },
        ),
      );
}
