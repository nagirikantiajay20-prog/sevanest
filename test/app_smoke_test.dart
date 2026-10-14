import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('no session -> splash restores -> login screen', (t) async {
    useTestPhone(t);
    await t.pumpWidget(
      testRootApp(store: InMemorySessionStore(), repo: FakeAuthRepository()),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('login_mobile_field')), findsOneWidget);
    expect(find.byKey(const Key('login_get_otp_btn')), findsOneWidget);
  });

  testWidgets(
    'stored session -> GET /customers/me -> home with bottom navigation',
    (t) async {
      useTestPhone(t);
      final repo = FakeAuthRepository()..onProfile = () async => true;
      await t.pumpWidget(
        testRootApp(
          store: InMemorySessionStore((access: 'a', refresh: 'r')),
          repo: repo,
        ),
      );
      await t.pumpAndSettle();
      expect(repo.profileCalls, 1);
      expect(find.byKey(const Key('home_find_worker_btn')), findsOneWidget);
      expect(find.byKey(const Key('nav_bookings')), findsOneWidget);

      await t.tap(find.byKey(const Key('nav_account')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('account_profile_btn')), findsOneWidget);
    },
  );
}
