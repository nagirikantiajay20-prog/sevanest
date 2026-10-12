/// Saved address (Swagger CreateAddressDto). The backend has no label, line 2 or state field.
class Address {
  const Address({
    required this.id,
    required this.line,
    required this.area,
    required this.city,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String line;
  final String area;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
}

/// Request body for create/edit. [isDefault] is create-only; edit uses `PUT .../default`.
class AddressInput {
  const AddressInput({
    required this.line,
    required this.area,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  final String line;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;
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
}
