import 'package:flutter/material.dart';

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
