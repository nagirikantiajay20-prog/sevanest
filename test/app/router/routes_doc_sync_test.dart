import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/router/routes.dart';

/// Guards against undocumented screens: every route constant must appear in the navigation map doc
/// (docs/modules/15_navigation_map_and_functional_flows.md, NAV-05).
void main() {
  test('every Routes constant is documented', () {
    final doc = File(
      'docs/modules/15_navigation_map_and_functional_flows.md',
    ).readAsStringSync();
    const paths = [
      Routes.splash,
      Routes.login,
      Routes.otp,
      Routes.profileSetup,
      Routes.home,
      Routes.bookings,
      Routes.favourites,
      Routes.account,
      Routes.addressNew,
      Routes.discoverCategory,
      Routes.discoverEngagement,
      Routes.discoverReview,
      Routes.workers,
      Routes.workerDetail,
      Routes.interviewNew,
      Routes.interviewDetail,
      Routes.bookingConfirm,
      Routes.bookingDetail,
      Routes.payment,
      Routes.transactions,
      Routes.transactionDetail,
      Routes.serviceCurrent,
      Routes.serviceHistory,
      Routes.rating,
      Routes.replacementNew,
      Routes.replacementDetail,
      Routes.support,
      Routes.supportNew,
      Routes.supportDetail,
      Routes.notifications,
    ];
    final missing = paths.where((p) => !doc.contains(p)).toList();
    expect(missing, isEmpty);
  });

  test('path() fills params and encodes them', () {
    expect(Routes.path(Routes.bookingDetail, {'id': '7'}), '/bookings/7');
    expect(Routes.path(Routes.workerDetail, {'id': 'a b'}), '/workers/a%20b');
  });
}
