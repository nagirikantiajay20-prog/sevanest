import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';

final _safeSegment = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// True when a location carries something the app never produces: a path segment or an `...Id`
/// query value that is not a plain backend id (same shape the push router accepts). A booking or
/// payment id from a route is only a request; the backend still decides ownership.
bool hasUnsafeRouteParams(Uri uri) {
  if (uri.pathSegments.any((s) => s.isNotEmpty && !_safeSegment.hasMatch(s))) {
    return true;
  }
  return uri.queryParameters.entries.any(
    (e) =>
        e.key.toLowerCase().endsWith('id') &&
        e.value.isNotEmpty &&
        !_safeSegment.hasMatch(e.value),
  );
}

/// Pure redirect rules (AGENTS §9). Returns null to stay on [location].
/// [profileComplete]: null = not yet known (the splash flow resolves it via GET /me).
String? resolveRedirect({
  required AuthStatus auth,
  required bool? profileComplete,
  required String location,
  Uri? uri,

  /// Developer-only screens (`/dev/*`) are reachable only when the build allows them.
  bool allowDev = true,
}) {
  if (location.startsWith('/dev/')) return allowDev ? null : Routes.home;
  const publicPaths = {Routes.login, Routes.otp};

  switch (auth) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;

    case AuthStatus.unauthenticated:
      return publicPaths.contains(location) ? null : Routes.login;

    case AuthStatus.authenticated:
      if (profileComplete == false) {
        final allowed =
            location == Routes.profileSetup || location == Routes.addressNew;
        return allowed ? null : Routes.profileSetup;
      }
      if (location == Routes.splash && profileComplete == null) return null;
      final leaveAuthScreens =
          location == Routes.splash ||
          location == Routes.profileSetup ||
          publicPaths.contains(location);
      if (leaveAuthScreens) return Routes.home;
      return uri != null && hasUnsafeRouteParams(uri) ? Routes.home : null;
  }
}
