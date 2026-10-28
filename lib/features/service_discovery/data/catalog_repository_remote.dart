import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// `GET /service-categories` (enabled categories). The backend gives only code / name /
/// description plus `allowedEngagements`; the budget step is always shown; the category `code` is the id the search sends back.
class CatalogRepositoryRemote implements CatalogRepository {
  CatalogRepositoryRemote(this._dio);
  final Dio _dio;

  /// `allowedEngagements` wins when the backend sends it. Empty = not restricted, so we fall back
  /// to the client's "Initial Service Categories" table, and only for an unknown service offer all.
  static List<EngagementOption> _options(
    Object? allowed,
    String code,
    String name,
  ) {
    final types = [
      for (final c in allowed is List ? allowed : const [])
        ?EngagementType.fromCode(c),
    ];
    return [
      for (final t
          in types.isNotEmpty
              ? types
              : defaultEngagements(code, name) ?? EngagementType.values)
        EngagementOption(t),
    ];
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/service-categories',
        queryParameters: {'page': 1, 'limit': 100},
      ),
    );
    return [
      for (final m in listOf(res.data))
        if ((m['code'] ?? m['id']) is String && m['name'] is String)
          ServiceCategory(
            id: (m['code'] ?? m['id']) as String,
            name: m['name'] as String,
            description: m['description'] as String? ?? '',
            icon: _iconFor('${m['code'] ?? m['id']}'),
            engagements: _options(
              m['allowedEngagements'] ?? m['engagements'],
              '${m['code'] ?? m['id']}',
              m['name'] as String,
            ),
          ),
    ];
  }
}

/// Client table (Initial Service Categories, section 4). Monthly is its own engagement since the backend added MONTHLY. Null = unknown service. Matches on code or name, e.g. HOUSE_MAID.
List<EngagementType>? defaultEngagements(String code, String name) {
  final c = '$code $name'.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
  if (c.contains('BABY') || c.contains('NANNY') || c.contains('CHILD')) {
    return [EngagementType.hourly, EngagementType.fullTime];
  }
  if (c.contains('ELDER')) {
    return [EngagementType.shift, EngagementType.fullTime];
  }
  if (c.contains('MAID')) {
    return [
      EngagementType.partTime,
      EngagementType.fullTime,
      EngagementType.liveIn,
    ];
  }
  if (c.contains('CLEAN')) {
    return [EngagementType.oneTime, EngagementType.hourly];
  }
  if (c.contains('DRIVER')) {
    return [
      EngagementType.hourly,
      EngagementType.daily,
      EngagementType.monthly,
    ];
  }
  if (c.contains('COOK')) {
    return [EngagementType.partTime, EngagementType.monthly];
  }
  return null;
}

IconData _iconFor(String code) {
  final c = code.toUpperCase();
  if (c.contains('COOK')) return Icons.soup_kitchen_outlined;
  if (c.contains('DRIVER')) return Icons.directions_car_outlined;
  if (c.contains('NANNY') || c.contains('BABY') || c.contains('CHILD')) {
    return Icons.child_care_outlined;
  }
  if (c.contains('MAID') || c.contains('CLEAN')) {
    return Icons.cleaning_services_outlined;
  }
  if (c.contains('ELDER') || c.contains('CARE') || c.contains('NURSE')) {
    return Icons.volunteer_activism_outlined;
  }
  return Icons.handyman_outlined;
}
