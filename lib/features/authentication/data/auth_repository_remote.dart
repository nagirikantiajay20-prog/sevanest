import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/error_mapper.dart';
import 'package:sevanest_customer/core/storage/device_id_store.dart';
import 'package:sevanest_customer/features/authentication/domain/auth_repository.dart';

const _appType = 'CUSTOMER';

/// Talks to the deployed backend (`/api/v1`, see docs/05_API_CONTRACT_ASSUMPTIONS.md).
class AuthRepositoryRemote implements AuthRepository {
  AuthRepositoryRemote(this._dio, this._deviceId);

  final Dio _dio;
  final DeviceIdStore _deviceId;

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<OtpChallenge> requestOtp(String mobile) async {
    final res = await _send(
      () => _dio.post<dynamic>(
        '/auth/otp/request',
        data: {'mobile': mobile, 'appType': _appType},
      ),
    );
    final data = res.data;
    final d = data is Map ? data : const <String, dynamic>{};
    const fallback = OtpChallenge();
    return OtpChallenge(
      expiresInSeconds:
          _positive(d['expiresInSeconds']) ?? fallback.expiresInSeconds,
      resendAfterSeconds:
          _positive(d['resendAfterSeconds']) ?? fallback.resendAfterSeconds,
    );
  }

  @override
  Future<AuthTokens> verifyOtp(String mobile, String otp) async {
    final deviceId = await _deviceId.get();
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        '/auth/otp/verify',
        data: {
          'mobile': mobile,
          'appType': _appType,
          'otp': otp,
          'deviceId': deviceId,
        },
      );
    } on DioException catch (e) {
      throw _otpFailure(e) ?? mapDioError(e);
    }
    final tokens = parseTokens(res.data);
    if (tokens == null) throw const UnknownFailure();
    return tokens;
  }

  @override
  Future<bool> profileComplete() async {
    try {
      await _dio.get<dynamic>('/customers/me');
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 404 &&
          data is Map &&
          data['code'] == 'CUSTOMER_PROFILE_NOT_FOUND') {
        return false;
      }
      throw mapDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    await _send(() => _dio.post<dynamic>('/auth/logout'));
  }
}

int? _positive(Object? v) => v is num && v > 0 ? v.toInt() : null;

/// Confirmed live: `OTP_EXPIRED` (also "never requested") and `OTP_INVALID` (5 attempts per code).
/// The lock-out code after the last attempt was not observed (UNVERIFIED): LOCK/ATTEMPT/MAX ->
/// locked, any other `OTP_*` -> wrong code.
/// HTTP 429 is NOT handled here: it surfaces as `RateLimitedFailure` (with Retry-After).
OtpFailure? _otpFailure(DioException e) {
  final data = e.response?.data;
  if (data is! Map) return null;
  final code = data['code'];
  if (code is! String || !code.contains('OTP')) return null;
  // Validation errors can send a list of messages; only a plain string is shown.
  final raw = data['message'];
  final message = raw is String ? raw : null;
  if (code.contains('EXPIRED')) return OtpFailure(OtpError.expired, message);
  if (RegExp('LOCK|ATTEMPT|MAX|TOO_MANY').hasMatch(code)) {
    return OtpFailure(OtpError.locked, message);
  }
  return OtpFailure(OtpError.invalid, message);
}

/// Verified live (verify and refresh share it): `{accessToken, refreshToken, tokenType, expiresIn,
/// user{id,type,isNewUser}}`. Returns null (fail closed) when either token is missing.
AuthTokens? parseTokens(Object? body) {
  if (body is! Map) return null;
  final access = body['accessToken'];
  final refresh = body['refreshToken'];
  if (access is String && access.isNotEmpty) {
    if (refresh is String && refresh.isNotEmpty) {
      return (access: access, refresh: refresh);
    }
  }
  return null;
}
