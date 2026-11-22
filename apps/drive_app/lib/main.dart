import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:drive_core/drive_core.dart';
import 'package:flutter/material.dart';

import 'demo.dart';

void main() => runApp(const DriveApp());

class DriveApp extends StatelessWidget {
  const DriveApp({super.key});
  static const seed = Color(0xFF3D5AFE);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aethryon Drive',
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
  final MemoryStorageAdapter _adapter = buildDemoAdapter();

  @override
  Widget build(BuildContext context) {
    final pages = [FilesScreen(adapter: _adapter), const ProvidersScreen()];
    const dests = [
      (Icons.folder_outlined, Icons.folder, 'Files'),
      (Icons.cloud_outlined, Icons.cloud, 'Providers'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide =
            c.maxWidth >= 840; // expanded layout: rail instead of bottom bar
        final body = IndexedStack(index: _i, children: pages);
        if (wide) {
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

class FilesScreen extends StatefulWidget {
  final MemoryStorageAdapter adapter;
  const FilesScreen({super.key, required this.adapter});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  BrowseState _nav = BrowseState.root(demoAccount);
  late Future<List<RemoteNode>> _future = _load();

  Future<List<RemoteNode>> _load() async => sortNodes(
    (await widget.adapter.listChildren(_nav.accountId, _nav.current)).items,
  );

  void _go(BrowseState s) => setState(() {
    _nav = s;
    _future = _load();
  });

  Future<void> _trash(RemoteNode n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Move "${n.name}" to trash?'),
        content: const Text(
          'You can restore it right after from the undo button.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.adapter.trash(n.accountId, n.id);
    if (!mounted) return;
    _go(_nav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${n.name}" moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.adapter.restore(n.accountId, n.id);
            _go(_nav);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.m),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Demo account (in memory) • ${_nav.current}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RemoteNode>>(
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
                        const Text('Could not load this folder.'),
                        const SizedBox(height: Space.s),
                        FilledButton(
                          onPressed: () => _go(_nav),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                final nodes = snap.data!;
                if (nodes.isEmpty)
                  return const Center(child: Text('This folder is empty.'));
                return ListView.builder(
                  itemCount: nodes.length,
                  itemBuilder: (context, i) {
                    final n = nodes[i];
                    return ListTile(
                      leading: Icon(
                        n.isFolder
                            ? Icons.folder
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(n.name),
                      subtitle: n.isFolder ? null : Text(formatBytes(n.size)),
                      onTap: n.isFolder ? () => _go(_nav.push(n.id)) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Move ${n.name} to trash',
                        onPressed: () => _trash(n),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
    final names = reg.providers.where((p) => p != 'gdrive_pooling').toList()
      ..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: ListView.separated(
        itemCount: names.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = reg.overall(names[i]);
          return ListTile(
            title: Text(names[i]),
            subtitle: Text(
              c.note ?? 'Not verified yet — disabled until tested.',
            ),
            trailing: StatusBadge(c.status.name, tone: _tone(c.status)),
          );
        },
      ),
    );
  }
}
