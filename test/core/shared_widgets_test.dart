import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/core/widgets/sn_text_field.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

import '../helpers/fakes.dart';

Widget _view(AsyncValue<List<int>> v, {VoidCallback? onRetry}) => testApp(
  AsyncValueView<List<int>>(
    value: v,
    isEmpty: (d) => d.isEmpty,
    onRetry: onRetry,
    data: (d) => Text('items:${d.length}'),
  ),
);

void main() {
  group('SnButton', () {
    testWidgets('calls onPressed; ignores taps while loading', (t) async {
      var taps = 0;
      await t.pumpWidget(
        testApp(SnButton(label: 'Go', onPressed: () => taps++)),
      );
      await t.tap(find.text('Go'));
      expect(taps, 1);

      await t.pumpWidget(
        testApp(
          SnButton(label: 'Go', isLoading: true, onPressed: () => taps++),
        ),
      );
      await t.tap(find.byType(FilledButton));
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('SnTextField shows error text', (t) async {
    await t.pumpWidget(
      testApp(const SnTextField(label: 'Name', errorText: 'Required')),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  group('AsyncValueView', () {
    testWidgets('loading shows skeleton', (t) async {
      await t.pumpWidget(_view(const AsyncLoading()));
      expect(find.byType(SnSkeletonList), findsOneWidget);
    });

    testWidgets('data shows content', (t) async {
      await t.pumpWidget(_view(const AsyncData([1, 2])));
      expect(find.text('items:2'), findsOneWidget);
    });

    testWidgets('empty shows empty state', (t) async {
      await t.pumpWidget(_view(const AsyncData([])));
      expect(find.byType(SnEmptyState), findsOneWidget);
    });

    testWidgets('error shows message and retry calls back', (t) async {
      var retries = 0;
      await t.pumpWidget(
        _view(
          const AsyncError<List<int>>(NetworkFailure(), StackTrace.empty),
          onRetry: () => retries++,
        ),
      );
      expect(find.textContaining("Couldn't reach SevaNest"), findsOneWidget);
      await t.tap(find.byKey(const Key('error_retry_btn')));
      expect(retries, 1);
    });

    testWidgets('refresh failure keeps old data with stale banner', (t) async {
      var builds = 0;
      final pod = FutureProvider<List<int>>((ref) async {
        if (builds++ == 0) return [1];
        throw const NetworkFailure();
      }, retry: (_, _) => null);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(pod.future);
      c.invalidate(pod);
      await expectLater(c.read(pod.future), throwsA(isA<NetworkFailure>()));
      final failed = c.read(pod);
      expect(failed.hasValue && failed.hasError, isTrue);
      await t.pumpWidget(_view(failed));
      expect(find.text('items:1'), findsOneWidget);
      expect(
        find.text("Showing earlier data. Couldn't refresh."),
        findsOneWidget,
      );
    });
  });

  test('PagedState follows cursor semantics', () {
    const s = PagedState<int>(items: [1], nextCursor: 'c1');
    expect(s.canLoadMore, isTrue);
    expect(s.loadingMore().canLoadMore, isFalse);
    final next = s.appended([2, 3], null);
    expect(next.items, [1, 2, 3]);
    expect(next.hasMore, isFalse);
    expect(s.failedMore('x').items, [1]);
  });
}
