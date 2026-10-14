// LIVE integration test for module 10: read-only requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1, with the backend test customer from the environment:
//
//     $env:SEVANEST_LIVE = '1'; $env:SEVANEST_TEST_MOBILE = '<number>'; $env:SEVANEST_TEST_OTP = '<otp>'
//     flutter test test/live/support_notifications_live_test.dart
//
//   It never creates a ticket, message, report or block, never marks a notification read and never
//   binds a device token: none of those can be undone by the customer.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/notifications/data/notification_repository_remote.dart';
import 'package:sevanest_customer/features/support/data/support_repository_remote.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

class _RandomDeviceId implements DeviceIdStore {
  final String id = const Uuid().v4();
  @override
  Future<String> get() async => id;
}

void main() {
  final env = Platform.environment;
  final live = env['SEVANEST_LIVE'] == '1';
  final mobile = env['SEVANEST_TEST_MOBILE'];
  final otp = env['SEVANEST_TEST_OTP'];
  final baseUrl = env['SEVANEST_API_BASE'] ?? AppConfig.dev.apiBaseUrl;

  test(
    'LIVE support and notifications: reads only',
    () async {
      final store = InMemorySessionStore();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(env: AppEnv.dev, apiBaseUrl: baseUrl, useMocks: false),
          ),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);
      final support = SupportRepositoryRemote(dio);
      final inbox = NotificationRepositoryRemote(dio);

      // Anonymous calls are refused.
      await expectLater(support.list(), throwsA(isA<UnauthorizedFailure>()));
      await expectLater(
        inbox.unreadCount(),
        throwsA(isA<UnauthorizedFailure>()),
      );

      final auth = AuthRepositoryRemote(dio, _RandomDeviceId());
      await auth.requestOtp(mobile!);
      final tokens = await auth.verifyOtp(mobile, otp!);
      await store.write(access: tokens.access, refresh: tokens.refresh);

      final cats = await support.categories();
      // ignore: avoid_print
      print('LIVE categories: ${cats.map((c) => c.code).toList()}');
      expect(cats, isNotEmpty);
      for (final c in cats) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
      }

      final tickets = await support.list();
      for (final t in tickets.items) {
        expect(t.status, isNot(TicketStatus.unknown));
      }
      if (tickets.items.isNotEmpty) {
        final one = await support.get(tickets.items.first.id);
        expect(one.id, tickets.items.first.id);
        final msgs = await support.messages(one.id);
        // ignore: avoid_print
        print(
          'LIVE first ticket: ${one.status.name}, ${msgs.items.length} messages',
        );
      } else {
        // ignore: avoid_print
        print(
          'LIVE: no tickets; get / messages of a real ticket were NOT exercised',
        );
      }
      await expectLater(
        support.get('00000000-0000-4000-8000-000000000000'),
        throwsA(isA<NotFoundFailure>()),
      );

      final page = await inbox.list();
      // ignore: avoid_print
      print('LIVE inbox: ${page.items.length} items, next: ${page.nextCursor}');
      final unread = await inbox.unreadCount();
      expect(unread, greaterThanOrEqualTo(0));
      final unreadList = await inbox.list(unreadOnly: true);
      for (final n in unreadList.items) {
        expect(n.isRead, isFalse);
      }
      for (final n in page.items) {
        // ignore: avoid_print
        print('LIVE notification route: ${n.target?.type}');
      }
    },
    skip: live && mobile != null && otp != null
        ? false
        : 'set SEVANEST_LIVE=1 and the test customer env vars',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
