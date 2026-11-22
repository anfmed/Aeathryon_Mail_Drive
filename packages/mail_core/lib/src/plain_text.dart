/// HTML -> plain text. SAFE BY DESIGN: the output is only ever shown as text
/// (never re-interpreted as markup), so there is no HTML/JS execution surface and
/// no remote resource is ever fetched. It is NOT an HTML sanitizer.
String htmlToPlainText(String html) {
  var s = html;
  s = s.replaceAll(
    RegExp(
      r'<(script|style|head)[^>]*>.*?</\1\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  s = s.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(
    RegExp(r'</(p|div|tr|li|h[1-6]|blockquote)\s*>', caseSensitive: false),
    '\n',
  );
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = _decodeEntities(s);
  s = s.replaceAll(RegExp(r'[ \t\u00A0]+'), ' ');
  s = s.replaceAll(RegExp(r' ?\n ?'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

String _decodeEntities(String s) {
  const named = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
  };
  var out = s.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m[2]!, radix: m[1]!.isEmpty ? 10 : 16);
    if (code == null ||
        code < 1 ||
        code > 0x10FFFF ||
        (code >= 0xD800 && code <= 0xDFFF)) {
      return '';
    }
    return String.fromCharCode(code);
  });
  named.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}
