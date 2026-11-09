// UNIT tests: the unfinished requirement (it holds an address) never outlives its session.
// Audit finding: sevanest/logout-leaves-requirement-draft-address-in-shared-preferences.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/account_data_cleaner.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

const _home = Address(
  id: 'addr-A',
  line: 'Flat 12, Lake View',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);

Future<String?> _stored() async =>
    (await SharedPreferences.getInstance()).getString(requirementDraftPrefKey);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Sign-out / sign-in return before their local cleanup finishes (it never delays the session
/// change), so tests wait for it explicitly.
Future<void> _signOut(ProviderContainer c) async {
  final n = c.read(authProvider.notifier);
  await n.signOut();
  await n.pendingCleanup;
  await _settle();
}

Future<void> _signIn(ProviderContainer c, String access) async {
  final n = c.read(authProvider.notifier);
  await n.signIn(access: access, refresh: 'r$access');
  await n.pendingCleanup;
  await _settle();
}

void main() {
  late InMemorySessionStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemorySessionStore((access: 'a', refresh: 'r'));
  });

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        accountDataCleanerProvider.overrideWithValue(
          AccountDataCleaner(
            receiptDirectories: () async => [],
            clearImages: () {},
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Customer A, signed in, part-way through a requirement with a saved address.
  Future<ProviderContainer> customerAWithDraft() async {
    final c = make();
    await c.read(authProvider.notifier).restore();
    c.read(requirementDraftProvider.notifier)
      ..setService('cook')
      ..setEngagement(EngagementType.partTime)
      ..setAddress(_home);
    c.read(requirementNoteProvider.notifier).set('please call before 9');
    await _settle();
    expect(await _stored(), contains('Madhapur'));
    return c;
  }

  test('while signed in the draft is saved and restored as before', () async {
    final c1 = await customerAWithDraft();
    expect(c1.read(authProvider), AuthStatus.authenticated);

    final c2 = make(); // the app was killed and reopened, same session
    await c2.read(authProvider.notifier).restore();
    await c2.read(requirementDraftProvider.notifier).restore();
    final d = c2.read(requirementDraftProvider);
    expect(d.serviceId, 'cook');
    expect(d.address?.id, 'addr-A');
  });

  test('logout clears the persisted draft', () async {
    final c = await customerAWithDraft();

    await _signOut(c);

    expect(await _stored(), isNull);
  });

  test('logout clears the in-memory draft and note', () async {
    final c = await customerAWithDraft();

    await _signOut(c);
    expect(c.read(requirementDraftProvider).isEmpty, isTrue);
    expect(c.read(requirementNoteProvider), isEmpty);
  });

  test('session expiry (refresh rejected) clears memory and storage', () async {
    final c = await customerAWithDraft();
    // The same provider scope keeps running after an expiry: nothing rebuilds it.
    final adapter = FakeAdapter((o) async => jsonBody('{"message":"no"}', 401));
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        store: store,
        dio: dio,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://x.test'))
          ..httpClientAdapter = adapter,
        onExpired: () => c.read(authProvider.notifier).signOut(),
      ),
    );

    await expectLater(
      dio.get<dynamic>('/customers/me'),
      throwsA(isA<DioException>()),
    );
    await c.read(authProvider.notifier).pendingCleanup;
    await _settle();

    expect(c.read(authProvider), AuthStatus.unauthenticated);
    expect(c.read(requirementDraftProvider).isEmpty, isTrue);
    expect(await _stored(), isNull);
  });

  test('a different account never gets the previous draft', () async {
    final c = await customerAWithDraft();
    await _signOut(c);

    // Customer B signs in on the same install, same provider scope (expiry path).
    await _signIn(c, 'b');
    await c.read(requirementDraftProvider.notifier).restore();

    expect(c.read(requirementDraftProvider).isEmpty, isTrue);
    expect(c.read(requirementDraftProvider).address, isNull);
  });

  test(
    'a draft left behind by a failed cleanup is dropped at sign-in',
    () async {
      SharedPreferences.setMockInitialValues({
        requirementDraftPrefKey: '{"serviceId":"cook"}',
      });
      store = InMemorySessionStore();
      final c = make();
      await c.read(authProvider.notifier).restore();
      expect(c.read(authProvider), AuthStatus.unauthenticated);

      await _signIn(c, 'b');
      await c.read(requirementDraftProvider.notifier).restore();

      expect(await _stored(), isNull);
      expect(c.read(requirementDraftProvider).isEmpty, isTrue);
    },
  );

  test('restore does nothing without a session', () async {
    SharedPreferences.setMockInitialValues({
      requirementDraftPrefKey: '{"serviceId":"cook"}',
    });
    store = InMemorySessionStore();
    final c = make();
    await c.read(authProvider.notifier).restore();

    await c.read(requirementDraftProvider.notifier).restore();

    expect(c.read(requirementDraftProvider).isEmpty, isTrue);
  });

  test(
    'a restore still reading when the session ends cannot revive it',
    () async {
      SharedPreferences.setMockInitialValues({
        requirementDraftPrefKey: '{"serviceId":"cook"}',
      });
      final c = make();
      await c.read(authProvider.notifier).restore();

      final pending = c.read(requirementDraftProvider.notifier).restore();
      await _signOut(c);
      await pending;

      expect(c.read(requirementDraftProvider).isEmpty, isTrue);
    },
  );

  test('a cleanup that fails still ends the session', () async {
    final c = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        accountDataCleanerProvider.overrideWithValue(
          AccountDataCleaner(
            prefs: () => throw StateError('prefs unavailable'),
            receiptDirectories: () => throw StateError('no storage'),
            clearImages: () => throw StateError('no binding'),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authProvider.notifier).restore();

    await _signOut(c);
    expect(c.read(authProvider), AuthStatus.unauthenticated);
    expect(await store.read(), isNull);
  });
}
