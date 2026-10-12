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
