import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Categories in the settings sheet. ponytail: kept on the device and applied to the in-app
/// banner only (the backend has no preference endpoint, BACKEND_REQUESTS 53); system
/// notifications stay under the phone's own settings.
const notificationCategories = [
  'bookings',
  'payments',
  'replacements',
  'support',
];

/// The category a route from `routeForNotification` belongs to, or null (always shown).
String? notificationCategoryOfRoute(String route) {
  if (route.startsWith('/bookings') || route.startsWith('/interviews')) {
    return 'bookings';
  }
  if (route.startsWith('/payments') || route.startsWith('/transactions')) {
    return 'payments';
  }
  if (route.startsWith('/replacements')) return 'replacements';
  if (route.startsWith('/support')) return 'support';
  return null;
}

/// Categories the customer switched off.
class MutedCategories extends AsyncNotifier<Set<String>> {
  static const _key = 'notif_muted_categories';

  @override
  Future<Set<String>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? const []).toSet();
    } on Object {
      return {}; // unreadable storage: nothing is muted
    }
  }

  Future<void> setEnabled(String category, {required bool enabled}) async {
    final next = {
      ...await future,
    }; // wait for the first load so it cannot overwrite us
    enabled ? next.remove(category) : next.add(category);
    state = AsyncData(next);
    try {
      await (await SharedPreferences.getInstance()).setStringList(
        _key,
        next.toList(),
      );
    } on Object {
      // kept for this run only
    }
  }
}

final mutedCategoriesProvider =
    AsyncNotifierProvider<MutedCategories, Set<String>>(MutedCategories.new);

/// True when a push route should show the in-app banner.
bool bannerAllowed(Set<String> muted, String route) {
  final c = notificationCategoryOfRoute(route);
  return c == null || !muted.contains(c);
}
