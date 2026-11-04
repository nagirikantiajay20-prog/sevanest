import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';

/// Saved address (OpenAPI `CreateAddressDto`). [label], [line2] and [state] are optional.
class Address {
  const Address({
    required this.id,
    required this.line,
    required this.area,
    required this.city,
    required this.pincode,
    this.label,
    this.line2,
    this.state,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.photoUrl,
    this.isServiceable,
    this.unserviceableReason,
  });

  final String id;

  /// House / flat.
  final String line;

  /// Building / street.
  final String? line2;

  /// "Home", "Parents' home" (what the customer calls it).
  final String? label;
  final String? state;
  final String area;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  /// Short-lived link to the home photo, when one was uploaded.
  final String? photoUrl;

  /// Server verdict from the enabled service areas; null when the backend sent none (older API).
  final bool? isServiceable;

  /// `CITY_NOT_SERVICEABLE` or `AREA_NOT_SERVICEABLE` when [isServiceable] is false.
  final String? unserviceableReason;

  /// House and street on one line.
  String get fullLine =>
      [line, line2].where((s) => s != null && s.isNotEmpty).join(', ');

  /// What titles the card: the customer's label, else the area.
  String get title => label != null && label!.isNotEmpty
      ? label!
      : (area.isEmpty ? city : area);
}

/// Request body for create/edit. [isDefault] is create-only; edit uses `PUT .../default`.
class AddressInput {
  const AddressInput({
    required this.line,
    required this.area,
    required this.city,
    required this.pincode,
    this.label,
    this.line2,
    this.state,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  final String line;
  final String? line2;
  final String? label;
  final String? state;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;

  /// From the device location, when the customer used it (the API accepts both or neither).
  final double? latitude;
  final double? longitude;
}

/// `GET /service-areas` item (success schema unpublished: only id/name/city are read).
class ServiceArea {
  const ServiceArea({required this.id, required this.name, this.city});
  final String id;
  final String name;
  final String? city;
}

abstract interface class AddressRepository {
  /// `GET /customers/me/addresses`, default first.
  Future<List<Address>> list();

  /// `POST /customers/me/addresses`.
  Future<Address> create(AddressInput input);

  /// `PATCH /customers/me/addresses/{id}`.
  Future<Address> update(String id, AddressInput input);

  /// `DELETE /customers/me/addresses/{id}` (soft delete).
  Future<void> delete(String id);

  /// `PUT /customers/me/addresses/{id}/default` (idempotent).
  Future<void> setDefault(String id);

  /// `GET /service-areas?city=` (enabled areas).
  Future<List<ServiceArea>> serviceAreas({String? city});

  /// Home photo of an address: `POST .../{id}/photo` (pre-signed `PUT` link), upload, then
  /// `POST .../photo/{photoId}/confirm`. Assumed contract, mirrors `/customers/me/photo`.
  Future<void> uploadPhoto(String id, PickedPhoto photo);

  /// `DELETE /customers/me/addresses/{id}/photo`.
  Future<void> removePhoto(String id);

  /// `GET /locations/service-area`: the enabled area for a device position and / or a geocoded
  /// name. Null when none matches (the customer picks the area).
  Future<ServiceArea?> resolveServiceArea({
    double? latitude,
    double? longitude,
    String? name,
    String? city,
  });
}

/// Fallback only, for a backend that sends no `isServiceable` (the server flag wins).
bool isServiceableCity(String city) => city.trim().toLowerCase() == 'hyderabad';

/// The backend has no address photo route or column (Q-138, still open), so the photo field is
/// hidden and not required. Flip when the backend ships it. Tests set it true (test/flutter_test_config.dart).
bool addressPhotoEnabled = false;

/// The enabled service area's id for an address's area name (trimmed, case-insensitive), or null.
/// Backend area names are edited by staff, so an exact `==` silently dropped customers' searches.
String? serviceAreaIdFor(List<ServiceArea> areas, String name) {
  final n = name.trim().toLowerCase();
  return areas.where((a) => a.name.trim().toLowerCase() == n).firstOrNull?.id;
}
