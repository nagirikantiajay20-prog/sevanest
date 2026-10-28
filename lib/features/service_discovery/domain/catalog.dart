import 'package:flutter/material.dart';

/// Backend vocabulary (`/reference-data` engagements): FULL_TIME PART_TIME LIVE_IN DAILY HOURLY
/// SHIFT ONE_TIME MONTHLY (MONTHLY added by the backend 2026-11-13).
enum EngagementType {
  fullTime('FULL_TIME'),
  partTime('PART_TIME'),
  daily('DAILY'),
  hourly('HOURLY'),
  liveIn('LIVE_IN'),
  shift('SHIFT'),
  oneTime('ONE_TIME'),
  monthly('MONTHLY');

  const EngagementType(this.code);
  final String code;

  static EngagementType? fromCode(Object? c) =>
      values.where((e) => e.code == c).firstOrNull;
}

/// One engagement option of a service. [unavailableReason] non-null = shown disabled with that reason.
class EngagementOption {
  const EngagementOption(this.type, {this.unavailableReason});
  final EngagementType type;
  final String? unavailableReason;
  bool get available => unavailableReason == null;
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.engagements,
    this.popular = false,
    this.requiresBudget = true,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool popular;
  final bool requiresBudget;
  final List<EngagementOption> engagements;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}

/// `GET /catalog/categories` (docs/05). Server-driven: the UI never hard-codes which engagement
/// types a service supports.
abstract interface class CatalogRepository {
  Future<List<ServiceCategory>> categories();
}
