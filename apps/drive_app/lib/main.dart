import 'dart:async';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:aethryon_host_flutter/aethryon_host_flutter.dart';
import 'package:aethryon_secure_store_flutter/aethryon_secure_store_flutter.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_store/aethryon_store.dart';
import 'package:drive_core/drive_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'accounts.dart';
import 'demo.dart';
import 'errors.dart';
import 'services.dart';

void main() {
  StartupTimer.start();
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimer.install();
  final store = FlutterSecureStore();
  final files = FlutterFilePlatform();
  runApp(DriveApp(
    services: DriveServices(
      secureStore: store,
      files: files,
      opener: FlutterUrlOpener(),
      httpClient: http.Client(),
      openDb: () => openProductionDb(store, files),
    ),
  ));
}

class DriveApp extends StatelessWidget {
  final DriveServices services;
  const DriveApp({super.key, required this.services});
  static const seed = Color(0xFF3D5AFE);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aethryon Drive',
        theme: buildAethryonTheme(seed, Brightness.light),
        darkTheme: buildAethryonTheme(seed, Brightness.dark),
        themeMode: ThemeMode.system,
        home: Shell(services: services),
      );
}

class Shell extends StatefulWidget {
  final DriveServices services;
  const Shell({super.key, required this.services});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final DriveAccounts _accounts = DriveAccounts(widget.services);
  late final JsonSettings _prefs = JsonSettings(widget.services.secureStore, 'aethryon.drive.settings');
  int _i = 0;
  List<AccountRecord> _recs = [];
  String _selected = demoAccount;
  bool _experimental = false;
  DriveDb _db = const DriveDb();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await _prefs.load();
    final db = await widget.services.openDb();
    final r = await _accounts.list();
    if (!mounted) return;
    setState(() {
      _experimental = s['experimental'] == true;
      _db = db;
      _recs = r;
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

  AccountRecord? get _selRec => _selected == demoAccount ? null : _recs.where((e) => e.id == _selected).firstOrNull;
  String get _label => _selRec?.label ?? 'Demo account (in memory)';
  String _labelFor(String id) => id == demoAccount ? 'Demo' : (_recs.where((e) => e.id == id).firstOrNull?.label ?? id);

  @override
  Widget build(BuildContext context) {
    final pages = [
      FilesScreen(
        key: ValueKey(_selected),
        adapter: _accounts.adapterFor(_selected, _recs),
        accountId: _selected,
        label: _label,
        providerId: _selRec?.kind ?? 'memory',
        store: _selected == demoAccount ? null : _db.store,
        controller: widget.services.transfers,
        files: widget.services.files,
      ),
      TransfersScreen(controller: widget.services.transfers),
      SearchScreen(store: _db.store, labelFor: _labelFor),
      AccountsScreen(
        accounts: _accounts,
        records: _recs,
        selected: _selected,
        experimental: _experimental,
        onChanged: _reload,
        onSelect: (id) => setState(() {
          _selected = id;
          _i = 0;
        }),
        onRemove: (id) async {
          await _accounts.remove(id, store: _db.store);
          await _reload();
        },
      ),
      SettingsScreen(
        experimental: _experimental,
        db: _db,
        onExperimental: (v) async {
          setState(() => _experimental = v);
          await _prefs.save({'experimental': v});
        },
      ),
    ];
    const dests = [
      (Icons.folder_outlined, Icons.folder, 'Files'),
      (Icons.swap_vert_outlined, Icons.swap_vert, 'Transfers'),
      (Icons.search_outlined, Icons.search, 'Search'),
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

class FilesScreen extends StatefulWidget {
  final StorageAdapter adapter;
  final String accountId;
  final String label;
  final String providerId;
  final DriveStore? store;
  final TransferController controller;
  final FilePlatform files;
  const FilesScreen({
    super.key,
    required this.adapter,
    required this.accountId,
    required this.label,
    required this.providerId,
    required this.store,
    required this.controller,
    required this.files,
  });
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late BrowseState _nav = BrowseState.root(widget.accountId);
  late Future<List<RemoteNode>> _future = _load();
  bool _offline = false;

  Future<List<RemoteNode>> _load() async {
    final store = widget.store;
    try {
      final nodes = sortNodes((await widget.adapter.listChildren(_nav.accountId, _nav.current)).items);
      _offline = false;
      if (store != null) {
        try {
          store.ensureAccount(widget.accountId, widget.providerId, widget.label);
          store.saveChildren(widget.accountId, _nav.current, nodes);
        } catch (_) {} // the cache is best-effort
      }
      return nodes;
    } catch (e) {
      if (store != null && store.hasListing(widget.accountId, _nav.current)) {
        _offline = true;
        return sortNodes(store.children(widget.accountId, _nav.current));
      }
      rethrow;
    }
  }

  void _go(BuildContext context, BrowseState s) => setState(() {
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
    _go(context, _nav);
    final a = widget.adapter;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(canTrash ? '"${n.name}" moved to trash' : '"${n.name}" deleted'),
      action: (canTrash && a is MemoryStorageAdapter)
          ? SnackBarAction(
              label: 'Undo',
              onPressed: () {
                a.restore(n.accountId, n.id);
                _go(context, _nav);
              })
          : null,
    ));
  }

  void _download(RemoteNode n) {
    unawaited(widget.controller.download(widget.adapter, n));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Downloading "${n.name}" — see the Transfers tab.')));
  }

  Future<void> _upload() async {
    final picked = await widget.files.pickFile();
    if (picked == null || !mounted) return;
    final parent = _nav.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading "${picked.name}" — see the Transfers tab.')));
    unawaited(() async {
      await widget.controller.upload(widget.adapter, widget.accountId, parent, picked);
      if (mounted) _go(context, _nav);
    }());
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
                onPressed: () => _go(context, _nav.pop()),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
        onPressed: _upload,
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
                    FilledButton(onPressed: () => _go(context, _nav), child: const Text('Try again')),
                  ]),
                );
              }
              final nodes = snap.data!;
              return Column(children: [
                if (_offline)
                  const MaterialBanner(
                    content: Text('Offline — showing the last saved copy of this folder.'),
                    actions: [SizedBox.shrink()],
                  ),
                Expanded(
                  child: nodes.isEmpty
                      ? const Center(child: Text('This folder is empty.'))
                      : ListView.builder(
                          itemCount: nodes.length,
                          itemBuilder: (context, i) {
                            final n = nodes[i];
                            return ListTile(
                              leading: Icon(n.isFolder ? Icons.folder : Icons.insert_drive_file_outlined),
                              title: Text(n.name),
                              subtitle: n.isFolder ? null : Text(formatBytes(n.size)),
                              onTap: n.isFolder ? () => _go(context, _nav.push(n.id)) : (_offline ? null : () => _download(n)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: canTrash ? 'Move ${n.name} to trash' : 'Delete ${n.name}',
                                onPressed: _offline ? null : () => _delete(n),
                              ),
                            );
                          },
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class TransfersScreen extends StatelessWidget {
  final TransferController controller;
  const TransfersScreen({super.key, required this.controller});

  String _text(TransferItem i) {
    switch (i.status) {
      case TransferStatus.running:
        return '${formatBytes(i.done)} of ${i.total >= 0 ? formatBytes(i.total) : 'unknown size'}';
      case TransferStatus.done:
        return i.isUpload ? 'Uploaded' : 'Saved to ${i.localPath}';
      case TransferStatus.failed:
        return 'Failed: ${i.error}';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: controller.changes,
      builder: (context, _) {
        final items = controller.items;
        return Scaffold(
          appBar: AppBar(title: const Text('Transfers'), actions: [
            IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear finished', onPressed: controller.clearFinished),
          ]),
          body: items.isEmpty
              ? const Center(child: Text('No transfers yet.'))
              : ListView(children: [
                  for (final i in items)
                    ListTile(
                      leading: Icon(i.isUpload ? Icons.upload : Icons.download),
                      title: Text(i.name),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_text(i)),
                        if (i.status == TransferStatus.running && i.total > 0)
                          LinearProgressIndicator(value: (i.done / i.total).clamp(0, 1).toDouble()),
                      ]),
                      trailing: i.status == TransferStatus.running
                          ? IconButton(icon: const Icon(Icons.close), tooltip: 'Cancel ${i.name}', onPressed: () => controller.cancel(i))
                          : null,
                    ),
                ]),
        );
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  final DriveStore? store;
  final String Function(String accountId) labelFor;
  const SearchScreen({super.key, required this.store, required this.labelFor});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<RemoteNode> _results = [];
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: store == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(Space.l),
                child: Text('Search needs the encrypted local database, which is not available right now. See Settings.',
                    textAlign: TextAlign.center),
              ),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(Space.m),
                child: TextField(
                  key: const Key('search'),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search names in folders you have opened'),
                  onChanged: (v) => setState(() {
                    _q = v;
                    _results = store.search(v);
                  }),
                ),
              ),
              Expanded(
                child: _results.isEmpty
                    ? Center(child: Text(_q.trim().isEmpty ? 'Type to search saved folder listings.' : 'Nothing found.'))
                    : ListView(children: [
                        for (final n in _results)
                          ListTile(
                            leading: Icon(n.isFolder ? Icons.folder : Icons.insert_drive_file_outlined),
                            title: Text(n.name),
                            subtitle: Text('${widget.labelFor(n.accountId)} • ${n.parentId ?? '/'}'),
                          ),
                      ]),
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

class SettingsScreen extends StatelessWidget {
  final bool experimental;
  final DriveDb db;
  final ValueChanged<bool> onExperimental;
  const SettingsScreen({super.key, required this.experimental, required this.db, required this.onExperimental});

  @override
  Widget build(BuildContext context) {
    final reg = buildDriveRegistry();
    final names = reg.providers.where((p) => p != 'gdrive_pooling').toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(Space.m), children: [
        SwitchListTile(
          key: const Key('experimental'),
          title: const Text('Show experimental providers'),
          subtitle: const Text('Dropbox and OneDrive are written but not yet verified against real accounts.'),
          value: experimental,
          onChanged: onExperimental,
        ),
        ListTile(
          title: const Text('Local storage'),
          subtitle: Text(db.store != null
              ? 'Encrypted offline cache and search are active.${db.recreated ? ' (The cache was reset.)' : ''}'
              : 'Offline cache and search are off: ${db.problem ?? 'starting…'}'),
        ),
        const DiagnosticsCard(appName: 'Aethryon Drive'),
        const Padding(padding: EdgeInsets.only(top: Space.l, bottom: Space.s), child: Text('Provider status')),
        for (final p in names)
          ListTile(
            title: Text(p),
            subtitle: Text(reg.overall(p).note ?? 'Not verified yet — disabled until tested.'),
            trailing: StatusBadge(reg.overall(p).status.name, tone: _tone(reg.overall(p).status)),
          ),
      ]),
    );
  }
}
