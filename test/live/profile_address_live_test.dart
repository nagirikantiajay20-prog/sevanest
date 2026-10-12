// LIVE integration tests for module 02: real HTTPS requests to the deployed backend (not mocked).
//
//   Skipped unless SEVANEST_LIVE=1. The authenticated flow also needs the backend-provisioned TEST
//   customer number and its static OTP, supplied ONLY through the environment (never commit them):
//
//     $env:SEVANEST_LIVE = '1'
//     $env:SEVANEST_TEST_MOBILE = '<10-digit test customer number>'
//     $env:SEVANEST_TEST_OTP = '<its static OTP>'
//     flutter test test/live/profile_address_live_test.dart
//
//   The authenticated test creates addresses and deletes them again, and restores the profile name.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_profile_repository_remote.dart';
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
  const why = 'set SEVANEST_LIVE=1 to run live backend tests';

  late InMemorySessionStore store;
  late ProviderContainer container;
  late Dio dio;

  setUp(() {
    store = InMemorySessionStore();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(env: AppEnv.dev, apiBaseUrl: baseUrl, useMocks: false),
        ),
        sessionStoreProvider.overrideWithValue(store),
      ],
    );
    dio = container.read(dioProvider);
  });
  tearDown(() => container.dispose());

  group('LIVE module 02, no session', () {
    test(
      'profile, address and service-area endpoints reject anonymous calls with 401',
      () async {
        await expectLater(
          CustomerProfileRepositoryRemote(dio).get(),
          throwsA(isA<UnauthorizedFailure>()),
        );
        await expectLater(
          AddressRepositoryRemote(dio).list(),
          throwsA(isA<UnauthorizedFailure>()),
        );
        await expectLater(
          AddressRepositoryRemote(dio).serviceAreas(city: 'Hyderabad'),
          throwsA(isA<UnauthorizedFailure>()),
        );
      },
      skip: live ? false : why,
    );
  });

  group('LIVE module 02, authenticated with the backend test account', () {
    test(
      'profile create/read/update + address CRUD + default + validation',
      () async {
        final auth = AuthRepositoryRemote(dio, _RandomDeviceId());
        await auth.requestOtp(mobile!);
        final tokens = await auth.verifyOtp(mobile, otp!);
        await store.write(access: tokens.access, refresh: tokens.refresh);

        final profiles = CustomerProfileRepositoryRemote(dio);
        final addrs = AddressRepositoryRemote(dio);
        final created = <String>[];
        String? originalName;
        try {
          // --- profile ---
          try {
            originalName = (await profiles.get()).name;
          } on NotFoundFailure {
            final p = await profiles.create(
              name: 'Live Test',
              email: 'live.test@example.com',
              preferredLanguage: 'en',
            );
            originalName = p.name;
          }
          final read = await profiles.get();
          expect(read.name, isNotEmpty);
          expect(read.email, isNotEmpty);
          final changed = await profiles.update(
            name: 'Live Test Updated',
            email: read.email,
            preferredLanguage: read.preferredLanguage,
          );
          expect(changed.name, 'Live Test Updated');
          expect((await profiles.get()).name, 'Live Test Updated');

          await expectLater(
            profiles.update(
              name: 'X',
              email: 'not-an-email',
              preferredLanguage: 'en',
            ),
            throwsA(isA<ValidationFailure>()),
          );

          // --- service areas ---
          final areas = await addrs.serviceAreas(city: 'Hyderabad');
          // ignore: avoid_print
          print('LIVE service areas for Hyderabad: ${areas.length}');

          // --- addresses ---
          const base = AddressInput(
            line: 'Flat 1, Live Test Residency',
            area: 'Madhapur',
            city: 'Hyderabad',
            pincode: '500081',
            isDefault: true,
          );
          final a1 = await addrs.create(base);
          created.add(a1.id);
          expect(a1.isDefault, isTrue);
          expect(a1.pincode, '500081');

          final a2 = await addrs.create(
            const AddressInput(
              line: 'Flat 2, Live Test Towers',
              area: 'Gachibowli',
              city: 'Hyderabad',
              pincode: '500032',
            ),
          );
          created.add(a2.id);
          expect(a2.isDefault, isFalse);

          var list = await addrs.list();
          expect(list.map((a) => a.id), containsAll([a1.id, a2.id]));
          expect(list.first.isDefault, isTrue, reason: 'default first');

          final edited = await addrs.update(
            a2.id,
            const AddressInput(
              line: 'Flat 2, Live Test Towers',
              area: 'Gachibowli',
              city: 'Hyderabad',
              pincode: '500033',
            ),
          );
          expect(edited.pincode, '500033');

          await addrs.setDefault(a2.id);
          list = await addrs.list();
          expect(list.firstWhere((a) => a.id == a2.id).isDefault, isTrue);
          expect(list.firstWhere((a) => a.id == a1.id).isDefault, isFalse);

          await expectLater(
            addrs.create(
              const AddressInput(
                line: 'x',
                area: 'Madhapur',
                city: 'Hyderabad',
                pincode: '12',
              ),
            ),
            throwsA(
              isA<ValidationFailure>().having(
                (f) => f.fieldErrors.containsKey('pincode'),
                'pincode field error',
                isTrue,
              ),
            ),
          );
        } finally {
          for (final id in created) {
            try {
              await addrs.delete(id);
            } on AppFailure {
              // best-effort cleanup
            }
          }
          if (originalName != null) {
            try {
              final p = await profiles.get();
              await profiles.update(
                name: originalName,
                email: p.email,
                preferredLanguage: p.preferredLanguage,
              );
            } on AppFailure {
              // best-effort restore
            }
          }
          await auth.logout();
        }
      },
      skip: live && mobile != null && otp != null
          ? false
          : 'needs SEVANEST_LIVE=1, SEVANEST_TEST_MOBILE and SEVANEST_TEST_OTP',
    );
  });
}
