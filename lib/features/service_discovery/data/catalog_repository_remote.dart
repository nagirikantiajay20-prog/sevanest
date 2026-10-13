import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// `GET /service-categories` (enabled categories). The backend gives only code / name /
/// description, so every engagement the app supports is offered and the budget step is always
/// shown; the category `code` is the id the search sends back.
class CatalogRepositoryRemote implements CatalogRepository {
  CatalogRepositoryRemote(this._dio);
  final Dio _dio;

  static const _engagements = [
    EngagementOption(EngagementType.fullTime),
    EngagementOption(EngagementType.partTime),
    EngagementOption(EngagementType.daily),
    EngagementOption(EngagementType.hourly),
    EngagementOption(EngagementType.liveIn),
  ];

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
            engagements: _engagements,
          ),
    ];
  }
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
