/// Turns free user text into a SAFE FTS5 prefix query: every token is quoted, so
/// operators/syntax characters typed by the user can never break (or inject into) the query.
String? ftsPrefixQuery(String raw) {
  final tokens = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true).allMatches(raw).map((m) => m[0]!).take(8).toList();
  if (tokens.isEmpty) return null;
  return tokens.map((t) => '"${t.replaceAll('"', '""')}"*').join(' ');
}
