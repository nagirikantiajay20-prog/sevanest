import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';

/// The customer's in-progress requirement. Built by modules 3-4, read by Review and Results.
/// [startDate] is the first day of work, or for Hourly the date of the visit (picked on Timing).
class RequirementDraft {
  const RequirementDraft({
    this.serviceId,
    this.engagement,
    this.address,
    this.timing,
    this.startDate,
    this.budget,
  });

  final String? serviceId;
  final EngagementType? engagement;

  /// Snapshot of the chosen address (kept so Review works offline and survives an app restart).
  final Address? address;
  final Timing? timing;
  final DateTime? startDate;
  final Budget? budget;

  bool get isEmpty =>
      serviceId == null &&
      engagement == null &&
      address == null &&
      timing == null &&
      startDate == null &&
      budget == null;

  TimingVariant? get variant =>
      engagement == null ? null : timingVariantFor(engagement!);

  /// Hourly has no separate start-date step: its date is chosen on Timing.
  bool get skipsStartDateStep => engagement == EngagementType.hourly;

  /// A new service invalidates everything that depended on it (engagement, timing, budget).
  RequirementDraft withService(String id) =>
      RequirementDraft(serviceId: id, address: address);

  /// Timing the new variant can't use is dropped; a budget priced for another engagement is
  /// dropped too, so old guidance never lingers (its period / range no longer apply).
  RequirementDraft withEngagement(EngagementType e) {
    if (e == engagement) return this;
    final sameVariant =
        engagement != null &&
        timingVariantFor(engagement!) == timingVariantFor(e);
    return RequirementDraft(
      serviceId: serviceId,
      engagement: e,
      address: address,
      timing: sameVariant ? timing : null,
      startDate: startDate,
    );
  }

  RequirementDraft withAddress(Address a) => RequirementDraft(
    serviceId: serviceId,
    engagement: engagement,
    address: a,
    timing: timing,
    startDate: startDate,
    budget: budget,
  );

  RequirementDraft withTiming(Timing? t) => RequirementDraft(
    serviceId: serviceId,
    engagement: engagement,
    address: address,
    timing: t,
    startDate: startDate,
    budget: budget,
  );

  RequirementDraft withStartDate(DateTime? d) => RequirementDraft(
    serviceId: serviceId,
    engagement: engagement,
    address: address,
    timing: timing,
    startDate: d == null ? null : dateOnly(d),
    budget: budget,
  );

  RequirementDraft withBudget(Budget? b) => RequirementDraft(
    serviceId: serviceId,
    engagement: engagement,
    address: address,
    timing: timing,
    startDate: startDate,
    budget: b,
  );

  Map<String, Object?> toJson() => {
    'serviceId': serviceId,
    'engagement': engagement?.name,
    'address': address == null
        ? null
        : {
            'id': address!.id,
            'line': address!.line,
            'line2': address!.line2,
            'label': address!.label,
            'area': address!.area,
            'city': address!.city,
            'pincode': address!.pincode,
            'isDefault': address!.isDefault,
          },
    'timing': timing?.toJson(),
    'startDate': startDate?.toIso8601String(),
    'budget': budget?.toJson(),
  };

  factory RequirementDraft.fromJson(Map<String, dynamic> j) {
    final a = j['address'] as Map<String, dynamic>?;
    final e = j['engagement'] as String?;
    final t = j['timing'] as Map<String, dynamic>?;
    final b = j['budget'] as Map<String, dynamic>?;
    final d = j['startDate'] as String?;
    return RequirementDraft(
      serviceId: j['serviceId'] as String?,
      engagement: e == null ? null : EngagementType.values.byName(e),
      address: a == null
          ? null
          : Address(
              id: a['id'] as String,
              line: a['line'] as String,
              line2: a['line2'] as String?,
              label: a['label'] as String?,
              area: a['area'] as String,
              city: a['city'] as String,
              pincode: a['pincode'] as String,
              isDefault: a['isDefault'] as bool? ?? false,
            ),
      timing: t == null ? null : Timing.fromJson(t),
      startDate: d == null ? null : dateOnly(DateTime.parse(d)),
      budget: b == null ? null : Budget.fromJson(b),
    );
  }
}
