import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/app/app.dart';
import 'package:sevanest_customer/app/session_reset_host.dart';
import 'package:sevanest_customer/app/theme/app_theme.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/schedule_repository.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

import 'notification_fakes.dart';
import 'support_fakes.dart';

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this._tokens]);
  ({String access, String refresh})? _tokens;

  @override
  Future<({String access, String refresh})?> read() async => _tokens;

  @override
  Future<void> write({required String access, required String refresh}) async {
    _tokens = (access: access, refresh: refresh);
  }

  @override
  Future<void> clear() async => _tokens = null;
}

typedef AdapterHandler = Future<ResponseBody> Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  final AdapterHandler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(String json, int status) => ResponseBody.fromString(
  json,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// Pumps [child] inside a localized MaterialApp for widget tests.
Widget testApp(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

/// Test double for the auth backend. Unit/widget tests only: the app never ships a fake auth path.
class FakeAuthRepository implements AuthRepository {
  int requestCalls = 0;
  int verifyCalls = 0;
  int profileCalls = 0;
  int logoutCalls = 0;
  String? lastMobile;
  String? lastOtp;

  Future<OtpChallenge> Function(String mobile) onRequest = (_) async =>
      const OtpChallenge();
  Future<AuthTokens> Function(String mobile, String otp) onVerify =
      (_, _) async => (access: 'access-1', refresh: 'refresh-1');
  Future<bool> Function() onProfile = () async => true;
  Future<void> Function() onLogout = () async {};

  @override
  Future<OtpChallenge> requestOtp(String mobile) {
    requestCalls++;
    lastMobile = mobile;
    return onRequest(mobile);
  }

  @override
  Future<AuthTokens> verifyOtp(String mobile, String otp) {
    verifyCalls++;
    lastOtp = otp;
    return onVerify(mobile, otp);
  }

  @override
  Future<bool> profileComplete() {
    profileCalls++;
    return onProfile();
  }

  @override
  Future<void> logout() {
    logoutCalls++;
    return onLogout();
  }
}

/// Full app with the fakes wired in. Phone-sized surface set by [useTestPhone].
Widget testRootApp({
  required SessionStore store,
  required AuthRepository repo,
  HomeRepository? home,
  CatalogRepository? catalog,
  ScheduleRepository? schedule,
  GuidanceRepository? guidance,
  NotificationRepository? notifications,
  SupportRepository? support,
  SafetyRepository? safety,
  PushService? push,
  List<Override> overrides = const [],
}) => SessionResetHost(
  overrides: [
    appConfigProvider.overrideWithValue(AppConfig.dev),
    sessionStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(repo),
    homeRepositoryProvider.overrideWithValue(home ?? FakeHomeRepository()),
    catalogRepositoryProvider.overrideWithValue(
      catalog ?? FakeCatalogRepository(),
    ),
    scheduleRepositoryProvider.overrideWithValue(
      schedule ?? FakeScheduleRepository(),
    ),
    guidanceRepositoryProvider.overrideWithValue(
      guidance ?? FakeGuidanceRepository(),
    ),
    nowProvider.overrideWithValue(() => testNow),
    notificationRepositoryProvider.overrideWithValue(
      notifications ?? FakeNotificationRepository(),
    ),
    supportRepositoryProvider.overrideWithValue(
      support ?? FakeSupportRepository(),
    ),
    safetyRepositoryProvider.overrideWithValue(
      safety ?? FakeSafetyRepository(),
    ),
    pushServiceProvider.overrideWithValue(push ?? FakePushService()),
    ...overrides,
  ],
  child: const SevaNestApp(),
);

void useTestPhone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// In-memory customer profile backend for widget tests (never shipped).
class FakeProfileRepository implements CustomerProfileRepository {
  FakeProfileRepository([this.stored]);
  CustomerProfile? stored;
  int createCalls = 0;
  int updateCalls = 0;
  Object? failNext;
  Future<void>? gate;

  Future<CustomerProfile> _write(String n, String e, String l) async {
    await gate;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return stored = CustomerProfile(
      name: n,
      email: e,
      preferredLanguage: l,
      mobile: stored?.mobile,
      verificationStatus: stored?.verificationStatus,
    );
  }

  @override
  Future<CustomerProfile> get() async {
    await gate;
    final s = stored;
    if (s == null) throw const NotFoundFailure();
    return s;
  }

  @override
  Future<CustomerProfile> create({
    required String name,
    required String email,
    required String preferredLanguage,
  }) {
    createCalls++;
    return _write(name, email, preferredLanguage);
  }

  @override
  Future<CustomerProfile> update({
    required String name,
    required String email,
    required String preferredLanguage,
  }) {
    updateCalls++;
    return _write(name, email, preferredLanguage);
  }
}

/// In-memory address backend for widget tests (never shipped).
class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository([List<Address>? seed]) : items = [...?seed];
  List<Address> items;
  List<ServiceArea> areas = const [
    ServiceArea(id: 'a1', name: 'Madhapur', city: 'Hyderabad'),
    ServiceArea(id: 'a2', name: 'Gachibowli', city: 'Hyderabad'),
  ];
  int listCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;
  int defaultCalls = 0;
  AddressInput? lastInput;
  Object? failNext;
  Object? failList;
  Object? failAreas;

  /// What `resolveServiceArea` answers (null = no area matches).
  ServiceArea? resolved;
  var _seq = 100;

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Future<List<Address>> list() async {
    listCalls++;
    final f = failList;
    if (f != null) throw f;
    return [...items]..sort((a, b) => b.isDefault ? 1 : (a.isDefault ? -1 : 0));
  }

  @override
  Future<ServiceArea?> resolveServiceArea({
    double? latitude,
    double? longitude,
    String? name,
    String? city,
  }) async => resolved;

  Address _from(String id, AddressInput i) => Address(
    id: id,
    label: i.label,
    line2: i.line2,
    state: i.state,
    line: i.line,
    area: i.area,
    city: i.city,
    pincode: i.pincode,
    isDefault: i.isDefault,
  );

  @override
  Future<Address> create(AddressInput input) async {
    createCalls++;
    lastInput = input;
    _maybeFail();
    if (input.isDefault) {
      items = [
        for (final a in items)
          _from(
            a.id,
            AddressInput(
              line: a.line,
              area: a.area,
              city: a.city,
              pincode: a.pincode,
            ),
          ),
      ];
    }
    final a = _from('${_seq++}', input);
    items = [...items, a];
    return a;
  }

  @override
  Future<Address> update(String id, AddressInput input) async {
    lastInput = input;
    _maybeFail();
    final old = items.firstWhere((a) => a.id == id);
    final a = _from(
      id,
      AddressInput(
        line: input.line,
        area: input.area,
        city: input.city,
        pincode: input.pincode,
        isDefault: old.isDefault,
      ),
    );
    items = [for (final x in items) x.id == id ? a : x];
    return a;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    _maybeFail();
    items = items.where((a) => a.id != id).toList();
  }

  @override
  Future<void> setDefault(String id) async {
    defaultCalls++;
    _maybeFail();
    items = [
      for (final a in items)
        Address(
          id: a.id,
          line: a.line,
          area: a.area,
          city: a.city,
          pincode: a.pincode,
          isDefault: a.id == id,
        ),
    ];
  }

  @override
  Future<List<ServiceArea>> serviceAreas({String? city}) async {
    final f = failAreas;
    if (f != null) throw f;
    return areas;
  }
}

/// Instant Home aggregate for widget tests (no mock latency, so no pending timers).
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository([this.data = const HomeData()]);
  HomeData data;
  int fetchCalls = 0;
  Object? failNext;

  @override
  Future<HomeData> fetch() async {
    fetchCalls++;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return data;
  }
}

