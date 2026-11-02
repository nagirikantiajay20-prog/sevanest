import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/engagement_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('week sketch draws seven visible bars', (t) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DiscoverClock(
          clock: ValueNotifier<double>(100000),
          child: Scaffold(
            body: EngagementCard(
              index: 0,
              option: const EngagementOption(EngagementType.fullTime),
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final bars = t
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .length;
    expect(bars, 7);
    for (final e in t.elementList(find.byType(FractionallySizedBox))) {
      final size = (e.renderObject! as RenderBox).size;
      expect(size.width, greaterThan(10));
      expect(size.height, greaterThanOrEqualTo(4));
    }
  });
}
