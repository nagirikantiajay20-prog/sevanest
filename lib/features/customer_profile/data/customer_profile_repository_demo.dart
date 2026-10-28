import 'dart:convert';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_demo.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dev flavor only: keeps the profile on the device for the demo login (the backend would answer
/// 401 to the placeholder token). One profile per mobile number.
class CustomerProfileRepositoryDemo implements CustomerProfileRepository {
  Future<(SharedPreferences, String)> _slot() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(demoMobileKey);
    if (mobile == null) throw const UnauthorizedFailure();
    return (prefs, mobile);
  }

  @override
  Future<CustomerProfile> get() async {
    final (prefs, mobile) = await _slot();
    final raw = prefs.getString(demoProfileKey(mobile));
    if (raw == null) throw const NotFoundFailure();
    return _parse(raw, mobile);
  }

  @override
  Future<CustomerProfile> create({
    required String name,
    required String email,
    required String preferredLanguage,
  }) async {
    final (prefs, mobile) = await _slot();
    if (prefs.containsKey(demoProfileKey(mobile))) {
      throw const ConflictFailure();
    }
    return _save(prefs, mobile, name, email, preferredLanguage);
  }

  @override
  Future<CustomerProfile> update({
    required String name,
    required String email,
    required String preferredLanguage,
  }) async {
    final (prefs, mobile) = await _slot();
    return _save(prefs, mobile, name, email, preferredLanguage);
  }

  Future<CustomerProfile> _save(
    SharedPreferences prefs,
    String mobile,
    String name,
    String email,
    String language,
  ) async {
    final body = {
      'name': name.trim(),
      'email': email.trim(),
      'preferredLanguage': language,
    };
    await prefs.setString(demoProfileKey(mobile), jsonEncode(body));
    return _parse(jsonEncode(body), mobile);
  }

  CustomerProfile _parse(String raw, String mobile) {
    final d = jsonDecode(raw) as Map<String, dynamic>;
    return CustomerProfile(
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      preferredLanguage: d['preferredLanguage'] as String? ?? 'en',
      mobile: mobile,
    );
  }
}
