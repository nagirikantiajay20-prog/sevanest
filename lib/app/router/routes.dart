/// Single source of route paths (AGENTS §58). Keep in sync with
/// docs/modules/15_navigation_map_and_functional_flows.md (a test enforces this).
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/otp';
  static const profileSetup = '/profile/setup';
  static const profile = '/profile';

  // Shell tabs
  static const home = '/home';
  static const bookings = '/bookings';
  static const favourites = '/favourites';
  static const account = '/account';

  // Addresses
  static const addresses = '/addresses';
  static const addressNew = '/addresses/new';
  static const addressEdit = '/addresses/:id/edit';

  // Discovery
  static const discoverCategory = '/discover/category';
  static const discoverEngagement = '/discover/engagement';
  static const discoverLocation = '/discover/location';
  static const discoverTiming = '/discover/timing';
  static const discoverStartDate = '/discover/start-date';
  static const discoverBudget = '/discover/budget';
  static const discoverReview = '/discover/review';

  // Workers
  static const workers = '/workers';
  static const workerDetail = '/workers/:id';
  static const workerReviews = '/workers/:id/reviews';

  // Interviews
  static const interviews = '/interviews';
  static const interviewNew = '/interviews/new';
  static const interviewDetail = '/interviews/:id';

  // Booking & payment
  static const bookingConfirm = '/bookings/confirm';
  static const bookingDetail = '/bookings/:id';
  static const payment = '/payments/:id';
  static const transactions = '/transactions';
  static const transactionDetail = '/transactions/:id';

  // Service
  static const serviceCurrent = '/services/current';
  static const serviceHistory = '/services/history';
  static const rating = '/ratings/:id';

  // Replacement
  static const replacementNew = '/replacements/new';
  static const replacementDetail = '/replacements/:id';

  // Support & notifications
  static const support = '/support';
  static const supportNew = '/support/new';
  static const supportDetail = '/support/:id';
  static const notifications = '/notifications';

  /// Notification / push deep links open here first: `/open?to=<entity route>` reads the entity
  /// fresh, then replaces itself with the screen, or says it is not available.
  static const open = '/open';

  // Dev only (never registered in prod)
  static const devGallery = '/dev/gallery';
  static const devPushDiagnostics = '/dev/push';

  /// Builds a concrete path, e.g. `Routes.path(Routes.bookingDetail, {'id': '7'})`.
  static String path(String pattern, Map<String, String> params) =>
      params.entries.fold(
        pattern,
        (p, e) => p.replaceAll(':${e.key}', Uri.encodeComponent(e.value)),
      );
}
