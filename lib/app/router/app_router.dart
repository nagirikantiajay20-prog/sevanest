import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/dev/widget_gallery_screen.dart';
import 'package:sevanest_customer/app/router/main_shell.dart';
import 'package:sevanest_customer/app/router/redirect.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/active_service/presentation/screens/active_service_screen.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_list_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/login_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/otp_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart';
import 'package:sevanest_customer/features/booking/presentation/screens/booking_detail_screen.dart';
import 'package:sevanest_customer/features/booking/presentation/screens/bookings_list_screen.dart';
import 'package:sevanest_customer/features/booking/presentation/screens/confirm_worker_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/account_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/profile_screen.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/screens/profile_setup_screen.dart';
import 'package:sevanest_customer/features/favourites/presentation/screens/favourites_screen.dart';
import 'package:sevanest_customer/features/home/presentation/screens/home_screen.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/screens/interview_detail_screen.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/screens/interview_request_screen.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/screens/interviews_list_screen.dart';
import 'package:sevanest_customer/features/notifications/diagnostics/push_diagnostics_screen.dart';
import 'package:sevanest_customer/features/notifications/presentation/screens/deep_link_screen.dart';
import 'package:sevanest_customer/features/notifications/presentation/screens/notification_centre_screen.dart';
import 'package:sevanest_customer/features/payment/presentation/screens/payment_screen.dart';
import 'package:sevanest_customer/features/payment/presentation/screens/transaction_detail_screen.dart';
import 'package:sevanest_customer/features/payment/presentation/screens/transactions_screen.dart';
import 'package:sevanest_customer/features/ratings/presentation/screens/rating_screen.dart';
import 'package:sevanest_customer/features/replacement/presentation/screens/replacement_request_screen.dart';
import 'package:sevanest_customer/features/replacement/presentation/screens/replacement_status_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/budget_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/engagement_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/location_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/review_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/service_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/start_date_screen.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/screens/timing_screen.dart';
import 'package:sevanest_customer/features/service_history/presentation/screens/service_history_screen.dart';
import 'package:sevanest_customer/features/support/presentation/screens/new_ticket_screen.dart';
import 'package:sevanest_customer/features/support/presentation/screens/support_home_screen.dart';
import 'package:sevanest_customer/features/support/presentation/screens/ticket_detail_screen.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/screens/worker_detail_screen.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/screens/worker_reviews_screen.dart';
import 'package:sevanest_customer/features/worker_search/presentation/screens/results_screen.dart';

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
            routes: [
              GoRoute(
                path: Routes.favourites,
                builder: (context, state) => const FavouritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.bookings,
                builder: (context, state) => const BookingsListScreen(),
              ),
            ],
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
        builder: (context, state) => ServiceScreen(
          edit: state.uri.queryParameters['edit'] == 'true',
          searchFirst: state.uri.queryParameters['search'] == 'true',
        ),
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
      GoRoute(
        path: Routes.discoverReview,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationCentreScreen(),
      ),
      GoRoute(
        path: Routes.open,
        builder: (context, state) =>
            DeepLinkScreen(to: state.uri.queryParameters['to'] ?? ''),
      ),
      GoRoute(
        path: Routes.support,
        builder: (context, state) => const SupportHomeScreen(),
      ),
      // `new` must come before `:id`.
      GoRoute(
        path: Routes.interviews,
        builder: (context, state) => const InterviewsListScreen(),
      ),
      GoRoute(
        path: Routes.interviewNew,
        builder: (context, state) => InterviewRequestScreen(
          workerId: state.uri.queryParameters['workerId'] ?? '',
          rescheduleId: state.uri.queryParameters['rescheduleId'],
        ),
      ),
      GoRoute(
        path: Routes.interviewDetail,
        builder: (context, state) =>
            InterviewDetailScreen(interviewId: state.pathParameters['id']!),
      ),
      // `confirm` must come before `:id`.
      GoRoute(
        path: Routes.bookingConfirm,
        builder: (context, state) => ConfirmWorkerScreen(
          bookingId: state.uri.queryParameters['interviewId'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.bookingDetail,
        builder: (context, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      // Later modules replace these: payment (07), service / rating (08), replacement (09),
      // support (10).
      // `/payments/new?bookingId=` starts a payment; any other id opens that payment.
      GoRoute(
        path: Routes.payment,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentScreen(
            paymentId: id == 'new' ? null : id,
            bookingId: state.uri.queryParameters['bookingId'],
          );
        },
      ),
      GoRoute(
        path: Routes.transactions,
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: Routes.transactionDetail,
        builder: (context, state) =>
            TransactionDetailScreen(paymentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.serviceCurrent,
        builder: (context, state) => ActiveServiceScreen(
          bookingId: state.uri.queryParameters['bookingId'],
        ),
      ),
      GoRoute(
        path: Routes.serviceHistory,
        builder: (context, state) => const ServiceHistoryScreen(),
      ),
      GoRoute(
        path: Routes.rating,
        builder: (context, state) =>
            RatingScreen(bookingId: state.pathParameters['id']!),
      ),
      // `new` must come before `:id`.
      GoRoute(
        path: Routes.replacementNew,
        builder: (context, state) => ReplacementRequestScreen(
          bookingId: state.uri.queryParameters['bookingId'],
        ),
      ),
      GoRoute(
        path: Routes.replacementDetail,
        builder: (context, state) =>
            ReplacementStatusScreen(replacementId: state.pathParameters['id']!),
      ),
      // `new` must come before `:id`.
      GoRoute(
        path: Routes.supportNew,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return NewTicketScreen(
            bookingId: q['bookingId'],
            paymentId: q['paymentId'],
            replacementId: q['replacementId'],
            interviewId: q['interviewId'],
            categoryId: q['categoryId'],
            safety: q['safety'] == 'true',
          );
        },
      ),
      GoRoute(
        path: Routes.supportDetail,
        builder: (context, state) =>
            TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.workers,
        builder: (context, state) => const ResultsScreen(),
      ),
      // Reviews is longer than the detail path, so order does not matter, but keep them together.
      GoRoute(
        path: Routes.workerReviews,
        builder: (context, state) =>
            WorkerReviewsScreen(workerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.workerDetail,
        builder: (context, state) =>
            WorkerDetailScreen(workerId: state.pathParameters['id']!),
      ),
      if (config.env == AppEnv.dev)
        GoRoute(
          path: Routes.devGallery,
          builder: (context, state) => const WidgetGalleryScreen(),
        ),
      if (!config.isProd)
        GoRoute(
          path: Routes.devPushDiagnostics,
          builder: (context, state) => const PushDiagnosticsScreen(),
        ),
    ],
  );
});
