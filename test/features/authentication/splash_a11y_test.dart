// Splash / welcome screen: the "Worker App" footer link on small phones and large text, and the
// WCAG contrast of the splash text colours (computed from the real colour values).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

import '../../helpers/fakes.dart';
import '../../helpers/real_fonts.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [fg] painted at its own alpha over an opaque [bg].
Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void main() {
  setUpAll(loadRealFonts);
  group('Worker App footer link', () {
    Future<void> launch(
      WidgetTester t, {
      required Size size,
      double scale = 1,
    }) async {
      t.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        // Status bar and gesture bar, 24 dp each, like a real phone.
        ..padding = const FakeViewPadding(top: 72, bottom: 72)
        ..viewPadding = const FakeViewPadding(top: 72, bottom: 72);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.view.reset();
        t.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore(),
          repo: FakeAuthRepository(),
          splashChoice: true,
        ),
      );
      // The logo's height comes from the decoded image: decode it before measuring.
      await t.runAsync(
        () => precacheImage(
          const AssetImage('assets/splash/logo.webp'),
          t.element(find.byType(Scaffold).first),
        ),
      );
      await t.pumpAndSettle();
    }

    final link = find.byKey(const Key('splash_worker_btn'));
    final cta = find.byKey(const Key('splash_customer_btn'));

    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(393, 852),
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: on screen (scrolling only '
        'under 600 dp), no overflow, >= 48 dp, labelled',
        (t) async {
          await launch(t, size: size);
          expect(t.takeException(), isNull);
          // 568 dp phones (older small devices) scroll to it; 640 dp and taller show it at once.
          if (size.height < 600) {
            await t.ensureVisible(link);
            await t.pump();
          }
          final box = t.getRect(link);
          expect(box.height, greaterThanOrEqualTo(kMinTapTarget));
          expect(box.width, greaterThanOrEqualTo(kMinTapTarget));
          final screen = Rect.fromLTRB(0, 24, size.width, size.height - 24);
          expect(
            screen.contains(box.topLeft) && screen.contains(box.bottomRight),
            isTrue,
            reason: 'link $box inside the $size screen',
          );
          // Get Started stays above it and also on screen.
          expect(t.getRect(cta).bottom, lessThanOrEqualTo(box.top));
          final handle = t.ensureSemantics();
          expect(
            t.getSemantics(link),
            matchesSemantics(
              label: 'Worker App',
              isButton: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true,
              hasEnabledState: true,
              isEnabled: true,
            ),
          );
          handle.dispose();
        },
      );
    }

    testWidgets('1.3x text on a 360x640 phone: no overflow, reachable', (
      t,
    ) async {
      await launch(t, size: const Size(360, 640), scale: 1.3);
      expect(t.takeException(), isNull);
      await t.ensureVisible(link);
      await t.pump();
      expect(t.getRect(link).height, greaterThanOrEqualTo(kMinTapTarget));
      await t.tap(link);
      await t.pumpAndSettle();
      // No link configured: the app says so instead of opening something made up.
      expect(find.textContaining('Worker app link'), findsOneWidget);
    });
  });

  group('Splash text contrast (WCAG 2.1 AA)', () {
    const surface = AppColors.surface;
    const cream = AppColors.whiteFBF9F6;
    const gray = AppColors.grayF4EFE8;
    final backdrops = {'white': surface, 'cream': cream, 'F4EFE8': gray};

    test('tagline, caption, trust row and link on the plain backdrop', () {
      for (final e in backdrops.entries) {
        // 26 sp bold serif is "large text" (3:1); the rest is normal text (4.5:1).
        expect(_ratio(AppColors.navyDeep, e.value), greaterThanOrEqualTo(4.5));
        expect(_ratio(AppColors.teal, e.value), greaterThanOrEqualTo(4.5));
        expect(_ratio(AppColors.slate600, e.value), greaterThanOrEqualTo(4.5));
      }
    });

    test(
      'the version label uses slate600: slate400 fails on the F4EFE8 end',
      () {
        expect(_ratio(AppColors.slate400, gray), lessThan(4.5));
        expect(_ratio(AppColors.slate600, gray), greaterThanOrEqualTo(4.5));
      },
    );

    test(
      'the plate under the tagline holds even over a pure black photo pixel',
      () {
        final worst = _over(AppColors.whiteA90xE6, const Color(0xFF000000));
        expect(_ratio(AppColors.navyDeep, worst), greaterThanOrEqualTo(4.5));
        // The teal accent ("your home") is 26 sp bold: large text, 3:1.
        expect(_ratio(AppColors.teal, worst), greaterThanOrEqualTo(3));
        expect(_ratio(AppColors.slate600, worst), greaterThanOrEqualTo(4.5));
      },
    );
  });
}
