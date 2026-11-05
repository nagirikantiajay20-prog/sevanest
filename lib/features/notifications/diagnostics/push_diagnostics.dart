import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sevanest_customer/features/notifications/domain/push_service.dart';

/// Dev / stg only. Runs the push chain step by step and says where it broke.

enum DiagStatus { pass, fail, skipped }

enum DiagSource { flutter, network, backend, fcm }

enum DiagStepId {
  firebase,
  permission,
  channel,
  token,
  register,
  trigger,
  delivery,
  ack,
}

class DiagStep {
  const DiagStep({
    required this.id,
    required this.status,
    required this.at,
    required this.detail,
    this.raw,
    this.source,
  });
  final DiagStepId id;
  final DiagStatus status;
  final DateTime at;
  final String detail;

  /// Raw response / error text, for the copied report.
  final String? raw;
  final DiagSource? source;
}

class DiagReport {
  const DiagReport(this.steps);
  final List<DiagStep> steps;

  DiagStep? get failed =>
      steps.where((s) => s.status == DiagStatus.fail).firstOrNull;
  bool get ok => failed == null && steps.isNotEmpty;
}

/// Device-side facts, behind an interface so the runner is testable with a fake.
abstract interface class PushDiagEnv {
  /// `null` when Firebase is not initialised.
  ({String projectId, String appId, String senderId})? firebase();

  Future<({bool enabled, int channelImportance})> notificationState();

  /// Throws [FirebaseException] (its `code` is shown) or [TimeoutException].
  Future<String?> fcmToken();

  Future<({String model, String android})> device();
}

class RealPushDiagEnv implements PushDiagEnv {
  static const _channel = MethodChannel('sevanest/push_diag');

  Future<Map<Object?, Object?>> _state() async =>
      (await _channel.invokeMapMethod<Object?, Object?>('state')) ?? {};

  @override
  ({String projectId, String appId, String senderId})? firebase() {
    if (Firebase.apps.isEmpty) return null;
    final o = Firebase.app().options;
    return (
      projectId: o.projectId,
      appId: o.appId,
      senderId: o.messagingSenderId,
    );
  }

  @override
  Future<({bool enabled, int channelImportance})> notificationState() async {
    final s = await _state();
    return (
      enabled: s['enabled'] == true,
      channelImportance: (s['channelImportance'] as int?) ?? -1,
    );
  }

  @override
  Future<String?> fcmToken() => FirebaseMessaging.instance.getToken().timeout(
    const Duration(seconds: 10),
  );

  @override
  Future<({String model, String android})> device() async {
    try {
      final s = await _state();
      return (model: '${s['model']}', android: '${s['androidVersion']}');
    } on Object {
      return (model: 'unknown', android: 'unknown');
    }
  }
}

const expectedFirebaseProject = 'sevanest-ab168';

/// First 8 and last 6 characters only.
String maskToken(String t) => t.length <= 14
    ? '••••'
    : '${t.substring(0, 8)}…${t.substring(t.length - 6)}';

final _fcmWords = RegExp(
  'firebase|fcm|messaging|sender|credential|UNREGISTERED|SENDER_ID_MISMATCH|'
  'INVALID_ARGUMENT|THIRD_PARTY_AUTH_ERROR',
  caseSensitive: false,
);
final _fcmCode = RegExp(
  r'UNREGISTERED|SENDER_ID_MISMATCH|INVALID_ARGUMENT|THIRD_PARTY_AUTH_ERROR|'
  r'QUOTA_EXCEEDED|UNAVAILABLE|messaging/[\w-]+|auth/[\w-]+',
);

class _Http {
  _Http(this.status, this.body, this.ms, this.netError);
  final int? status;
  final String body;
  final int ms;

  /// Set when there was no HTTP response at all (offline, DNS, timeout).
  final String? netError;
  bool get ok => status != null && status! >= 200 && status! < 300;
}

class PushDiagnosticsRunner {
  PushDiagnosticsRunner({
    required this.env,
    required this.push,
    required this.dio,
    DateTime Function()? now,
    this.deliveryWait = const Duration(seconds: 20),
    this.onStep,
  }) : _now = now ?? DateTime.now;

  final PushDiagEnv env;
  final PushService push;
  final Dio dio;
  final Duration deliveryWait;
  final DateTime Function() _now;

  /// Called after every step (the screen fills its list from this).
  final void Function(DiagStep step)? onStep;

  final _steps = <DiagStep>[];

  DiagStep _add(
    DiagStepId id,
    DiagStatus status,
    String detail, {
    String? raw,
    DiagSource? source,
  }) {
    final s = DiagStep(
      id: id,
      status: status,
      at: _now(),
      detail: detail,
      raw: raw,
      source: source,
    );
    _steps.add(s);
    if (kDebugMode) {
      debugPrint('[push-diag] ${id.name} ${status.name}: $detail');
    }
    onStep?.call(s);
    return s;
  }

  void _skip(DiagStepId id, String why) => _add(id, DiagStatus.skipped, why);

