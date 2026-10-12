import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

enum BudgetPeriod { monthly, hourly }

BudgetPeriod budgetPeriodFor(EngagementType e) =>
    e == EngagementType.hourly ? BudgetPeriod.hourly : BudgetPeriod.monthly;

/// Slider / "Any budget" ceiling in rupees ("₹40k+" monthly, "₹1k+" hourly).
int budgetCeiling(BudgetPeriod p) => p == BudgetPeriod.hourly ? 1000 : 40000;

/// Hard cap on a typed amount (sanity, not market guidance).
int budgetCap(BudgetPeriod p) => p == BudgetPeriod.hourly ? 5000 : 500000;

/// Range shown before guidance arrives (design 11 defaults).
({int min, int max}) fallbackBudgetRange(BudgetPeriod p) =>
    p == BudgetPeriod.hourly ? (min: 100, max: 200) : (min: 6000, max: 10000);

/// The customer's budget. [flexible] ignores the amounts ("Any budget").
class Budget {
  const Budget({
    this.min,
    this.max,
    this.flexible = false,
    required this.period,
  });

  final int? min;
  final int? max;
  final bool flexible;
  final BudgetPeriod period;

  Budget copyWith({
    int? min,
    int? max,
    bool? flexible,
    bool clearMin = false,
    bool clearMax = false,
  }) => Budget(
    min: clearMin ? null : min ?? this.min,
    max: clearMax ? null : max ?? this.max,
    flexible: flexible ?? this.flexible,
    period: period,
  );

  Map<String, Object?> toJson() => {
    'min': min,
    'max': max,
    'flexible': flexible,
    'period': period.name,
  };

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
    min: j['min'] as int?,
    max: j['max'] as int?,
    flexible: j['flexible'] as bool? ?? false,
    period: BudgetPeriod.values.byName(j['period'] as String),
  );
}

/// Market range for service + location + engagement (`GET /catalog/price-guidance`, assumed).
class Guidance {
  const Guidance({
    required this.min,
    required this.max,
    required this.period,
    required this.city,
    required this.basis,
  });

  final int min;
  final int max;
  final BudgetPeriod period;
  final String city;

  /// e.g. "Based on recent bookings".
  final String basis;
}

class GuidanceQuery {
  const GuidanceQuery({
    required this.serviceId,
    required this.engagement,
    required this.area,
    required this.city,
  });

  final String serviceId;
  final EngagementType engagement;
  final String area;
  final String city;

  // Records give value equality, so this works as a provider family key.
  @override
  bool operator ==(Object other) =>
      other is GuidanceQuery &&
      other.serviceId == serviceId &&
      other.engagement == engagement &&
      other.area == area &&
      other.city == city;

  @override
  int get hashCode => Object.hash(serviceId, engagement, area, city);
}

abstract interface class GuidanceRepository {
  Future<Guidance> guidance(GuidanceQuery query);
}

enum BudgetStatus { ok, lowWarning, invalid }

enum BudgetIssue { missing, minAboveMax, tooHigh }

/// The one verdict the Budget screen and whole-draft validation share.
/// Flexible is always ok; a range entirely below the guidance only warns (it never blocks).
BudgetStatus budgetStatus(Budget? b, Guidance? guidance) =>
    budgetIssue(b) != null
    ? BudgetStatus.invalid
    : (b!.flexible || guidance == null || b.max! >= guidance.min)
    ? BudgetStatus.ok
    : BudgetStatus.lowWarning;

BudgetIssue? budgetIssue(Budget? b) {
  if (b == null) return BudgetIssue.missing;
  if (b.flexible) return null;
  final min = b.min;
  final max = b.max;
  if (min == null || max == null || max <= 0) return BudgetIssue.missing;
  if (min > max) return BudgetIssue.minAboveMax;
  if (max > budgetCap(b.period)) return BudgetIssue.tooHigh;
  return null;
}

/// ₹ with Indian digit grouping: 600000 -> "₹6,00,000".
String formatRupees(int amount) => '₹${groupIndian(amount)}';

String groupIndian(int amount) {
  final s = amount.abs().toString();
  final String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final parts = <String>[];
    for (var i = head.length; i > 0; i -= 2) {
      parts.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
    }
    grouped = '${parts.join(',')},$tail';
  }
  return amount < 0 ? '-$grouped' : grouped;
}
