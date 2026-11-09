/// Every repository throws one of these; UI never sees DioException (AGENTS §51, §61).
sealed class AppFailure implements Exception {
  const AppFailure([this.message]);
  final String? message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message,
    this.timedOut = false,
    this.offline = false,
  ]);

  /// True when a write was refused up front because the device has no network. Nothing was sent.
  final bool offline;

  /// True when the device was online but the server did not answer in time. The outcome of a write
  /// is then unknown, so callers must not claim failure or blindly retry (see failureMessage).
  final bool timedOut;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message]);
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message]);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message]);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message, this.code]);

  /// Backend error code, e.g. `DUPLICATE_BOOKING` or `INVALID_TRANSITION`.
  final String? code;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([
    super.message,
    this.fieldErrors = const {},
    this.code,
  ]);
  final Map<String, String> fieldErrors;

  /// Backend error code, e.g. `WORKER_NOT_ELIGIBLE` or `OUTSIDE_SERVICE_AREA`.
  final String? code;
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure([super.message, this.retryAfterSeconds]);

  /// From `Retry-After` or `details[0].retryAfterSeconds`; null when the server gave none.
  final int? retryAfterSeconds;
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message]);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message]);
}

enum OtpError { invalid, expired, locked }

/// OTP verification failures the UI reacts to individually.
final class OtpFailure extends AppFailure {
  const OtpFailure(this.error, [super.message]);
  final OtpError error;
}

/// True only when the device has no connection. A timeout is not "offline": the server may have
/// received the request, so screens must not say "you're offline" for it.
bool isOffline(Object? e) => e is NetworkFailure && !e.timedOut;
