import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// The customer's in-progress requirement. Built by modules 3-4, read by Review and Results.
/// Module 4 adds timing, start date and budget.
class RequirementDraft {
  const RequirementDraft({this.serviceId, this.engagement, this.address});

  final String? serviceId;
  final EngagementType? engagement;

  /// Snapshot of the chosen address (kept so Review works offline and survives an app restart).
  final Address? address;

  bool get isEmpty =>
      serviceId == null && engagement == null && address == null;

  RequirementDraft copyWith({
    String? serviceId,
    EngagementType? engagement,
    Address? address,
  }) => RequirementDraft(
    serviceId: serviceId ?? this.serviceId,
    engagement: engagement ?? this.engagement,
    address: address ?? this.address,
  );

  Map<String, Object?> toJson() => {
    'serviceId': serviceId,
    'engagement': engagement?.name,
    'address': address == null
        ? null
        : {
            'id': address!.id,
            'line': address!.line,
            'area': address!.area,
            'city': address!.city,
            'pincode': address!.pincode,
            'isDefault': address!.isDefault,
          },
  };

  factory RequirementDraft.fromJson(Map<String, dynamic> j) {
    final a = j['address'] as Map<String, dynamic>?;
    final e = j['engagement'] as String?;
    return RequirementDraft(
      serviceId: j['serviceId'] as String?,
      engagement: e == null ? null : EngagementType.values.byName(e),
      address: a == null
          ? null
          : Address(
              id: a['id'] as String,
              line: a['line'] as String,
              area: a['area'] as String,
              city: a['city'] as String,
              pincode: a['pincode'] as String,
              isDefault: a['isDefault'] as bool? ?? false,
            ),
    );
  }
}
