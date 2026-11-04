import 'dart:async';

import 'package:sevanest_customer/features/addresses/domain/address.dart';

/// The photo flow is built and tested ahead of the backend (Q-138); production ships it off.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  addressPhotoEnabled = true;
  await testMain();
}
