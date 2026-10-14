import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// `GET /app-config` -> `legal.terms.url`, `legal.privacy.url`, `languages`. Null URLs mean the
/// document is not published yet (OPEN_QUESTIONS #17).
class AccountConfig {
  const AccountConfig({
    this.termsUrl,
    this.privacyUrl,
    this.languages = const ['en'],
  });

  final String? termsUrl;
  final String? privacyUrl;
  final List<String> languages;
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
    return u is String && Uri.tryParse(u.trim())?.hasScheme == true
        ? u.trim()
        : null;
  }

  final legal = data['legal'];
  final langs = data['languages'];
  return AccountConfig(
    termsUrl: url(legal is Map ? legal['terms'] : null),
    privacyUrl: url(legal is Map ? legal['privacy'] : null),
    languages: langs is List && langs.isNotEmpty
        ? [for (final l in langs) l.toString()]
        : const ['en'],
  );
});

/// Opens [url] in an in-app browser; false if it could not be opened. Overridden in tests.
final openInAppBrowserProvider = Provider<Future<bool> Function(String url)>(
  (ref) => (url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } on Object {
      return false;
    }
  },
);
