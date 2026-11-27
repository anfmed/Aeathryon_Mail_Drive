import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const feedbackCategories = ['general', 'bug', 'idea', 'praise', 'other'];

enum FeedbackOutcome { sent, rateLimited, invalid, notConfigured, failed }

/// POST <AUS>/v1/feedback  (contract supplied by the project owner).
/// Sends NO device id, IP or other personal data.
class FeedbackClient {
  final String baseUrl;
  final String appId;
  final http.Client _client;
  final Duration timeout;
  FeedbackClient({
    required this.baseUrl,
    required this.appId,
    required http.Client client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client;

  bool get configured => baseUrl.trim().isNotEmpty && appId.trim().isNotEmpty;

  /// null = OK, otherwise a human-readable problem.
  static String? validateMessage(String message) {
    final n = message.trim().length;
    if (n < 3) return 'Please write at least 3 characters.';
    if (n > 2000) return 'Please keep it under 2000 characters.';
    return null;
  }

  Future<FeedbackOutcome> send({
    required String message,
    required String category,
    String contact = '',
    required String appVersion,
    required String platform,
  }) async {
    if (!configured) return FeedbackOutcome.notConfigured;
    if (validateMessage(message) != null ||
        !feedbackCategories.contains(category) ||
        contact.trim().length > 200) {
      return FeedbackOutcome.invalid;
    }
    final b = baseUrl.trim();
    final uri = Uri.parse(
      b.endsWith('/') ? '${b}v1/feedback' : '$b/v1/feedback',
    );
    final body = <String, Object>{
      'source': appId,
      'message': message.trim(),
      'category': category,
      if (contact.trim().isNotEmpty) 'contact': contact.trim(),
      'appVersion': appVersion,
      'platform': platform,
      'website':
          '', // anti-spam honeypot field required by the contract: always empty
    };
    try {
      final r = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      if (r.statusCode == 202 || r.statusCode == 200 || r.statusCode == 201)
        return FeedbackOutcome.sent;
      if (r.statusCode == 429) return FeedbackOutcome.rateLimited;
      if (r.statusCode == 400 || r.statusCode == 422)
        return FeedbackOutcome.invalid;
      return FeedbackOutcome.failed;
    } catch (_) {
      return FeedbackOutcome.failed;
    }
  }
}
