import 'dart:async';
import 'dart:io';

/// Desktop OAuth redirect receiver (RFC 8252 loopback). Binds 127.0.0.1 only.
/// Mobile redirect handling (custom scheme / app links) is NOT implemented yet.
class LoopbackReceiver {
  final HttpServer _server;
  LoopbackReceiver._(this._server);

  static Future<LoopbackReceiver> start() async =>
      LoopbackReceiver._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  Future<void> close() => _server.close(force: true);

  Uri get redirectUri =>
      Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: '/callback');

  Future<Map<String, String>> waitForCallback({Duration timeout = const Duration(minutes: 5)}) async {
    final done = Completer<Map<String, String>>();
    final sub = _server.listen((req) async {
      if (req.uri.path == '/callback' && !done.isCompleted) {
        done.complete(Map.of(req.uri.queryParameters));
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><body>You can close this window and return to the app.</body></html>');
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
    try {
      return await done.future.timeout(timeout);
    } finally {
      await sub.cancel();
      await _server.close(force: true);
    }
  }
}
