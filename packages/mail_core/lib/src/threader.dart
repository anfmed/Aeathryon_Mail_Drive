class MsgRef {
  final String key; // local unique id
  final String? messageId;
  final String? inReplyTo;
  final List<String> references;
  const MsgRef({required this.key, this.messageId, this.inReplyTo, this.references = const []});
}

/// Local threading from Message-ID / In-Reply-To / References (union-find).
/// Deliberately NO subject-based merging (avoids false merges).
/// Returns: message key -> thread id (smallest Message-ID in the component,
/// falling back to the message key if it has no Message-ID and no links).
Map<String, String> buildThreads(List<MsgRef> msgs) {
  final parent = <String, String>{};
  String find(String x) {
    var r = x;
    while (parent[r] != r) {
      r = parent[r]!;
    }
    var c = x;
    while (parent[c] != r) {
      final n = parent[c]!;
      parent[c] = r;
      c = n;
    }
    return r;
  }

  void add(String x) => parent.putIfAbsent(x, () => x);
  void union(String a, String b) {
    add(a);
    add(b);
    final ra = find(a), rb = find(b);
    if (ra == rb) return;
    // deterministic root: lexicographically smaller wins
    if (ra.compareTo(rb) < 0) {
      parent[rb] = ra;
    } else {
      parent[ra] = rb;
    }
  }

  String node(MsgRef m) => m.messageId != null ? 'm:${_norm(m.messageId!)}' : 'k:${m.key}';

  for (final m in msgs) {
    final n = node(m);
    add(n);
    final links = <String>[
      ...m.references,
      if (m.inReplyTo != null) m.inReplyTo!,
    ];
    for (final l in links) {
      final ln = 'm:${_norm(l)}';
      union(n, ln);
    }
    // adjacent references chain together (parent->child), keeps siblings joined
    for (var i = 0; i + 1 < m.references.length; i++) {
      union('m:${_norm(m.references[i])}', 'm:${_norm(m.references[i + 1])}');
    }
  }
  return {for (final m in msgs) m.key: find(node(m))};
}

String _norm(String id) => id.trim().replaceAll(RegExp(r'^<|>$'), '').toLowerCase();
