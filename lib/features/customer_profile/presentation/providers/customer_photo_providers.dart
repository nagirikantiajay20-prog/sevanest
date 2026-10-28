import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_photo_repository_demo.dart';
import 'package:sevanest_customer/features/customer_profile/data/customer_photo_repository_remote.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';

/// Kept on the device while the demo login is active (dev flavor); otherwise the backend.
final customerPhotoRepositoryProvider = Provider<CustomerPhotoRepository>(
  (ref) => ref.watch(demoLoginProvider)
      ? CustomerPhotoRepositoryDemo()
      : CustomerPhotoRepositoryRemote(ref.watch(dioProvider)),
);

/// `GET /customers/me/photo`. A failed read just means no photo is shown (initials stay).
/// Auto-disposed so one customer's photo never outlives their session.
class ProfilePhotoNotifier extends AsyncNotifier<ProfilePhoto?> {
  @override
  Future<ProfilePhoto?> build() async {
    try {
      return await ref.read(customerPhotoRepositoryProvider).current();
    } on AppFailure {
      return null;
    }
  }

  /// Throws the [AppFailure] when the upload fails, so the screen can say why.
  Future<void> upload(PickedPhoto photo) async {
    await ref.read(customerPhotoRepositoryProvider).upload(photo);
    // The backend link is short-lived: show the bytes we just sent.
    state = AsyncData(ProfilePhoto(bytes: photo.bytes));
  }
}

final profilePhotoProvider =
    AsyncNotifierProvider.autoDispose<ProfilePhotoNotifier, ProfilePhoto?>(
      ProfilePhotoNotifier.new,
    );
