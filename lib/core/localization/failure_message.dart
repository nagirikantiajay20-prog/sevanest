import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Maps any error to user-facing text. Backend-supplied messages are shown for 4xx business errors only.
String failureMessage(AppLocalizations l10n, Object error) {
  if (isNotServiceable(error)) return l10n.locationNotServed;
  if (error is NetworkFailure) return l10n.errorNetwork;
  if (error is UnauthorizedFailure) return l10n.errorSessionExpired;
  if (error is ForbiddenFailure) return l10n.errorForbidden;
  if (error is ServerFailure) return l10n.errorServer;
  if (error is AppFailure && error.message != null) return error.message!;
  return l10n.errorGeneric;
}

/// Like [failureMessage] but never shows text the server wrote (support, safety and notification
/// screens map the codes they know themselves and fall back to this).
String plainFailureMessage(AppLocalizations l10n, Object error) {
  if (isNotServiceable(error)) return l10n.locationNotServed;
  if (error is NetworkFailure) return l10n.errorNetwork;
  if (error is UnauthorizedFailure) return l10n.errorSessionExpired;
  if (error is ForbiddenFailure) return l10n.errorForbidden;
  if (error is ServerFailure) return l10n.errorServer;
  return l10n.errorGeneric;
}

/// Booking refused because the address or area is outside the enabled service areas (422).
bool isNotServiceable(Object error) =>
    error is ValidationFailure &&
    const {
      'OUTSIDE_SERVICE_AREA',
      'AREA_NOT_AVAILABLE',
      'ADDRESS_NOT_SERVICEABLE',
    }.contains(error.code);
