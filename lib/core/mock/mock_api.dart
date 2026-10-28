import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';

/// What the mock API pretends the network is doing. Flipped from the dev menu so every
/// loading / error / offline / empty state in the design is reachable (build prompt, final pass).
enum MockMode { normal, slow, error, offline, empty, loading }

class MockApiState {
  const MockApiState({
    this.mode = MockMode.normal,
    this.returningUser = false,
    this.live = false,
    this.forceUpdate = false,
    this.maintenance = false,
  });

  final MockMode mode;

  /// True = repositories whose endpoints exist talk to the deployed backend (always so in stg /
  /// prod); false = the seeded mocks, so every state can be reached on a device. The dev flavor
  /// starts on mocks and can flip this in the dev menu.
  final bool live;

  /// Seeds Home (and later modules) as a returning customer with activity, or a brand-new one.
  final bool returningUser;

  /// Dev only: what the launch gate shows while on mocks (module 11.1).
  final bool forceUpdate;
  final bool maintenance;

  MockApiState copyWith({
    MockMode? mode,
    bool? returningUser,
    bool? live,
    bool? forceUpdate,
    bool? maintenance,
  }) => MockApiState(
    mode: mode ?? this.mode,
    returningUser: returningUser ?? this.returningUser,
    live: live ?? this.live,
    forceUpdate: forceUpdate ?? this.forceUpdate,
    maintenance: maintenance ?? this.maintenance,
  );

  Duration get latency => switch (mode) {
    MockMode.slow => const Duration(seconds: 4),
    _ => const Duration(milliseconds: 300),
  };
}

class MockApiNotifier extends Notifier<MockApiState> {
  @override
  MockApiState build() =>
      MockApiState(live: !ref.read(appConfigProvider).useMocks);

  // ignore: use_setters_to_change_properties
  void set(MockApiState s) => state = s;
}

final mockApiProvider = NotifierProvider<MockApiNotifier, MockApiState>(
  MockApiNotifier.new,
);

/// Runs [build] after the mock latency. `error` and `offline` throw (a repository may catch
/// offline and serve its cache instead of a [NetworkFailure]).
Future<T> mockCall<T>(MockApiState s, T Function() build) async {
  // `loading` never answers, so the skeleton / loading design states stay on screen.
  if (s.mode == MockMode.loading) await Completer<void>().future;
  await Future<void>.delayed(s.latency);
  return switch (s.mode) {
    MockMode.error => throw const ServerFailure(),
    MockMode.offline => throw const NetworkFailure(),
    _ => build(),
  };
}
