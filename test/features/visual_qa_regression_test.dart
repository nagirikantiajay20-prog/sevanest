// Regression tests for the seven defects found in the 2026-11-06 visual QA pass (see
// CUSTOMER_APP_UI_UX_AUDIT.md "Visual QA pass 3"). Each test checks what a person sees (one-line
// labels, whole words, targets on screen) at 1.3x text, not how it is built. Real fonts are loaded
// because the default test font is far wider than Inter.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

import '../helpers/discover_harness.dart';
import '../helpers/fakes.dart';
import '../helpers/real_fonts.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 1));
  }
  await t.pumpAndSettle();
}

void scale(WidgetTester t, double s) {
  t.platformDispatcher.textScaleFactorTestValue = s;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

RenderParagraph para(WidgetTester t, Finder f) =>
    t.renderObject<RenderParagraph>(f.first);

/// Number of text lines the paragraph was laid out on.
int lines(WidgetTester t, Finder f) {
  final p = para(t, f);
  return p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

/// Every line after the first starts right after a space or newline, never inside a word.
void expectNoMidWordBreak(WidgetTester t, Finder f) {
  final p = para(t, f);
  final text = p.text.toPlainText();
  double top(int i) => p
      .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
      .first
      .top;
  for (var i = 1; i < text.length; i++) {
    if (top(i) > top(i - 1) + 1) {
      expect(
        RegExp(r'\s').hasMatch(text[i - 1]) || RegExp(r'\s').hasMatch(text[i]),
        isTrue,
        reason: '"$text" breaks inside a word at "${text.substring(i)}"',
      );
    }
  }
}

void main() {
  setUpAll(loadRealFonts);

  Future<DiscoverEnv> returning(
    WidgetTester t, {
    required String route,
    double height = 1400,
  }) async {
    final env = await launchDiscover(t, height: height);
    env.container
        .read(mockApiProvider.notifier)
        .set(const MockApiState(returningUser: true));
    env.stepsOneToThree(EngagementType.fullTime);
    await env.go(route);
    await settle(t);
    return env;
  }

  group('1 and 2: interview detail at 1.3x', () {
    testWidgets('"Your requirement" is one line, not "requiremen/t"', (
      t,
    ) async {
      scale(t, 1.3);
      await returning(t, route: '/interviews/iv_301');
      expect(t.takeException(), isNull);
      final label = find.text('Your requirement');
      expect(label, findsOneWidget);
      expect(lines(t, label), lessThanOrEqualTo(2));
      expectNoMidWordBreak(t, label);
    });

    testWidgets('hero step captions do not run together', (t) async {
      scale(t, 1.3);
      await returning(t, route: '/interviews/iv_301');
      expect(t.takeException(), isNull);
      final captions = <Rect>[];
      for (final label in ['Requested', 'Scheduled', 'Done', 'Decision']) {
        final f = find.descendant(
          of: find.byType(FittedBox),
          matching: find.text(label),
        );
        expect(f, findsOneWidget, reason: label);
        captions.add(t.getRect(f));
      }
      captions.sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < captions.length; i++) {
        expect(
          captions[i].left - captions[i - 1].right,
          greaterThanOrEqualTo(2),
          reason: 'captions ${i - 1} and $i must not touch',
        );
      }
    });
  });

  testWidgets('3: worker reviews rating-bar label stays on one line', (
    t,
  ) async {
    scale(t, 1.3);
    await returning(t, route: '/workers/cook-2/reviews');
    expect(t.takeException(), isNull);
    final label = find.text('4★');
    expect(label, findsWidgets);
    expect(lines(t, label), 1);
  });

  group('4: Budget footer button at 1.3x', () {
    for (final width in [360.0, 393.0]) {
      testWidgets('"Review requirement" is whole at ${width.toInt()} wide', (
        t,
      ) async {
        scale(t, 1.3);
        final env = await launchDiscover(t, height: 1600);
        t.view.physicalSize = Size(width * 3, 1600 * 3);
        env.stepsOneToThree(EngagementType.partTime);
        env.draftNotifier
          ..setTiming(
            const Timing(
              window: TimeWindow.morning,
              startMinutes: 480,
              endMinutes: 720,
              days: {1, 2, 3, 4, 5, 6},
            ),
          )
          ..setStartDate(DateTime(2026, 10, 12));
        await env.go('/discover/budget');
        await settle(t);
        expect(t.takeException(), isNull);
        final label = find.descendant(
          of: k('discover_next_btn'),
          matching: find.text('Review requirement'),
        );
        expect(label, findsOneWidget);
        expect(para(t, label).didExceedMaxLines, isFalse);
        expect(lines(t, label), lessThanOrEqualTo(2));
        expect(
          t.getRect(k('discover_next_btn')).right,
          lessThanOrEqualTo(width),
        );
      });
    }
  });

  group('5: login trust strip at 1.3x', () {
    for (final width in [360.0, 393.0]) {
      testWidgets('no word is broken mid-word at ${width.toInt()} wide', (
        t,
      ) async {
        t.view
          ..physicalSize = Size(width * 3, 2532)
          ..devicePixelRatio = 3;
        addTearDown(t.view.reset);
        scale(t, 1.3);
        await t.pumpWidget(
          testRootApp(
            store: InMemorySessionStore(),
            repo: FakeAuthRepository(),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final item in ['Nearby', 'Secure', 'Dedicated']) {
          final f = find.textContaining(item, findRichText: true);
          expect(f, findsWidgets, reason: item);
          expectNoMidWordBreak(t, f);
        }
      });
    }
  });

  group('6: welcome screen on a short phone', () {
    for (final size in [const Size(360, 640), const Size(320, 568)]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: Get Started is on screen',
        (t) async {
          t.view
            ..physicalSize = size * 3
            ..devicePixelRatio = 3
            ..padding = const FakeViewPadding(top: 72, bottom: 72)
            ..viewPadding = const FakeViewPadding(top: 72, bottom: 72);
          addTearDown(t.view.reset);
          await t.pumpWidget(
            testRootApp(
              store: InMemorySessionStore(),
              repo: FakeAuthRepository(),
              splashChoice: true,
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          final cta = t.getRect(k('splash_customer_btn'));
          expect(cta.height, greaterThanOrEqualTo(44));
          expect(cta.bottom, lessThanOrEqualTo(size.height - 24));
          expect(cta.top, greaterThanOrEqualTo(24));
        },
      );
    }
  });

  group('7: workers results title', () {
    testWidgets('a deep link without a requirement never reads " near "', (
      t,
    ) async {
      final env = await launchDiscover(t);
      await env.go('/workers');
      await settle(t);
      expect(find.textContaining(' near '), findsNothing);
      expect(find.text('Find a worker'), findsWidgets);
    });

    testWidgets('with a requirement the title names service and area', (
      t,
    ) async {
      final env = await launchDiscover(t);
      env.stepsOneToThree(EngagementType.fullTime);
      await env.go('/workers');
      await settle(t);
      expect(find.text('Cook near Madhapur'), findsOneWidget);
    });
  });
}
