typedef AuthTokens = ({String access, String refresh});

/// `POST /auth/otp/request` response (verified live): both fields in seconds.
class OtpChallenge {
  const OtpChallenge({
    this.expiresInSeconds = 300,
    this.resendAfterSeconds = 30,
  });
  final int expiresInSeconds;
  final int resendAfterSeconds;
}

abstract interface class AuthRepository {
  /// `POST /auth/otp/request`. Throws [AppFailure] (rate limit, SMS unavailable, account type...).
  Future<OtpChallenge> requestOtp(String mobile);

  /// `POST /auth/otp/verify`. Throws `OtpFailure` for wrong / expired / locked codes.
  Future<AuthTokens> verifyOtp(String mobile, String otp);

  /// `GET /customers/me`: 200 = profile exists (complete), 404 CUSTOMER_PROFILE_NOT_FOUND = not yet.
  Future<bool> profileComplete();

  /// `POST /auth/logout`. Callers treat failure as best-effort.
  Future<void> logout();
}

/// Customer app OTP length is server configuration; the approved design uses 6 digits.
const otpLength = 6;

final _mobile = RegExp(r'^[6-9]\d{9}$');
bool isValidMobile(String digits) => _mobile.hasMatch(digits);
