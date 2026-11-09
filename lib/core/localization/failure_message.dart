import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Maps any error to user-facing text. Backend-supplied messages are shown for 4xx business errors
/// (validation / conflict) only, and only when they read like a sentence for a person: anything
/// that looks technical (exception names, SQL, stack traces, JSON, status codes) is replaced.
String failureMessage(AppLocalizations l10n, Object error) {
  final plain = _known(l10n, error);
  if (plain != null) return plain;
  if ((error is ValidationFailure || error is ConflictFailure) &&
      error is AppFailure &&
      isCustomerSafe(error.message)) {
    return error.message!;
  }
  // A 409 with no readable reason is almost always "someone already changed this".
  if (error is ConflictFailure) return l10n.errorConflictGeneric;
  return l10n.errorGeneric;
}

String? _known(AppLocalizations l10n, Object error) {
  if (isNotServiceable(error)) return l10n.locationNotServed;
  if (error is ConflictFailure) {
    switch (error.code) {
      case 'DUPLICATE_BOOKING':
        return l10n.errorDuplicateBooking;
      case 'WORKER_UNAVAILABLE':
        return l10n.errorWorkerUnavailable;
    }
  }
  if (error is NetworkFailure) {
    if (error.offline) return l10n.errorOffline;
    return error.timedOut ? l10n.errorTimeout : l10n.errorNetwork;
  }
  if (error is UnauthorizedFailure) return l10n.errorSessionExpired;
  if (error is ForbiddenFailure) return l10n.errorForbidden;
  if (error is NotFoundFailure) return l10n.errorNotFound;
  if (error is RateLimitedFailure) {
    final s = error.retryAfterSeconds;
    return s == null ? l10n.errorRateLimited : l10n.errorRateLimitedIn(s);
  }
  if (error is ServerFailure) return l10n.errorServer;
  return null;
}

final _technical = RegExp(
  r'exception|error:|stack ?trace|\bsql\b|prisma|\bnull\b|undefined|\bhttps?\b|status ?code|econn|[{}<>]|\.dart',
  caseSensitive: false,
);

/// True when a backend message is short, plain text that is safe to show a customer.
bool isCustomerSafe(String? m) =>
    m != null &&
    m.trim().contains(' ') && // a sentence, not a bare code like ERR_STATE
    m.length <= 200 &&
    !_technical.hasMatch(m);

/// Like [failureMessage] but never shows text the server wrote (support, safety and notification
/// screens map the codes they know themselves and fall back to this).
String plainFailureMessage(AppLocalizations l10n, Object error) {
  return _known(l10n, error) ?? l10n.errorGeneric;
}

/// Booking refused because the address or area is outside the enabled service areas (422).
bool isNotServiceable(Object error) =>
    error is ValidationFailure &&
    const {
      'OUTSIDE_SERVICE_AREA',
      'AREA_NOT_AVAILABLE',
      'ADDRESS_NOT_SERVICEABLE',
    }.contains(error.code);
