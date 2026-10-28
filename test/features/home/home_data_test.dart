// UNIT tests: Home formatting, JSON cache round trip and the mock repository's offline behaviour.
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/home_repository_mock.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final now = DateTime(2026, 10, 9, 20); // Fri 8 pm

  group('relativeWhen / startsIn', () {
    test('today, tomorrow and later dates', () {
      expect(
        relativeWhen(l10n, DateTime(2026, 10, 9, 21, 15), now),
        'Today, 9:15 PM',
      );
      expect(
        relativeWhen(l10n, DateTime(2026, 10, 10, 17, 30), now),
        'Tomorrow, 5:30 PM',
      );
      expect(
        relativeWhen(l10n, DateTime(2026, 10, 12, 9), now),
        'Mon, 12 Oct, 9:00 AM',
      );
    });

    test('countdown picks minutes, hours or days', () {
      expect(
        startsIn(l10n, now.add(const Duration(minutes: 20)), now),
        'Starts in 20 min',
      );
      expect(
        startsIn(l10n, now.add(const Duration(hours: 1)), now),
        'Starts in 1 hour',
      );
      expect(
        startsIn(l10n, now.add(const Duration(hours: 5)), now),
        'Starts in 5 hours',
      );
      expect(
        startsIn(l10n, now.add(const Duration(hours: 24)), now),
        'Starts in 1 day',
      );
      expect(
        startsIn(l10n, now.add(const Duration(days: 3)), now),
        'Starts in 3 days',
      );
      expect(
        startsIn(l10n, now.subtract(const Duration(minutes: 1)), now),
        'Starting now',
      );
    });
  });

  group('HomeData', () {
    test('JSON round trip keeps every section', () {
      final d = HomeData(
        activeBooking: const ActiveBookingSummary(
          id: 'b',
          reference: 'SN-1',
          workerName: 'Lakshmi Devi',
          service: 'Cook',
          engagement: 'Full-time',
          startLabel: 'From 8 Oct',
          stage: BookingStage.active,
        ),
        upcomingInterview: UpcomingInterview(
          id: 'i',
          workerName: 'S',
          startsAt: now,
        ),
        shortlist: const [
          ShortlistPreview(workerId: 'w', name: 'A', service: 'Cook'),
        ],
        unreadCount: 2,
      );
      final back = HomeData.fromJson(d.toJson());
      expect(back.activeBooking?.stage, BookingStage.active);
      expect(back.activeBooking?.initials, 'LD');
      expect(back.upcomingInterview?.startsAt, now);
      expect(back.shortlist.single.workerId, 'w');
      expect(back.unreadCount, 2);
      expect(back.isNewUser, isFalse);
      expect(const HomeData().isNewUser, isTrue);
    });
  });

  group('HomeRepositoryMock', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    HomeRepositoryMock repo(MockApiState Function() s) =>
        HomeRepositoryMock(s, now: () => now);

    test('returning vs new user seeds', () async {
      var s = const MockApiState(returningUser: true);
      final r = repo(() => s);
      expect((await r.fetch()).activeBooking?.reference, 'SN-2048');
      s = const MockApiState(returningUser: false);
      expect((await r.fetch()).isNewUser, isTrue);
    });

    test('error mode throws a server failure', () {
      expect(
        repo(() => const MockApiState(mode: MockMode.error)).fetch(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test(
      'offline serves the last online snapshot, flagged as cached',
      () async {
        var s = const MockApiState(returningUser: false);
        final r = repo(() => s);
        await r.fetch(); // caches the new-user snapshot
        s = const MockApiState(mode: MockMode.offline);
        final d = await r.fetch();
        expect(d.fromCache, isTrue);
        expect(d.isNewUser, isTrue);
      },
    );

    test('offline with nothing cached falls back to the seed', () async {
      final d = await repo(
        () => const MockApiState(mode: MockMode.offline, returningUser: true),
      ).fetch();
      expect(d.fromCache, isTrue);
      expect(d.activeBooking, isNotNull);
    });

    test('clearCache drops the snapshot', () async {
      final r = repo(() => const MockApiState(returningUser: false));
      await r.fetch();
      await HomeRepositoryMock.clearCache();
      final d = await repo(
        () => const MockApiState(mode: MockMode.offline, returningUser: true),
      ).fetch();
      expect(
        d.activeBooking,
        isNotNull,
      ); // seed, not the cleared new-user snapshot
    });
  });
}
