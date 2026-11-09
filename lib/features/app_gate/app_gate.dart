import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/security/safe_url.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launch / resume gate (OPEN_QUESTIONS #30): `GET /app-config` -> `customer.minVersion` and
/// `maintenance`. Only a successful answer ever blocks; a network or server failure lets the app on.
enum AppGateKind { none, forceUpdate, maintenance }

class AppGate {
  const AppGate(this.kind, {this.storeUrl, this.checked = false});
  static const open = AppGate(AppGateKind.none);

  final AppGateKind kind;

  /// False until the first check has answered, failed, or hit the hold cap; the host keeps the
  /// app behind a splash until then so login / home never flash before a block screen.
  final bool checked;

  AppGate get asChecked => AppGate(kind, storeUrl: storeUrl, checked: true);

  /// Store page to open. The backend does not publish one today (BACKEND_REQUESTS 55); null hides
  /// the Update button.
  final String? storeUrl;
}

/// "1.2.3", "1.2.3+45" or "1.2.3 (45)" -> [1, 2, 3, 45]; null when malformed. A missing build is -1.
List<int>? parseAppVersion(String? raw) {
  final m = RegExp(
    r'^\s*(\d+)\.(\d+)\.(\d+)(?:\s*(?:\+|\()\s*(\d+)\)?)?\s*$',
  ).firstMatch(raw ?? '');
  if (m == null) return null;
  return [
    for (var i = 1; i <= 4; i++)
      m.group(i) == null ? -1 : int.parse(m.group(i)!),
  ];
}

/// True only when both versions parse and [running] is older than [minVersion]. The build number
/// is compared only when both sides carry one.
bool isBelowMinVersion(String running, String? minVersion) {
  final r = parseAppVersion(running);
  final min = parseAppVersion(minVersion);
  if (r == null || min == null) return false;
  for (var i = 0; i < 3; i++) {
    if (r[i] != min[i]) return r[i] < min[i];
  }
  return r[3] >= 0 && min[3] >= 0 && r[3] < min[3];
}

/// "1.2.3+45" from the platform package info. Overridden in tests.
final runningVersionProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    final i = await PackageInfo.fromPlatform();
    return i.buildNumber.isEmpty ? i.version : '${i.version}+${i.buildNumber}';
  },
);

/// Reads the gate. Throws on any failure (the notifier fails open). Mock mode follows the dev flags.
final appGateFetcherProvider = Provider<Future<AppGate> Function()>((ref) {
  return () async {
    final mock = ref.read(mockApiProvider);
    if (!mock.live) {
      return mock.maintenance
          ? const AppGate(AppGateKind.maintenance)
          : mock.forceUpdate
          ? const AppGate(AppGateKind.forceUpdate)
          : AppGate.open;
    }
    final res = await ref.read(dioProvider).get<dynamic>('/app-config');
    final data = res.data;
    if (data is! Map) throw const FormatException('app-config');
    if (data['maintenance'] == true) {
      return const AppGate(AppGateKind.maintenance);
    }
    final customer = data['customer'];
    final min = customer is Map ? customer['minVersion'] : null;
    if (min is! String) return AppGate.open;
    final running = await ref.read(runningVersionProvider)();
    if (!isBelowMinVersion(running, min)) return AppGate.open;
    final url = customer is Map ? customer['storeUrl'] : null;
    // Only an https store page or a market: link is ever opened (never intent:, file:, custom schemes).
    final store = url is String
        ? parseAllowedUri(url, schemes: storeSchemes)
        : null;
    return AppGate(AppGateKind.forceUpdate, storeUrl: store?.toString());
  };
});

class AppGateNotifier extends Notifier<AppGate> {
  @override
  AppGate build() => AppGate.open;

  /// Re-reads the config. A failure keeps the last answer (open on a fresh launch). Returns false
  /// when the read failed, so Retry can say so.
  Future<bool> check() async {
    try {
      state = (await ref.read(appGateFetcherProvider)()).asChecked;
      return true;
    } on Object {
      state =
          state.asChecked; // fail open; nothing logged (no data worth keeping)
      return false;
    }
  }

  /// The first check took too long: let the app on. A late answer still blocks.
  void release() => state = state.asChecked;
}

final appGateProvider = NotifierProvider<AppGateNotifier, AppGate>(
  AppGateNotifier.new,
);

/// Opens [url] in the store app; false if it could not be opened. Overridden in tests.
final openStoreProvider = Provider<Future<bool> Function(String url)>(
  (ref) => (url) async {
    try {
      final uri = parseAllowedUri(url, schemes: storeSchemes);
      if (uri == null) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  },
);
