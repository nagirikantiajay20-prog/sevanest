import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';

/// Pure redirect rules (AGENTS §9). Returns null to stay on [location].
/// [profileComplete]: null = not yet known (the splash flow resolves it via GET /me).
String? resolveRedirect({
  required AuthStatus auth,
  required bool? profileComplete,
  required String location,
}) {
  if (location.startsWith('/dev/')) return null;
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
      return leaveAuthScreens ? Routes.home : null;
  }
}
