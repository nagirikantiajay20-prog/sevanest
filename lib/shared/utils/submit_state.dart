import 'package:sevanest_customer/core/errors/app_failure.dart';

/// Mutation state for a form: [busy] blocks double submits (AGENTS §65), [failure] is the last error.
class SubmitState {
  const SubmitState({this.busy = false, this.failure});
  final bool busy;
  final AppFailure? failure;
}
