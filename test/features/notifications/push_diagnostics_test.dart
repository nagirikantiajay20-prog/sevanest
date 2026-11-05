import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/notifications/diagnostics/push_diagnostics.dart';
import 'package:sevanest_customer/features/notifications/diagnostics/push_diagnostics_screen.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

import '../../helpers/discover_harness.dart';
import '../../helpers/notification_fakes.dart';

const _token = 'abcdefgh-0123456789-uvwxyz';

class _Env implements PushDiagEnv {
  ({String projectId, String appId, String senderId})? fb = (
    projectId: expectedFirebaseProject,
    appId: '1:2:android:3',
    senderId: '2',
  );
  bool enabled = true;
  int importance = 4;
  Object? tokenError;
  String? token = _token;

  @override
  ({String projectId, String appId, String senderId})? firebase() => fb;
  @override
  Future<({bool enabled, int channelImportance})> notificationState() async =>
      (enabled: enabled, channelImportance: importance);
  @override
  Future<String?> fcmToken() async {
    if (tokenError != null) throw tokenError!;
    return token;
  }

  @override
  Future<({String model, String android})> device() async =>
      (model: 'Fake', android: '14');
}

/// Answers by "METHOD path" prefix; anything unlisted is a 200.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.replies);
  final Map<String, (int, Object?)> replies;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? body,
    Future<void>? cancel,
  ) async {
    final key = '${o.method} ${o.path}';
    final r = replies.entries
        .where((e) => key.startsWith(e.key))
        .map((e) => e.value)
        .firstOrNull;
    final (status, data) = r ?? (200, <String, Object?>{});
    if (data is DioExceptionType) {
      throw DioException(requestOptions: o, type: data);
    }
    return ResponseBody.fromString(
      data is String ? data : jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<DiagReport> _run(
  _Env env,
  FakePushService push,
  Map<String, (int, Object?)> replies, {
  PushMessage? delivered,
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://x/api'))
    ..httpClientAdapter = _Adapter(replies);
  final runner = PushDiagnosticsRunner(
    env: env,
    push: push,
    dio: dio,
    deliveryWait: const Duration(milliseconds: 200),
  );
  final f = runner.run();
  if (delivered != null) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    push.foreground.add(delivered);
  }
  return f;
}

Map<DiagStepId, DiagStatus> _s(DiagReport r) => {
  for (final s in r.steps) s.id: s.status,
};

DiagStep _step(DiagReport r, DiagStepId id) =>
    r.steps.firstWhere((s) => s.id == id);

FakePushService _granted() => FakePushService(state: PushPermission.granted);

void main() {
  test('firebase not initialised: fails and skips the rest', () async {
    final r = await _run(_Env()..fb = null, _granted(), {});
    expect(r.failed!.id, DiagStepId.firebase);
    expect(r.failed!.source, DiagSource.flutter);
    expect(
      r.steps.skip(1).every((s) => s.status == DiagStatus.skipped),
      isTrue,
    );
  });

  test('wrong project id fails the firebase step', () async {
    final env = _Env()..fb = (projectId: 'other', appId: 'a', senderId: 's');
    final r = await _run(env, _granted(), {});
    expect(r.failed!.id, DiagStepId.firebase);
  });

  test('permission denied fails but the chain continues', () async {
    final r = await _run(
      _Env(),
      FakePushService(state: PushPermission.denied),
      {},
    );
    expect(_s(r)[DiagStepId.permission], DiagStatus.fail);
    expect(_s(r)[DiagStepId.token], DiagStatus.pass);
    expect(r.failed!.id, DiagStepId.permission);
  });

  test('token null stops at token', () async {
    final r = await _run(_Env()..token = null, _granted(), {});
    expect(_s(r)[DiagStepId.token], DiagStatus.fail);
    expect(_s(r)[DiagStepId.register], DiagStatus.skipped);
    expect(_s(r)[DiagStepId.trigger], DiagStatus.skipped);
  });

  test('device-token 500 is a backend failure, token never leaks', () async {
    final r = await _run(_Env(), _granted(), {
      'PUT /auth/device-token': (500, {'message': 'boom $_token'}),
    });
    final reg = _step(r, DiagStepId.register);
    expect(reg.status, DiagStatus.fail);
    expect(reg.source, DiagSource.backend);
    expect('${reg.raw}${reg.detail}'.contains(_token), isFalse);
  });

  test('test-push 401 is an auth error', () async {
    final r = await _run(_Env(), _granted(), {
      'POST /notifications/test-push': (401, {'message': 'expired'}),
    });
    final t = _step(r, DiagStepId.trigger);
    expect(t.detail, contains('Auth error (token expired)'));
    expect(t.source, DiagSource.backend);
    expect(_s(r)[DiagStepId.delivery], DiagStatus.skipped);
  });

  test('test-push without network is a device-side network error', () async {
    final r = await _run(_Env(), _granted(), {
      'POST /notifications/test-push': (0, DioExceptionType.connectionError),
    });
    final t = _step(r, DiagStepId.trigger);
    expect(t.detail, contains('Network error (device side)'));
    expect(t.source, DiagSource.network);
  });

  test('test-push 400 with a plain body is rejected by the backend', () async {
    final r = await _run(_Env(), _granted(), {
      'POST /notifications/test-push': (400, {'message': 'bad'}),
    });
    expect(
      _step(r, DiagStepId.trigger).detail,
      contains('Backend rejected the request'),
    );
  });

  test('test-push 500 with FCM text is a backend-to-FCM error', () async {
    final r = await _run(_Env(), _granted(), {
      'POST /notifications/test-push': (
        500,
        {'message': 'messaging error: SENDER_ID_MISMATCH'},
      ),
    });
    final t = _step(r, DiagStepId.trigger);
    expect(t.detail, contains('Backend to FCM error [SENDER_ID_MISMATCH]'));
    expect(t.source, DiagSource.fcm);
    expect(r.failed!.id, DiagStepId.trigger);
  });

  test('2xx but nothing arrives: delivery fails on FCM', () async {
    final r = await _run(_Env(), _granted(), {});
    final d = _step(r, DiagStepId.delivery);
    expect(d.status, DiagStatus.fail);
    expect(d.source, DiagSource.fcm);
    expect(_s(r)[DiagStepId.ack], DiagStatus.skipped);
  });

  test('full success acks the notification', () async {
    final r = await _run(
      _Env(),
      _granted(),
      {},
      delivered: const PushMessage(
        title: 't',
        body: 'b',
        data: {'notificationId': 'n1', 'routeType': 'booking', 'routeId': '9'},
      ),
    );
    expect(r.ok, isTrue);
    expect(_s(r)[DiagStepId.ack], DiagStatus.pass);
  });

  testWidgets('screen shows the verdict and results after a run', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://x/api'))
      ..httpClientAdapter = _Adapter({
        'POST /notifications/test-push': (500, {'message': 'FCM UNREGISTERED'}),
      });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.dev),
          pushDiagEnvProvider.overrideWithValue(_Env()),
          pushServiceProvider.overrideWithValue(_granted()),
          dioProvider.overrideWithValue(dio),
          appVersionProvider.overrideWith((ref) async => '1.0 (1)'),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PushDiagnosticsScreen(),
        ),
      ),
    );
    await t.tap(find.text('Send test push'));
    // Dio finishes on real time, so give the run real time to complete.
    for (var i = 0; i < 50 && find.text('Run again').evaluate().isEmpty; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Failed at: Trigger test push [FCM]'), findsOneWidget);
    expect(find.text('Run again'), findsOneWidget);
    expect(find.text('Firebase · PASS'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Copy full report'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Copy full report'), findsOneWidget);
  });

  for (final (config, shown) in [
    (AppConfig.prod, false),
    (AppConfig.stg, true),
  ]) {
    testWidgets('Account entry ${shown ? 'shown' : 'hidden'} in '
        '${config.env.name}', (t) async {
      final env = await launchDiscover(t, height: 1400, config: config);
      await env.tapKey('nav_account');
      expect(
        find.byKey(const Key('account_push_diag_btn')),
        shown ? findsOneWidget : findsNothing,
      );
    });
  }
}
