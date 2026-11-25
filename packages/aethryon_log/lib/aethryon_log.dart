class Redactor {
  static final _bearer =
      RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);
  static final _kv = RegExp(
      r'(access_token|refresh_token|id_token|password|passwd|client_secret|code|authorization)=([^&\s"]+)',
      caseSensitive: false);
  static final _json = RegExp(
      r'"(access_token|refresh_token|id_token|password|client_secret)"\s*:\s*"[^"]*"',
      caseSensitive: false);
  static final _email = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
  static final _opaque = RegExp(r'\b[A-Za-z0-9_\-]{32,}\b');

  static String redact(String input) {
    var s = input;
    s = s.replaceAll(_bearer, 'Bearer [REDACTED]');
    s = s.replaceAllMapped(_kv, (m) => '${m[1]}=[REDACTED]');
    s = s.replaceAllMapped(_json, (m) => '"${m[1]}":"[REDACTED]"');
    s = s.replaceAll(_email, '[EMAIL]');
    s = s.replaceAll(_opaque, '[OPAQUE]');
    return s;
  }
}

enum LogLevel { debug, info, warn, error }

class RedactingLogger {
  final void Function(String line) sink;
  final LogLevel min;
  const RedactingLogger(this.sink, {this.min = LogLevel.info});

  void log(LogLevel level, String message) {
    if (level.index < min.index) return;
    sink('[${level.name}] ${Redactor.redact(message)}');
  }
}
