/// Status vocabulary (Phase 0: PROVIDER_COMPATIBILITY_MATRIX.md).
/// STATUS: written without a Dart toolchain; validated only by CI (see docs/).
enum CapabilityStatus {
  full,
  partial,
  unsupported,
  requiresPermission,
  requiresCompanion,
  temporarilyUnavailable,
  unverified,
}

enum Evidence { primary, secondary, none }

class Capability {
  final CapabilityStatus status;
  final Evidence evidence;
  final List<String> sources;
  final String? note;

  const Capability._(this.status, this.evidence, this.sources, this.note);

  /// FULL is only constructible with at least one source id (primary evidence).
  factory Capability.full({required List<String> sources, String? note}) {
    if (sources.isEmpty) {
      throw ArgumentError('FULL requires at least one primary source id');
    }
    return Capability._(
        CapabilityStatus.full, Evidence.primary, List.unmodifiable(sources), note);
  }

  const Capability.partial(
      {Evidence evidence = Evidence.secondary,
      List<String> sources = const [],
      String? note})
      : this._(CapabilityStatus.partial, evidence, sources, note);

  const Capability.unsupported({List<String> sources = const [], String? note})
      : this._(CapabilityStatus.unsupported, Evidence.primary, sources, note);

  const Capability.requiresPermission(
      {List<String> sources = const [], String? note})
      : this._(CapabilityStatus.requiresPermission, Evidence.primary, sources, note);

  const Capability.requiresCompanion(
      {List<String> sources = const [], String? note})
      : this._(CapabilityStatus.requiresCompanion, Evidence.primary, sources, note);

  const Capability.unverified({String? note})
      : this._(CapabilityStatus.unverified, Evidence.none, const [], note);

  /// UI may enable the action. UNVERIFIED / UNSUPPORTED / REQUIRES_* never do.
  bool get enabledInUi =>
      status == CapabilityStatus.full || status == CapabilityStatus.partial;
}

class CapabilityRegistry {
  final Map<String, Map<String, Capability>> _byProvider = {};
  final Map<String, Capability> _overall = {};

  void register(String provider, Map<String, Capability> features,
      {required Capability overall}) {
    _byProvider[provider] = Map.of(features);
    _overall[provider] = overall;
  }

  Capability overall(String provider) =>
      _overall[provider] ?? const Capability.unverified(note: 'not registered');

  Capability lookup(String provider, String feature) =>
      _byProvider[provider]?[feature] ??
      const Capability.unverified(note: 'feature not registered');

  /// Runtime probe result wins over the static manifest.
  void applyProbe(String provider, String feature, Capability probed) {
    (_byProvider[provider] ??= {})[feature] = probed;
  }

  Iterable<String> get providers => _byProvider.keys;
}
