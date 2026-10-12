/// `GET /customers/me` (fields per Swagger Create/UpdateCustomerProfileDto; the success body schema is
/// not published, so everything except the three DTO fields is optional).
class CustomerProfile {
  const CustomerProfile({
    required this.name,
    required this.email,
    required this.preferredLanguage,
    this.mobile,
    this.verificationStatus,
  });

  final String name;
  final String email;
  final String preferredLanguage;
  final String? mobile;
  final String? verificationStatus;
}

abstract interface class CustomerProfileRepository {
  /// 404 `CUSTOMER_PROFILE_NOT_FOUND` surfaces as `NotFoundFailure`.
  Future<CustomerProfile> get();

  /// `POST /customers/me` (409 if the profile already exists).
  Future<CustomerProfile> create({
    required String name,
    required String email,
    required String preferredLanguage,
  });

  /// `PATCH /customers/me`.
  Future<CustomerProfile> update({
    required String name,
    required String email,
    required String preferredLanguage,
  });
}
