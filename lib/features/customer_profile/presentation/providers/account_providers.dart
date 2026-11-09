import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/security/safe_url.dart';
import 'package:url_launcher/url_launcher.dart';

/// `GET /app-config` -> `legal.terms.url`, `legal.privacy.url`, `languages`. Null URLs mean the
/// document is not published yet (OPEN_QUESTIONS #17).
/// `GET /app-config` -> `policy` (Q-114). Every field is null until the client approves the text.
class PolicyConfig {
  const PolicyConfig({
    this.cancellationText,
    this.cancellationUrl,
    this.refundText,
    this.refundUrl,
  });

  final String? cancellationText;
  final String? cancellationUrl;
  final String? refundText;
  final String? refundUrl;

  /// False while nothing is configured: the policy link stays hidden.
  bool get isEmpty =>
      cancellationText == null &&
      cancellationUrl == null &&
      refundText == null &&
      refundUrl == null;

  static PolicyConfig from(Object? json) {
    String? s(String k) {
      final v = json is Map ? json[k] : null;
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    String? url(String k) {
      final v = s(k);
      return parseAllowedUri(v)?.toString();
    }

    return PolicyConfig(
      cancellationText: s('cancellationText'),
      cancellationUrl: url('cancellationUrl'),
      refundText: s('refundText'),
      refundUrl: url('refundUrl'),
    );
  }
}

class AccountConfig {
  const AccountConfig({
    this.termsUrl,
    this.privacyUrl,
    this.languages = const ['en'],
    this.policy = const PolicyConfig(),
  });

  final String? termsUrl;
  final String? privacyUrl;
  final List<String> languages;
  final PolicyConfig policy;
}

final accountConfigProvider = FutureProvider.autoDispose<AccountConfig>((
  ref,
) async {
  if (!ref.watch(mockApiProvider.select((s) => s.live))) {
    return const AccountConfig();
  }
  final res = await ref.read(dioProvider).get<dynamic>('/app-config');
  final data = res.data;
  if (data is! Map) return const AccountConfig();
  String? url(Object? doc) {
    final u = doc is Map ? doc['url'] : null;
    return u is String ? parseAllowedUri(u)?.toString() : null;
  }

  final legal = data['legal'];
  final langs = data['languages'];
  return AccountConfig(
    termsUrl: url(legal is Map ? legal['terms'] : null),
    privacyUrl: url(legal is Map ? legal['privacy'] : null),
    languages: langs is List && langs.isNotEmpty
        ? [for (final l in langs) l.toString()]
        : const ['en'],
    policy: PolicyConfig.from(data['policy']),
  );
});

/// Opens [url] in an in-app browser; false if it could not be opened. Overridden in tests.
final openInAppBrowserProvider = Provider<Future<bool> Function(String url)>(
  (ref) => (url) async {
    try {
      final uri = parseAllowedUri(url);
      if (uri == null) return false;
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } on Object {
      return false;
    }
  },
);

/// "1.2.3 (45)" from the platform package info (pubspec `version`). Overridden in tests.
final appVersionProvider = FutureProvider.autoDispose<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});
