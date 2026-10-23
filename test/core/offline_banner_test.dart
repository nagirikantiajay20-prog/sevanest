import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/widgets/offline_banner.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

Widget _app(bool online) => ProviderScope(
  key: ValueKey(online),
  overrides: [onlineProvider.overrideWith((ref) => Stream.value(online))],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: OfflineBannerHost(child: Scaffold(body: Text('page'))),
  ),
);

void main() {
  testWidgets('the banner shows only while offline', (t) async {
    await t.pumpWidget(_app(false));
    await t.pump();
    expect(find.byKey(const Key('offline_banner')), findsOneWidget);
    expect(find.text('page'), findsOneWidget);

    await t.pumpWidget(_app(true));
    await t.pump();
    expect(find.byKey(const Key('offline_banner')), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });
}
