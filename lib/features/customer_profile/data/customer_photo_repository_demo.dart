import 'dart:convert';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_demo.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dev flavor only: keeps the photo on the device for the demo login (the backend would answer
/// 401 to the placeholder token). One photo per mobile number.
class CustomerPhotoRepositoryDemo implements CustomerPhotoRepository {
  Future<(SharedPreferences, String)> _slot() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(demoMobileKey);
    if (mobile == null) throw const UnauthorizedFailure();
    return (prefs, 'demo_photo_$mobile');
  }

  @override
  Future<ProfilePhoto?> current() async {
    final (prefs, key) = await _slot();
    final raw = prefs.getString(key);
    return raw == null ? null : ProfilePhoto(bytes: base64Decode(raw));
  }

  @override
  Future<void> upload(PickedPhoto photo) async {
    final (prefs, key) = await _slot();
    await prefs.setString(key, base64Encode(photo.bytes));
  }
}