  Future<_Http> _call(String method, String path, [Object? data]) async {
    final sw = Stopwatch()..start();
    try {
      final r = await dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
      return _Http(r.statusCode, _text(r.data), sw.elapsedMilliseconds, null);
    } on DioException catch (e) {
      final r = e.response;
      return _Http(
        r?.statusCode,
        r == null ? '' : _text(r.data),
        sw.elapsedMilliseconds,
        r == null ? '${e.type.name}: ${e.message ?? e.error}' : null,
      );
    } on Object catch (e) {
      return _Http(null, '', sw.elapsedMilliseconds, '$e');
    }
  }

  /// The full FCM token never appears in a result (it is masked wherever it is echoed).
  String? _secret;

  String _text(Object? d) {
    var t = d == null ? '' : (d is String ? d : _safeJson(d));
    final s = _secret;
    if (s != null) t = t.replaceAll(s, maskToken(s));
    return t;
  }

  static String _safeJson(Object d) {
    try {
      return jsonEncode(d);
    } on Object {
      return '$d';
    }
  }

  Future<DiagReport> run() async {
    _steps.clear();
    try {
      await push.start();
    } on Object {
      // reported by the Firebase step
    }

    // 1. Firebase
    final fb = env.firebase();
    if (fb == null) {
      _add(
        DiagStepId.firebase,
        DiagStatus.fail,
        'Firebase not initialised / google-services.json missing',
        source: DiagSource.flutter,
      );
      for (final id in DiagStepId.values.skip(1)) {
        _skip(id, 'Needs Firebase');
      }
      return DiagReport(List.of(_steps));
    }
    final fbInfo =
        'projectId ${fb.projectId}\nappId ${fb.appId}\nsenderId ${fb.senderId}';
    if (fb.projectId != expectedFirebaseProject) {
      _add(
        DiagStepId.firebase,
        DiagStatus.fail,
        'Wrong Firebase project (expected $expectedFirebaseProject)\n$fbInfo',
        source: DiagSource.flutter,
      );
    } else {
      _add(DiagStepId.firebase, DiagStatus.pass, fbInfo);
    }

    // 2 + 3. Permission and channel
    var enabled = false;
    var importance = -1;
    try {
      final s = await env.notificationState();
      enabled = s.enabled;
      importance = s.channelImportance;
    } on Object catch (e) {
      _add(
        DiagStepId.permission,
        DiagStatus.fail,
        'Could not read notification state: $e',
        source: DiagSource.flutter,
      );
    }
    final perm = await push.permission();
    if (_steps.last.id != DiagStepId.permission) {
      if (perm == PushPermission.granted && enabled) {
        _add(
          DiagStepId.permission,
          DiagStatus.pass,
          'FCM: granted, Android notifications: on',
        );
      } else {
        _add(
          DiagStepId.permission,
          DiagStatus.fail,
          'Permission denied (FCM: ${perm.name}, Android notifications: '
          '${enabled ? 'on' : 'off'}). Open app settings and allow notifications.',
          source: DiagSource.flutter,
        );
      }
      if (importance < 0) {
        _add(
          DiagStepId.channel,
          DiagStatus.fail,
          'Channel sevanest_high_importance is missing',
          source: DiagSource.flutter,
        );
      } else {
        _add(
          DiagStepId.channel,
          importance >= 4 ? DiagStatus.pass : DiagStatus.fail,
          'Channel sevanest_high_importance importance $importance'
          '${importance >= 4 ? '' : ' (needs 4 = HIGH for a heads-up)'}',
          source: importance >= 4 ? null : DiagSource.flutter,
        );
      }
    } else {
      _skip(DiagStepId.channel, 'Needs the notification state');
    }

    // 4. Token
    String? token;
    try {
      token = await env.fcmToken();
      if (token == null || token.isEmpty) {
        _add(
          DiagStepId.token,
          DiagStatus.fail,
          'getToken() returned null',
          source: DiagSource.flutter,
        );
        token = null;
      } else {
        _add(DiagStepId.token, DiagStatus.pass, maskToken(token));
      }
    } on FirebaseException catch (e) {
      _add(
        DiagStepId.token,
        DiagStatus.fail,
        'FirebaseException ${e.code}: ${e.message ?? ''}',
        source: DiagSource.flutter,
      );
    } on TimeoutException {
      _add(
        DiagStepId.token,
        DiagStatus.fail,
        'getToken() timed out after 10 s (Google Play services / network)',
        source: DiagSource.flutter,
      );
    } on Object catch (e) {
      _add(DiagStepId.token, DiagStatus.fail, '$e', source: DiagSource.flutter);
    }
    if (token == null) {
      _skip(DiagStepId.register, 'Needs an FCM token');
      _skip(DiagStepId.trigger, 'Needs an FCM token');
      _skip(DiagStepId.delivery, 'Needs a test push');
      _skip(DiagStepId.ack, 'Needs a delivered push');
      return DiagReport(List.of(_steps));
    }

    _secret = token;
    // 5. Register
    final reg = await _call('PUT', '/auth/device-token', {
      'token': token,
      'platform': push.platform,
    });
    final regRaw = 'HTTP ${reg.status ?? reg.netError}\n${reg.body}';
    if (reg.ok) {
      _add(
        DiagStepId.register,
        DiagStatus.pass,
        'HTTP ${reg.status}',
        raw: regRaw.replaceAll(token, maskToken(token)),
      );
    } else {
      _add(
        DiagStepId.register,
        DiagStatus.fail,
        reg.netError != null
            ? 'Network error: ${reg.netError}'
            : 'Backend error HTTP ${reg.status}: ${reg.body}',
        raw: regRaw.replaceAll(token, maskToken(token)),
        source: reg.netError != null ? DiagSource.network : DiagSource.backend,
      );
    }

    // Listen before triggering so a fast push is not missed.
    final inbox = Completer<PushMessage>();
    final sub = push.onForeground.listen((m) {
      if (!inbox.isCompleted) inbox.complete(m);
    });
    final started = _now();
    try {
      // 6. Trigger
      final t = await _call('POST', '/notifications/test-push');
      final trigger = _classify(t);
      _add(
        DiagStepId.trigger,
        trigger.ok ? DiagStatus.pass : DiagStatus.fail,
        '${trigger.label}\nHTTP ${t.status ?? '-'} · requested '
        '${started.toIso8601String()} · ${t.ms} ms\n${t.body}',
        raw: 'HTTP ${t.status ?? t.netError}\n${t.body}',
        source: trigger.ok ? null : trigger.source,
      );
      if (!trigger.ok) {
        _skip(DiagStepId.delivery, 'Test push was not accepted');
        _skip(DiagStepId.ack, 'Needs a delivered push');
        return DiagReport(List.of(_steps));
      }

      // 7. Delivery
      PushMessage? got;
      try {
        got = await inbox.future.timeout(deliveryWait);
      } on TimeoutException {
        got = null;
      }
      if (got == null) {
        _add(
          DiagStepId.delivery,
          DiagStatus.fail,
          'FCM accepted but the device did not receive it within '
          '${deliveryWait.inSeconds} s. Likely causes: battery optimisation / '
          'background restrictions (Vivo, iQOO, Xiaomi), no internet, wrong '
          'token or project, app force-stopped, notifications blocked.',
          source: DiagSource.fcm,
        );
        _skip(DiagStepId.ack, 'Needs a delivered push');
        return DiagReport(List.of(_steps));
      }
      final secs = _now().difference(started).inSeconds;
      final d = got.data;
      _add(
        DiagStepId.delivery,
        DiagStatus.pass,
        'Received on device after $secs s\ntitle: ${got.title}\nbody: ${got.body}\n'
        'notificationId: ${d['notificationId']}\nrouteType: ${d['routeType']}\n'
        'routeId: ${d['routeId']}',
        raw: jsonEncode({'title': got.title, 'body': got.body, 'data': d}),
      );

      // 8. Ack
      final id = '${d['notificationId'] ?? _idFrom(t.body) ?? ''}';
      if (id.isEmpty) {
        _skip(DiagStepId.ack, 'No notificationId in the push or response');
      } else {
        final a = await _call(
          'POST',
          '/notifications/${Uri.encodeComponent(id)}/ack',
          {'eventType': 'RECEIVED'},
        );
        _add(
          DiagStepId.ack,
          a.ok ? DiagStatus.pass : DiagStatus.fail,
          a.ok
              ? 'HTTP ${a.status}'
              : (a.netError ?? 'HTTP ${a.status}: ${a.body}'),
          raw: 'HTTP ${a.status ?? a.netError}\n${a.body}',
          source: a.ok
              ? null
              : (a.netError != null ? DiagSource.network : DiagSource.backend),
        );
      }
    } finally {
      await sub.cancel();
    }
    return DiagReport(List.of(_steps));
  }

  static String? _idFrom(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) {
        final m = j['data'] is Map ? j['data'] as Map : j;
        final v = m['notificationId'] ?? m['id'];
        return v?.toString();
      }
    } on Object {
      // not JSON
    }
    return null;
  }

  ({bool ok, String label, DiagSource source}) _classify(_Http t) {
    if (t.netError != null) {
      return (
        ok: false,
        label: 'Network error (device side): ${t.netError}',
        source: DiagSource.network,
      );
    }
    final s = t.status!;
    if (t.ok) {
      return (
        ok: true,
        label: 'Backend accepted and sent to FCM',
        source: DiagSource.backend,
      );
    }
    if (s == 401) {
      return (
        ok: false,
        label: 'Auth error (token expired)',
        source: DiagSource.backend,
      );
    }
    if (s >= 500 || _fcmWords.hasMatch(t.body)) {
      final code = _fcmCode.firstMatch(t.body)?.group(0);
      return (
        ok: false,
        label: 'Backend to FCM error${code == null ? '' : ' [$code]'}',
        source: DiagSource.fcm,
      );
    }
    return (
      ok: false,
      label: 'Backend rejected the request',
      source: DiagSource.backend,
    );
  }
}
