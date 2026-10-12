import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';

/// What the mock API pretends the network is doing. Flipped from the dev menu so every
/// loading / error / offline / empty state in the design is reachable (build prompt, final pass).
enum MockMode { normal, slow, error, offline, empty }

class MockApiState {
  const MockApiState({this.mode = MockMode.normal, this.returningUser = true});

  final MockMode mode;

  /// Seeds Home (and later modules) as a returning customer with activity, or a brand-new one.
  final bool returningUser;

  MockApiState copyWith({MockMode? mode, bool? returningUser}) => MockApiState(
    mode: mode ?? this.mode,
    returningUser: returningUser ?? this.returningUser,
  );

  Duration get latency => switch (mode) {
    MockMode.slow => const Duration(seconds: 4),
    _ => const Duration(milliseconds: 300),
  };
}

class MockApiNotifier extends Notifier<MockApiState> {
  @override
  MockApiState build() => const MockApiState();

  // ignore: use_setters_to_change_properties
  void set(MockApiState s) => state = s;
}

final mockApiProvider = NotifierProvider<MockApiNotifier, MockApiState>(
  MockApiNotifier.new,
);

/// Runs [build] after the mock latency. `error` and `offline` throw (a repository may catch
/// offline and serve its cache instead of a [NetworkFailure]).
Future<T> mockCall<T>(MockApiState s, T Function() build) async {
  await Future<void>.delayed(s.latency);
  return switch (s.mode) {
    MockMode.error => throw const ServerFailure(),
    MockMode.offline => throw const NetworkFailure(),
    _ => build(),
  };
}
