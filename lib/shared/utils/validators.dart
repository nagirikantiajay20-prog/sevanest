/// Client-side checks for instant feedback only; the backend stays authoritative (AGENTS §87).
final _name = RegExp(r"^\p{L}[\p{L}\p{M} .'-]*$", unicode: true);
final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final _pincode = RegExp(r'^[1-9]\d{5}$');

bool isValidName(String v) {
  final t = v.trim();
  return t.length >= 2 && t.length <= 60 && _name.hasMatch(t);
}

bool isValidEmail(String v) => _email.hasMatch(v.trim());

bool isValidPincode(String v) => _pincode.hasMatch(v.trim());

/// True for empty or whitespace-only text (required notes must not pass on spaces alone).
bool isBlank(String? v) => v == null || v.trim().isEmpty;

/// True when trimmed text is within [max] characters. Callers show a counter; never truncate.
bool withinMax(String v, int max) => v.trim().length <= max;

/// OTP is exactly [length] digits (length comes from the backend contract, not guessed here).
bool isValidOtp(String v, int length) =>
    v.length == length && RegExp(r'^\d+$').hasMatch(v);

/// Optional min/max rupee pair: either may be null; when both are set, min must not exceed max.
bool isValidRange(num? min, num? max) =>
    (min == null || min >= 0) &&
    (max == null || max >= 0) &&
    (min == null || max == null || min <= max);
