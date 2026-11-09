/// Schemes the app may hand to the operating system. Everything else (intent:, file:, javascript:,
/// custom app schemes, http:) is refused, whatever the backend or a build setting says.
const webSchemes = {'https'};

/// Store pages: the HTTPS listing or the Play Store app link.
const storeSchemes = {'https', 'market'};

/// Support contact built by the app itself.
const contactSchemes = {'tel', 'mailto'};

const _maxLength = 2048;
final _unsafeChars = RegExp(r'[\x00-\x20\x7f]');

/// [raw] as a [Uri] if, and only if, it is a well-formed absolute URL with one of [schemes].
///
/// Rejects null/blank/oversized text, whitespace or control characters, a missing scheme, a scheme
/// outside [schemes], an `https` URL with no host or with embedded credentials (`user:pw@host`).
Uri? parseAllowedUri(String? raw, {Set<String> schemes = webSchemes}) {
  final text = raw?.trim();
  if (text == null || text.isEmpty || text.length > _maxLength) return null;
  if (_unsafeChars.hasMatch(text)) return null;
  final uri = Uri.tryParse(text);
  return uri != null && isAllowedUri(uri, schemes: schemes) ? uri : null;
}

/// Same rules for a [Uri] that was already built.
bool isAllowedUri(Uri uri, {Set<String> schemes = webSchemes}) {
  if (!uri.hasScheme || !schemes.contains(uri.scheme.toLowerCase())) {
    return false;
  }
  if (uri.scheme == 'tel' || uri.scheme == 'mailto') return uri.path.isNotEmpty;
  return uri.host.isNotEmpty && uri.userInfo.isEmpty;
}
