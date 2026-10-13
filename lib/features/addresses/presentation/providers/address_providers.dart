import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/shared/utils/submit_state.dart';

/// Hyderabad is the launch market (AGENTS header); the form pre-fills it, the user can change it.
const defaultCity = 'Hyderabad';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepositoryRemote(ref.watch(dioProvider)),
);

/// `GET /customers/me/addresses`. Auto-disposed so addresses never outlive the session.
class AddressesNotifier extends AsyncNotifier<List<Address>> {
  bool _mutating = false;

  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() => _repo.list();

  /// Pull-to-refresh / retry. Riverpod keeps the earlier list when the reload fails (stale banner).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // surfaced through [state]
    }
  }

  Future<AppFailure?> setDefault(String id) =>
      _mutate(() => _repo.setDefault(id));

  Future<AppFailure?> delete(String id) => _mutate(() => _repo.delete(id));

  /// Runs one mutation at a time, then re-reads the authoritative list (AGENTS §65).
  Future<AppFailure?> _mutate(Future<void> Function() call) async {
    if (_mutating) return null;
    _mutating = true;
    try {
      await call();
      await refresh();
      return null;
    } on AppFailure catch (f) {
      return f;
    } finally {
      _mutating = false;
    }
  }
}

final addressesProvider =
    AsyncNotifierProvider.autoDispose<AddressesNotifier, List<Address>>(
      AddressesNotifier.new,
    );

/// `GET /service-areas` for the area picker. Failure only disables the picker (free text remains).
final serviceAreasProvider = FutureProvider.autoDispose<List<ServiceArea>>(
  (ref) => ref.watch(addressRepositoryProvider).serviceAreas(city: defaultCity),
);

/// Create / edit / delete from the form screen.
class AddressFormController extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState();

  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  /// [id] null = create. For an edit, [makeDefault] triggers `PUT .../default` after the `PATCH`.
  Future<Address?> save({
    required AddressInput input,
    String? id,
    bool makeDefault = false,
  }) async {
    if (state.busy) return null;
    state = const SubmitState(busy: true);
    try {
      final Address saved;
      if (id == null) {
        saved = await _repo.create(input);
      } else {
        saved = await _repo.update(id, input);
        if (makeDefault) await _repo.setDefault(id);
      }
      ref.invalidate(addressesProvider);
      state = const SubmitState();
      return saved;
    } on AppFailure catch (f) {
      state = SubmitState(failure: f);
      return null;
    }
  }

  /// Returns true when deleted; a failure (e.g. 409 in use) is left in [state].
  Future<bool> delete(String id) async {
    if (state.busy) return false;
    state = const SubmitState(busy: true);
    try {
      await _repo.delete(id);
      ref.invalidate(addressesProvider);
      state = const SubmitState();
      return true;
    } on AppFailure catch (f) {
      state = SubmitState(failure: f);
      return false;
    }
  }
}

final addressFormProvider =
    NotifierProvider.autoDispose<AddressFormController, SubmitState>(
      AddressFormController.new,
    );

/// The service area for what the device location found, or null (the customer picks it). The
/// resolved name is the one the backend knows, so it can be used for search and bookings.
Future<ServiceArea?> resolveFoundArea(WidgetRef ref, AddressInput found) async {
  try {
    return await ref
        .read(addressRepositoryProvider)
        .resolveServiceArea(
          latitude: found.latitude,
          longitude: found.longitude,
          name: found.area,
          city: found.city,
        );
  } on Object {
    return null;
  }
}
