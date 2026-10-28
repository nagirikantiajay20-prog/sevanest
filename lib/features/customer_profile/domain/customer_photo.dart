import 'dart:typed_data';

/// A photo chosen on the device, ready to upload (`image/jpeg` or `image/png` only).
class PickedPhoto {
  const PickedPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;

  /// PNG when the file starts with the PNG signature, JPEG otherwise.
  factory PickedPhoto.fromBytes(Uint8List bytes) {
    final png =
        bytes.length > 3 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return PickedPhoto(bytes, png ? 'image/png' : 'image/jpeg');
  }
}

/// The customer's current photo: a short-lived [url] from the backend (never stored) or, right
/// after an upload / on the demo login, the [bytes] themselves.
class ProfilePhoto {
  const ProfilePhoto({this.url, this.bytes});
  final String? url;
  final Uint8List? bytes;
}

/// `GET|POST /customers/me/photo` and `POST /customers/me/photo/{photoId}/confirm`.
abstract interface class CustomerPhotoRepository {
  /// Null when the customer has no photo (404).
  Future<ProfilePhoto?> current();

  /// Asks for an upload link, sends the bytes to it, then confirms.
  Future<void> upload(PickedPhoto photo);
}
