import 'package:aethryon_brand_core/aethryon_brand_core.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:http/http.dart' as http;

/// Everything the branding UI needs, built once at startup.
class BrandServices {
  final LinkConfigService links;
  final UrlOpener opener;
  final AppInfo info;
  final FeedbackClient feedback;
  const BrandServices({required this.links, required this.opener, required this.info, required this.feedback});

  /// [ausBaseUrl] / [appId] normally come from `--dart-define=AUS_BASE_URL=…` / `AUS_APP_ID=…`
  /// (empty AUS url = links stay on defaults/cache and feedback reports "not set up").
  factory BrandServices.create({
    required SecureStore store,
    required UrlOpener opener,
    required http.Client httpClient,
    required AppInfo info,
    required String linksCacheKey,
    required String ausBaseUrl,
    required String appId,
  }) =>
      BrandServices(
        links: LinkConfigService(cache: JsonSettings(store, linksCacheKey), client: httpClient, baseUrl: ausBaseUrl),
        opener: opener,
        info: info,
        feedback: FeedbackClient(baseUrl: ausBaseUrl, appId: appId, client: httpClient),
      );

  /// Background, failure-tolerant: cached links first, then one throttled refresh.
  Future<void> start() async {
    await links.init();
    await links.refresh();
  }
}
