import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Maps any error to user-facing text. Backend-supplied messages are shown for 4xx business errors only.
String failureMessage(AppLocalizations l10n, Object error) {
  if (error is NetworkFailure) return l10n.errorNetwork;
  if (error is UnauthorizedFailure) return l10n.errorSessionExpired;
  if (error is ForbiddenFailure) return l10n.errorForbidden;
  if (error is ServerFailure) return l10n.errorServer;
  if (error is AppFailure && error.message != null) return error.message!;
  return l10n.errorGeneric;
}
