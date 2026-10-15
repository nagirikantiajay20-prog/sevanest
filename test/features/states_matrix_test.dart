// Module 11.3: loading / error / offline for the screens backed by the mock repositories, driven by
// the same MockMode the dev menu flips. Screens with their own fakes are covered in their module
// tests (see the table in docs/PROGRESS.md).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

import '../helpers/discover_harness.dart';

const _routes = [
  '/bookings',
  '/bookings/bk_2100',
  '/favourites',
  '/interviews',
  '/interviews/iv_301',
  '/transactions',
  '/services/history',
  '/services/current',
  '/workers/cook-2',
  '/workers',
  '/workers/cook-2/reviews',
];

void main() {
  for (final mode in [MockMode.loading, MockMode.error, MockMode.offline]) {
    for (final route in _routes) {
      testWidgets('${mode.name}: $route', (t) async {
        final env = await launchDiscover(t, height: 1400);
        env.container
            .read(mockApiProvider.notifier)
            .set(env.container.read(mockApiProvider).copyWith(mode: mode));
        if (route == '/workers') env.stepsOneToThree(EngagementType.fullTime);
        env.unawaitedPush(route);
        // No pumpAndSettle: a loading screen may animate for as long as it waits.
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        final l10n = AppLocalizations.of(
          t.element(find.byType(Scaffold).first),
        );
        final retry = find.textContaining(RegExp('Retry|Try again'));
        switch (mode) {
          case MockMode.loading:
            expect(
              find.bySemanticsLabel(l10n.loading).evaluate().length +
                  find.byType(CircularProgressIndicator).evaluate().length,
              greaterThan(0),
              reason: 'a skeleton or spinner, never a blank page',
            );
          case MockMode.error:
            expect(retry, findsWidgets);
          case MockMode.offline:
            expect(retry, findsWidgets);
            expect(
              find.textContaining(
                RegExp('offline|connection|internet', caseSensitive: false),
              ),
              findsWidgets,
            );
          case _:
            break;
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 5));
      });
    }
  }
}
