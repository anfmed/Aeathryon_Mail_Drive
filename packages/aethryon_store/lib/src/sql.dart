/// Splits a schema script into single statements (no reliance on multi-statement execute).
/// Full-line `--` comments are dropped; the schemas contain no `;` inside strings/comments.
List<String> splitSql(String sql) {
  final cleaned = sql
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('--'))
      .join('\n');
  return cleaned
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
