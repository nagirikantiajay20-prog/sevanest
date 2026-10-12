import 'dart:convert';

import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheKey = 'home_cache_v1';

/// Seeded Home aggregate behind the mock-API toggle. Online fetches refresh the offline cache;
/// offline serves the cache (or the seed when nothing was ever cached) flagged `fromCache`.
class HomeRepositoryMock implements HomeRepository {
  HomeRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MockApiState Function() _state;
  final DateTime Function() _now;

  HomeData _seed(bool returning) {
    if (!returning) return const HomeData(unreadCount: 1);
    final tomorrow = _now().add(const Duration(days: 1));
    return HomeData(
      activeBooking: const ActiveBookingSummary(
        id: 'bk_2048',
        reference: 'SN-2048',
        workerName: 'Lakshmi Devi',
        service: 'Cook',
        engagement: 'Full-time',
        startLabel: 'From 8 Oct',
        stage: BookingStage.trial,
      ),
      upcomingInterview: UpcomingInterview(
        id: 'iv_301',
        workerName: 'Sunita R.',
        startsAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17, 30),
      ),
      shortlist: const [
        ShortlistPreview(workerId: 'w_1', name: 'Anita K.', service: 'Cook'),
        ShortlistPreview(workerId: 'w_2', name: 'Ramesh P.', service: 'Driver'),
      ],
      unreadCount: 3,
    );
  }

  @override
  Future<HomeData> fetch() async {
    final s = _state();
    if (s.mode == MockMode.offline) {
      await Future<void>.delayed(s.latency);
      final cached = await _readCache();
      return (cached ?? _seed(s.returningUser)).asCached();
    }
    final data = await mockCall(
      s,
      () =>
          s.mode == MockMode.empty ? const HomeData() : _seed(s.returningUser),
    );
    await _writeCache(data);
    return data;
  }

  Future<HomeData?> _readCache() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_cacheKey);
      if (raw == null) return null;
      return HomeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> _writeCache(HomeData d) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _cacheKey,
        jsonEncode(d.toJson()),
      );
    } on Object {
      // A cache write failure must never break Home.
    }
  }

  /// Logout / delete account clears the cache (module 12).
  static Future<void> clearCache() async =>
      (await SharedPreferences.getInstance()).remove(_cacheKey);
}
