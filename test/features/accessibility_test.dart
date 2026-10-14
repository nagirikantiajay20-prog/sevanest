// Module 11.2: text scale 1.3, 44 dp tap targets and spoken labels on the Account rows and the
// notification centre rows (added in modules 10 and 14).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';

import '../helpers/discover_harness.dart';
import '../helpers/fakes.dart';
import '../helpers/notification_fakes.dart';

Finder k(String key) => find.byKey(Key(key));

void _scale(WidgetTester t) {
  t.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets(
    'Account at text scale 1.3: no overflow, rows >= 44 dp, labelled',
    (t) async {
      _scale(t);
      final handle = t.ensureSemantics();
      final env = await launchDiscover(
        t,
        height: 1800,
        profiles: FakeProfileRepository(
          const CustomerProfile(
            name: 'Asha Rao',
            email: 'asha@example.com',
            preferredLanguage: 'en',
            mobile: '+919999900002',
            verificationStatus: 'VERIFIED',
          ),
        ),
      );
      await env.tapKey('nav_account');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      for (final key in [
        'account_profile_btn',
        'account_addresses_btn',
        'account_favourites_btn',
        'account_bookings_btn',
        'account_interviews_btn',
        'account_history_btn',
        'account_transactions_btn',
        'account_support_btn',
        'account_notifications_btn',
      ]) {
        expect(k(key), findsOneWidget, reason: key);
        expect(t.getSize(k(key)).height, greaterThanOrEqualTo(44), reason: key);
        expect(t.getSemantics(k(key)).label, isNotEmpty, reason: key);
      }
      handle.dispose();
    },
  );

  testWidgets(
    'Notification centre at text scale 1.3: no overflow, rows labelled',
    (t) async {
      _scale(t);
      final handle = t.ensureSemantics();
      final repo = FakeNotificationRepository([
        notif(
          'n1',
          title: 'Interview confirmed with a long title that wraps',
          type: 'interview',
          entity: 'iv_301',
          at: DateTime(2026, 10, 9, 8),
        ),
      ])..unreadFails = false;
      final env = await launchDiscover(t, height: 1400, notifications: repo);
      await env.go('/notifications');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final row = find.textContaining('Interview confirmed');
      expect(row, findsOneWidget);
      expect(t.getSemantics(row).label, contains('Interview confirmed'));
      final tile = find.ancestor(of: row, matching: find.byType(InkWell)).first;
      expect(t.getSize(tile).height, greaterThanOrEqualTo(44));
      handle.dispose();
    },
  );
}
