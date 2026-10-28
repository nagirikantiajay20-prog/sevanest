import 'dart:math';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/auth_interceptor.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The number of the signed-in demo customer; the demo profile and addresses are stored under it.
const demoMobileKey = 'demo_auth_mobile';

/// Dev flavor only: the backend no longer verifies OTPs, so a random code is generated here and
/// shown on the OTP screen. The session is a placeholder: every other `/api` call still returns
/// 401 until the backend issues real tokens, so the demo profile and addresses are kept on the
/// device too. A number is an "existing" customer once it has saved a demo profile.
class AuthRepositoryDemo implements AuthRepository {
  AuthRepositoryDemo({Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;
  String? _code;
  DateTime? _issuedAt;

  @override
  Future<OtpChallenge> requestOtp(String mobile) async {
    _code = (100000 + _random.nextInt(900000)).toString();
    _issuedAt = _now();
    return OtpChallenge(otp: _code);
  }

  @override
  Future<AuthTokens> verifyOtp(String mobile, String otp) async {
    final issued = _issuedAt;
    const ttl = Duration(seconds: 300);
    if (_code == null || issued == null || _now().difference(issued) > ttl) {
      throw const OtpFailure(OtpError.expired);
    }
    if (otp != _code) throw const OtpFailure(OtpError.invalid);
    _code = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(demoMobileKey, mobile);
    return (
      access: '${demoTokenPrefix}access-$mobile',
      refresh: '${demoTokenPrefix}refresh-$mobile',
    );
  }

  @override
  Future<bool> profileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(demoMobileKey);
    return mobile != null && prefs.containsKey(demoProfileKey(mobile));
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(demoMobileKey);
  }
}

String demoProfileKey(String mobile) => 'demo_profile_$mobile';
String demoAddressesKey(String mobile) => 'demo_addresses_$mobile';
