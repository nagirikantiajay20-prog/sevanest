import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/home/data/home_repository_remote.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';

/// `GET /customers/me/home`, always the backend (tests override with a fake).
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryRemote(ref.watch(dioProvider)),
);

/// Home aggregate. Re-fetches when the dev menu changes the mock behaviour.
class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() {
    ref.watch(mockApiProvider);
    return ref.read(homeRepositoryProvider).fetch();
  }

  /// Pull-to-refresh / Retry. Shows the skeleton again only when there is no data yet.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // surfaced through [state]
    }
  }
}

final homeProvider = AsyncNotifierProvider.autoDispose<HomeNotifier, HomeData>(
  HomeNotifier.new,
);

/// Bell badge: `GET /notifications/unread-count`, falling back to the Home aggregate until it is read.
final unreadCountProvider = Provider.autoDispose<int>(
  (ref) =>
      ref.watch(notificationUnreadProvider).value ??
      ref.watch(homeProvider).value?.unreadCount ??
      0,
);

/// Address picked from Home's chip. Scopes discovery only; the server default is untouched
/// (modules/03). Module 3's Location step starts from this.
class SelectedAddressNotifier extends Notifier<Address?> {
  @override
  Address? build() => null;

  // ignore: use_setters_to_change_properties
  void set(Address? a) => state = a;
}

final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, Address?>(
      SelectedAddressNotifier.new,
    );
