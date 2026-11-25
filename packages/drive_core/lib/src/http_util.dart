import 'package:aethryon_net/aethryon_net.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

FailureKind classifyProviderError(Object e) => e is ProviderHttpError
    ? classifyStatus(e.statusCode)
    : FailureKind.transient;

/// Builds a FRESH request for every attempt (bodies are never replayed from a
/// consumed stream), reads the full response, retries per [policy].
/// Error messages carry only method+path+status — never response bodies/tokens.
Future<http.Response> sendBuffered(
  http.Client client,
  RetryPolicy policy,
  http.BaseRequest Function() build,
) => retry<http.Response>(
  policy: policy,
  classify: classifyProviderError,
  retryAfterOf: (e) =>
      e is ProviderHttpError ? parseRetryAfter(e.retryAfterHeader) : null,
  op: () async {
    final req = build();
    final r = await http.Response.fromStream(await client.send(req));
    if (r.statusCode >= 400) {
      throw ProviderHttpError(
        r.statusCode,
        '${req.method} ${req.url.path}',
        retryAfterHeader: r.headers['retry-after'],
      );
    }
    return r;
  },
);

/// Single streaming attempt (downloads). Error bodies are drained.
Future<http.StreamedResponse> sendStreaming(
  http.Client client,
  http.BaseRequest req,
) async {
  final r = await client.send(req);
  if (r.statusCode >= 400) {
    final ra = r.headers['retry-after'];
    await r.stream.drain<void>();
    throw ProviderHttpError(
      r.statusCode,
      '${req.method} ${req.url.path}',
      retryAfterHeader: ra,
    );
  }
  return r;
}
