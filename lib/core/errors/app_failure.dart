/// Every repository throws one of these; UI never sees DioException (AGENTS §51, §61).
sealed class AppFailure implements Exception {
  const AppFailure([this.message]);
  final String? message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message]);
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
