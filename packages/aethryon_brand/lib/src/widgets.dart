import 'package:aethryon_brand_core/aethryon_brand_core.dart';
import 'package:aethryon_design/aethryon_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services.dart';

const _logoAsset = 'assets/branding/aethryon_labs_logo.png';

/// The official logo (never regenerated or recoloured). It has a light background, so it sits on
/// a white rounded tile — that keeps it faithful in dark theme too.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 120});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Aethryon Labs logo',
        image: true,
        child: ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.12),
            child: Container(
              color: Colors.white,
              width: size,
              height: size,
              child: Image.asset(
                _logoAsset,
                package: 'aethryon_brand',
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const Center(child: Text('Aethryon Labs')),
              ),
            ),
          ),
        ),
      );
}

/// Company and developer credits — two separate identities, extendable with more developers.
class CreditsBlock extends StatelessWidget {
  final Credits credits;
  const CreditsBlock({super.key, this.credits = aethryonCredits});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final label = t.labelSmall?.copyWith(letterSpacing: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('DEVELOPED BY', style: label),
      const SizedBox(height: Space.xs),
      Text(credits.organization, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: Space.m),
      Text(credits.developers.length == 1 ? 'DEVELOPER' : 'DEVELOPERS', style: label),
      const SizedBox(height: Space.xs),
      for (final d in credits.developers) Text(d, style: t.titleSmall),
    ]);
  }
}

class _VersionText extends StatelessWidget {
  final AppInfo info;
  const _VersionText(this.info);
  @override
  Widget build(BuildContext context) => FutureBuilder<AppVersion>(
        future: info.load(),
        builder: (context, s) => Text(s.hasData ? 'Version ${s.data!.display}' : 'Version …',
            style: Theme.of(context).textTheme.bodySmall),
      );
}

Future<void> showWelcomeDialog(BuildContext context, BrandServices s) =>
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => WelcomeDialog(services: s));

/// First-launch welcome. Friendly and roomy (the About screen is deliberately more compact).
class WelcomeDialog extends StatelessWidget {
  final BrandServices services;
  const WelcomeDialog({super.key, required this.services});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.m),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Welcome!', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: Space.s),
        Text('Thank You for Choosing Our App', style: t.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: Space.m),
        Text(
          "We're delighted to have you here! We hope you enjoy using the app and find it helpful. "
          "Your experience matters to us, and we'd love to hear your thoughts after you've had a chance to explore it.",
          style: t.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xl),
        const BrandLogo(size: 128),
        const SizedBox(height: Space.l),
        const CreditsBlock(),
        const SizedBox(height: Space.m),
        _VersionText(services.info),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: Space.l),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.symmetric(horizontal: Space.xl), child: Text('Get Started'))),
      ],
    );
  }
}

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Compact About screen.
class AboutScreen extends StatelessWidget {
  final BrandServices services;
  const AboutScreen({super.key, required this.services});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await openLink(services.opener, url);
    if (!ok && context.mounted) _snack(context, 'Could not open the link.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandLogo(size: 96),
                const SizedBox(height: Space.l),
                const CreditsBlock(),
                const SizedBox(height: Space.m),
                _VersionText(services.info),
                const SizedBox(height: Space.xl),
                Wrap(spacing: Space.m, runSpacing: Space.s, alignment: WrapAlignment.center, children: [
                  FilledButton.icon(
                    key: const Key('about_get_in_touch'),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Get In Touch'),
                    onPressed: () => _open(context, services.links.links.getInTouchUrl),
                  ),
                  OutlinedButton.icon(
                    key: const Key('about_support'),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Support'),
                    onPressed: () => _open(context, services.links.links.supportUrl),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
}

/// Small, highlighted Support button for an unused AppBar corner. Colour comes from the theme's
/// accent (tertiary) palette; it opens the SAME centrally configured support URL as About.
class SupportButton extends StatelessWidget {
  final BrandServices services;
  const SupportButton({super.key, required this.services});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: Space.xs),
      child: FilledButton.tonalIcon(
        key: const Key('support_button'),
        icon: const Icon(Icons.support_agent, size: 18),
        label: const Text('Support'),
        style: FilledButton.styleFrom(
          backgroundColor: cs.tertiaryContainer,
          foregroundColor: cs.onTertiaryContainer,
          // 48dp is the accessibility minimum; the semantics node itself must be that tall
          // (compact density made it 40dp and failed the tap-target guideline in CI).
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
        ),
        onPressed: () async {
          final ok = await openLink(services.opener, services.links.links.supportUrl);
          if (!ok && context.mounted) _snack(context, 'Could not open the link.');
        },
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  final BrandServices services;
  const FeedbackScreen({super.key, required this.services});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _message = TextEditingController();
  final _contact = TextEditingController();
  String _category = 'general';
  bool _sending = false;
  String? _status;
  bool _statusIsError = false;

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final problem = FeedbackClient.validateMessage(_message.text);
    if (problem != null) return setState(() {
      _status = problem;
      _statusIsError = true;
    });
    setState(() {
      _sending = true;
      _status = null;
    });
    final version = (await widget.services.info.load()).version;
    final outcome = await widget.services.feedback.send(
      message: _message.text,
      category: _category,
      contact: _contact.text,
      appVersion: version,
      platform: defaultTargetPlatform.name.toLowerCase(),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      switch (outcome) {
        case FeedbackOutcome.sent:
          _message.clear(); // only a successful send clears the text
          _status = 'Thank you! Your feedback was sent.';
          _statusIsError = false;
        case FeedbackOutcome.rateLimited:
          _status = 'You are sending feedback too quickly. Please wait a minute and try again. Your text is kept.';
          _statusIsError = true;
        case FeedbackOutcome.invalid:
          _status = 'The server did not accept this feedback. Please check the text and try again.';
          _statusIsError = true;
        case FeedbackOutcome.notConfigured:
          _status = 'Feedback is not set up in this build.';
          _statusIsError = true;
        case FeedbackOutcome.failed:
          _status = 'Could not send. Your text is kept — please try again.';
          _statusIsError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DropdownButtonFormField<String>(
            key: const Key('category'),
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in feedbackCategories) DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))],
            onChanged: (v) => setState(() => _category = v ?? 'general'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            key: const Key('message'),
            controller: _message,
            minLines: 5,
            maxLines: 10,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Your feedback', alignLabelWithHint: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: Space.s),
          TextField(
            key: const Key('contact'),
            controller: _contact,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'How can we reach you? (optional)'),
          ),
          const SizedBox(height: Space.s),
          const Text('Nothing else is sent — no device ID, no IP address.'),
          const SizedBox(height: Space.m),
          if (_status != null) Text(_status!, key: const Key('status'), style: TextStyle(color: _statusIsError ? cs.error : cs.primary)),
          const SizedBox(height: Space.m),
          FilledButton(onPressed: _sending ? null : _send, child: Text(_sending ? 'Sending…' : 'Send')),
        ]),
      ),
    );
  }
}
