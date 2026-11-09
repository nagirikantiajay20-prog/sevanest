// Mock and demo code must not be reachable from any shipped flavor.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_demo.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_remote.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_remote.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';

ProviderContainer _with(AppConfig c) {
  final container = ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(c)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const prod = AppConfig(
    env: AppEnv.prod,
    apiBaseUrl: 'https://api.example.test/api/v1',
    useMocks: false,
  );
  const stg = AppConfig(
    env: AppEnv.stg,
    apiBaseUrl: 'https://stg.example.test/api/v1',
    useMocks: false,
  );

  group('flavors never resolve to mock or demo repositories', () {
    for (final c in [AppConfig.dev, stg, prod]) {
      test('${c.env.name}: live auth, address and payment repositories', () {
        final k = _with(c);
        expect(k.read(authRepositoryProvider), isA<AuthRepositoryRemote>());
        expect(
          k.read(authRepositoryProvider),
          isNot(isA<AuthRepositoryDemo>()),
        );
        expect(k.read(demoLoginProvider), isFalse);
        expect(
          k.read(addressRepositoryProvider),
          isA<AddressRepositoryRemote>(),
        );
        expect(k.read(mockApiProvider).live, isTrue);
        expect(
          k.read(paymentRepositoryProvider),
          isA<PaymentRepositoryRemote>(),
        );
      });
    }

    test('only the automated-test config turns the demo login on', () {
      final k = _with(AppConfig.mock);
      expect(k.read(authRepositoryProvider), isA<AuthRepositoryDemo>());
      expect(k.read(mockApiProvider).live, isFalse);
    });
  });

  group('startup refuses unsafe release configuration', () {
    test(
      'stg and prod reject mocks, http, a missing URL and the dev backend',
      () {
        for (final env in [AppEnv.stg, AppEnv.prod]) {
          AppConfig of(String url, {bool mocks = false}) =>
              AppConfig(env: env, apiBaseUrl: url, useMocks: mocks);
          expect(
            of('https://x.example.test/api', mocks: true).problem,
            isNotNull,
          );
          expect(of('http://x.example.test/api').problem, isNotNull);
          expect(of('').problem, contains('API_BASE_URL'));
          expect(of(AppConfig.devApiUrl).problem, contains('dev backend'));
          expect(of('https://x.example.test/api').problem, isNull);
        }
      },
    );

    test('the release flavors have no baked-in URL to fall back to', () {
      expect(AppConfig.stg.apiBaseUrl, isNot(AppConfig.devApiUrl));
      expect(AppConfig.prod.apiBaseUrl, isNot(AppConfig.devApiUrl));
    });
  });

  group('source guards', () {
    String read(String path) => File(path).readAsStringSync();

    test('no shipped code selects the mock configuration', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => read(f.path).contains('AppConfig.mock'))
          .map((f) => f.path)
          .toList();
      expect(offenders, isEmpty);
    });

    test('each entrypoint bootstraps its own flavor', () {
      expect(read('lib/main_dev.dart'), contains('AppConfig.dev'));
      expect(read('lib/main_stg.dart'), contains('AppConfig.stg'));
      expect(read('lib/main_prod.dart'), contains('AppConfig.prod'));
      expect(read('lib/main_prod.dart'), isNot(contains('mock')));
    });

    test(
      'bootstrap stops on an invalid configuration before anything starts',
      () {
        final b = read('lib/app/bootstrap.dart');
        expect(b, contains('config.problem'));
        expect(b.indexOf('config.problem'), lessThan(b.indexOf('Firebase')));
      },
    );

    test('the widget gallery route exists only in the dev flavor', () {
      final r = read('lib/app/router/app_router.dart');
      expect(r, contains('if (config.env == AppEnv.dev)'));
      expect(r, contains('allowDev: !config.isProd'));
    });
  });
}