/// Instant catalogue for widget tests; [gate] holds the response, [failNext] throws once.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository([List<ServiceCategory>? seed])
    : items = seed ?? CatalogRepositoryMock.categories_;
  List<ServiceCategory> items;
  Object? failNext;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<List<ServiceCategory>> categories() async {
    calls++;
    await gate;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return items;
  }
}

class FakeLocationService implements LocationService {
  LocationResult result = const LocationResult(LocationOutcome.denied);
  Future<void>? gate;
  int calls = 0;
  int settingsCalls = 0;

  @override
  Future<LocationResult> currentAddress() async {
    calls++;
    await gate;
    return result;
  }

  @override
  Future<void> openSettings() async => settingsCalls++;
}

/// Fixed "now" for date rules: Friday 9 Oct 2026, as in the design screens.
final testNow = DateTime(2026, 10, 9, 10);

class FakeScheduleRepository implements ScheduleRepository {
  ScheduleConfig value = ScheduleConfig.fallback;
  Object? failNext;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<ScheduleConfig> config() async {
    calls++;
    await gate;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return value;
  }
}

class FakeGuidanceRepository implements GuidanceRepository {
  Guidance? value;
  Object? failNext;
  Future<void>? gate;
  final queries = <GuidanceQuery>[];

  @override
  Future<Guidance> guidance(GuidanceQuery q) async {
    queries.add(q);
    await gate;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return value ??
        Guidance(
          min: q.engagement == EngagementType.hourly ? 100 : 6000,
          max: q.engagement == EngagementType.hourly ? 200 : 10000,
          period: q.engagement == EngagementType.hourly
              ? BudgetPeriod.hourly
              : BudgetPeriod.monthly,
          city: q.city,
          basis: 'Based on recent bookings',
        );
  }
}
