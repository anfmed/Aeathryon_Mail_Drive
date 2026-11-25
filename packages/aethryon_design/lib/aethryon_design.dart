import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Space {
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 24;
}

/// Same language for both apps; each app passes its own seed colour.
ThemeData buildAethryonTheme(Color seed, Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: seed,
  brightness: brightness,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // restrained motion: no fancy page transitions beyond platform defaults
  listTileTheme: const ListTileThemeData(minVerticalPadding: 6),
);

enum Tone { neutral, good, warn, bad }

/// Status is conveyed by text + icon, never by colour alone (accessibility).
class StatusBadge extends StatelessWidget {
  final String label;
  final Tone tone;
  const StatusBadge(this.label, {super.key, this.tone = Tone.neutral});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = switch (tone) {
      Tone.good => (Icons.check_circle_outline, cs.primary),
      Tone.warn => (Icons.info_outline, cs.tertiary),
      Tone.bad => (Icons.block, cs.error),
      Tone.neutral => (Icons.help_outline, cs.outline),
    };
    return Semantics(
      label: 'Status: $label',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: Space.xs),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Startup/memory diagnostics so the owner can measure P-01/P-02/P-03 on a real device.
/// First-frame time is measured from main() (excludes engine start); use
/// docs/MEASUREMENT_PROTOCOL.md for true cold-start numbers.
class StartupTimer {
  static final Stopwatch _sw = Stopwatch();
  static int? firstFrameMs;
  static void start() => _sw.start();
  static void install() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => firstFrameMs ??= _sw.elapsedMilliseconds,
    );
  }
}

String diagnosticsText(String appName) {
  String mb(int b) => (b / (1024 * 1024)).toStringAsFixed(0);
  var rss = 'n/a';
  try {
    rss =
        'now ${mb(ProcessInfo.currentRss)} MB, peak ${mb(ProcessInfo.maxRss)} MB';
  } catch (_) {}
  return '$appName diagnostics\n'
      'First frame (from main): ${StartupTimer.firstFrameMs ?? 'n/a'} ms\n'
      'Memory (RSS): $rss\n'
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
}

class DiagnosticsCard extends StatefulWidget {
  final String appName;
  const DiagnosticsCard({super.key, required this.appName});
  @override
  State<DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<DiagnosticsCard> {
  @override
  Widget build(BuildContext context) {
    final text = diagnosticsText(widget.appName);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnostics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Space.s),
            SelectableText(text),
            const SizedBox(height: Space.s),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: Space.s),
                OutlinedButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                  child: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
