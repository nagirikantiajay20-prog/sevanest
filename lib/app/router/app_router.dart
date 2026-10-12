import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/dev/widget_gallery_screen.dart';
import 'package:sevanest_customer/app/router/main_shell.dart';
import 'package:sevanest_customer/app/router/redirect.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/widgets/placeholder_screen.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_list_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/login_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/otp_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/account_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/profile_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/profile_setup_screen.dart';
import 'package:sevanest_customer/features/home/presentation/screens/home_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/budget_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/engagement_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/location_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/service_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/start_date_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/timing_screen.dart';

GoRoute _placeholder(String path, String title) =>
    GoRoute(path: path, builder: (context, state) => PlaceholderScreen(title));

/// Real screens replace the placeholders module by module (docs/modules/*).
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authProvider, (_, _) => refresh.value++)
    ..listen(profileCompleteProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      auth: ref.read(authProvider),
      profileComplete: ref.read(profileCompleteProvider),
      location: state.uri.path,
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(path: Routes.otp, builder: (context, state) => const OtpScreen()),
      GoRoute(
        path: Routes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.addresses,
        builder: (context, state) => AddressListScreen(
          selectMode: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(
        path: Routes.addressNew,
        builder: (context, state) => AddressFormScreen(
          firstTime: state.uri.queryParameters['firstTime'] == 'true',
          prefill: state.extra is AddressInput
              ? state.extra! as AddressInput
              : null,
        ),
      ),
      GoRoute(
        path: Routes.addressEdit,
        builder: (context, state) =>
            AddressFormScreen(addressId: state.pathParameters['id']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(Routes.bookings, 'Bookings')],
          ),
          StatefulShellBranch(
            routes: [_placeholder(Routes.favourites, 'Shortlist')],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      // Targets Home links to; each is replaced by its real screen in its own module.
      GoRoute(
        path: Routes.discoverCategory,
        builder: (context, state) =>
            ServiceScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      GoRoute(
        path: Routes.discoverEngagement,
        builder: (context, state) =>
            EngagementScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      GoRoute(
        path: Routes.discoverLocation,
        builder: (context, state) =>
            LocationScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      GoRoute(
        path: Routes.discoverTiming,
        builder: (context, state) =>
            TimingScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      GoRoute(
        path: Routes.discoverStartDate,
        builder: (context, state) =>
            StartDateScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      GoRoute(
        path: Routes.discoverBudget,
        builder: (context, state) =>
            BudgetScreen(edit: state.uri.queryParameters['edit'] == 'true'),
      ),
      // Module 5 replaces this with the real Review screen.
      _placeholder(Routes.discoverReview, 'Review your requirement'),
      _placeholder(Routes.notifications, 'Notifications'),
      _placeholder(Routes.support, 'Support'),
      _placeholder(Routes.interviewDetail, 'Interview'),
      _placeholder(Routes.bookingDetail, 'Booking'),
      _placeholder(Routes.workerDetail, 'Worker'),
      if (config.env == AppEnv.dev)
        GoRoute(
          path: Routes.devGallery,
          builder: (context, state) => const WidgetGalleryScreen(),
        ),
    ],
  );
});
