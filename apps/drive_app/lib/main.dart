import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_secure_store_flutter/aethryon_secure_store_flutter.dart';
import 'package:drive_core/drive_core.dart';
import 'package:flutter/material.dart';

import 'accounts.dart';
import 'demo.dart';

void main() => runApp(DriveApp(secureStore: FlutterSecureStore()));

class DriveApp extends StatelessWidget {
  final SecureStore secureStore;
  const DriveApp({super.key, required this.secureStore});
  static const seed = Color(0xFF3D5AFE);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aethryon Drive',
        theme: buildAethryonTheme(seed, Brightness.light),
        darkTheme: buildAethryonTheme(seed, Brightness.dark),
        themeMode: ThemeMode.system,
        home: Shell(accounts: DriveAccounts(secureStore)),
      );
}

class Shell extends StatefulWidget {
  final DriveAccounts accounts;
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
      if (_selected != demoAccount && !r.any((x) => x.id == _selected)) _selected = demoAccount;
    });
  }

  String get _label =>
      _selected == demoAccount ? 'Demo account (in memory)' : _recs.firstWhere((e) => e.id == _selected).label;

  @override
  Widget build(BuildContext context) {
    final pages = [
      FilesScreen(
        key: ValueKey(_selected),
        adapter: widget.accounts.adapterFor(_selected, _recs),
        accountId: _selected,
        label: _label,
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
      const ProvidersScreen(),
    ];
    const dests = [
      (Icons.folder_outlined, Icons.folder, 'Files'),
      (Icons.manage_accounts_outlined, Icons.manage_accounts, 'Accounts'),
      (Icons.cloud_outlined, Icons.cloud, 'Providers'),
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

class FilesScreen extends StatefulWidget {
  final StorageAdapter adapter;
  final String accountId;
  final String label;
  const FilesScreen({super.key, required this.adapter, required this.accountId, required this.label});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late BrowseState _nav = BrowseState.root(widget.accountId);
  late Future<List<RemoteNode>> _future = _load();

  Future<List<RemoteNode>> _load() async =>
      sortNodes((await widget.adapter.listChildren(_nav.accountId, _nav.current)).items);

  void _go(BrowseState s) => setState(() {
        _nav = s;
        _future = _load();
      });

  Future<void> _delete(RemoteNode n) async {
    final canTrash = widget.adapter.capability(DriveFeature.trash).enabledInUi;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(canTrash ? 'Move "${n.name}" to trash?' : 'Delete "${n.name}" permanently?'),
        content: Text(canTrash
            ? 'You can restore it right after from the undo button.'
            : 'This server has no trash for this app. The deletion cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(canTrash ? 'Move to trash' : 'Delete permanently')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (canTrash) {
        await widget.adapter.trash(n.accountId, n.id);
      } else {
        await widget.adapter.permanentDelete(n.accountId, n.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(explainError(e))));
      return;
    }
    if (!mounted) return;
    _go(_nav);
    final a = widget.adapter;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(canTrash ? '"${n.name}" moved to trash' : '"${n.name}" deleted'),
      action: (canTrash && a is MemoryStorageAdapter)
          ? SnackBarAction(
              label: 'Undo',
              onPressed: () {
                a.restore(n.accountId, n.id);
                _go(_nav);
              })
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canTrash = widget.adapter.capability(DriveFeature.trash).enabledInUi;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aethryon Drive'),
        leading: _nav.atRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Up one folder',
                onPressed: () => _go(_nav.pop()),
              ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(Space.m),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${widget.label} • ${_nav.current}', style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<RemoteNode>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(explainError(snap.error!), textAlign: TextAlign.center),
                    const SizedBox(height: Space.s),
                    FilledButton(onPressed: () => _go(_nav), child: const Text('Try again')),
                  ]),
                );
              }
              final nodes = snap.data!;
              if (nodes.isEmpty) return const Center(child: Text('This folder is empty.'));
              return ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, i) {
                  final n = nodes[i];
                  return ListTile(
                    leading: Icon(n.isFolder ? Icons.folder : Icons.insert_drive_file_outlined),
                    title: Text(n.name),
                    subtitle: n.isFolder ? null : Text(formatBytes(n.size)),
                    onTap: n.isFolder ? () => _go(_nav.push(n.id)) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: canTrash ? 'Move ${n.name} to trash' : 'Delete ${n.name}',
                      onPressed: () => _delete(n),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

Tone _tone(CapabilityStatus s) => switch (s) {
      CapabilityStatus.full => Tone.good,
      CapabilityStatus.partial => Tone.warn,
      CapabilityStatus.unverified => Tone.neutral,
      _ => Tone.bad,
    };

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final reg = buildDriveRegistry();
    final names = reg.providers.where((p) => p != 'gdrive_pooling').toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: ListView.separated(
        itemCount: names.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = reg.overall(names[i]);
          return ListTile(
            title: Text(names[i]),
            subtitle: Text(c.note ?? 'Not verified yet — disabled until tested.'),
            trailing: StatusBadge(c.status.name, tone: _tone(c.status)),
          );
        },
      ),
    );
  }
}
