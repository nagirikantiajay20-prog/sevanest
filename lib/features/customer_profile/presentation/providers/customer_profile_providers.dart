import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_profile_repository_remote.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:sevanest_customer/shared/utils/submit_state.dart';

final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>(
  (ref) => CustomerProfileRepositoryRemote(ref.watch(dioProvider)),
);

/// Languages the design lists. Only codes the backend allows are selectable (`GET /app-config` ->
/// `languages: ["en"]`, OPEN_QUESTIONS #16).
const profileLanguages = [
  (code: 'en', label: 'English', enabled: true),
  (code: 'hi', label: 'हिन्दी', enabled: false),
  (code: 'te', label: 'తెలుగు', enabled: false),
  (code: 'ta', label: 'தமிழ்', enabled: false),
  (code: 'kn', label: 'ಕನ್ನಡ', enabled: false),
  (code: 'mr', label: 'मराठी', enabled: false),
];

/// `GET /customers/me`. Auto-disposed so one customer's data never outlives their session.
class ProfileNotifier extends AsyncNotifier<CustomerProfile> {
  @override
  Future<CustomerProfile> build() =>
      ref.read(customerProfileRepositoryProvider).get();

  // ignore: use_setters_to_change_properties
  void replace(CustomerProfile p) => state = AsyncData(p);
}

final profileProvider =
    AsyncNotifierProvider.autoDispose<ProfileNotifier, CustomerProfile>(
      ProfileNotifier.new,
    );

/// Create (`POST`) on first login, update (`PATCH`) afterwards. Ignores taps while a request runs.
class ProfileFormController extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState();

  /// Returns the saved profile, or null on failure (see [state]).
  Future<CustomerProfile?> submit({
    required bool create,
    required String name,
    required String email,
    required String preferredLanguage,
  }) async {
    if (state.busy) return null;
    state = const SubmitState(busy: true);
    final repo = ref.read(customerProfileRepositoryProvider);
    try {
      final saved = create
          ? await repo.create(
              name: name,
              email: email,
              preferredLanguage: preferredLanguage,
            )
          : await repo.update(
              name: name,
              email: email,
              preferredLanguage: preferredLanguage,
            );
      state = const SubmitState();
      return saved;
    } on AppFailure catch (f) {
      state = SubmitState(failure: f);
      return null;
    }
  }
}

final profileFormProvider =
    NotifierProvider.autoDispose<ProfileFormController, SubmitState>(
      ProfileFormController.new,
    );
