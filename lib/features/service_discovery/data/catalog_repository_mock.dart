import 'package:flutter/material.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

const _all = [
  EngagementOption(EngagementType.fullTime),
  EngagementOption(EngagementType.partTime),
  EngagementOption(EngagementType.daily),
  EngagementOption(EngagementType.hourly),
  EngagementOption(EngagementType.liveIn),
];

/// Seeded catalogue behind the mock-API toggle. Driver cannot be live-in (design 07).
class CatalogRepositoryMock implements CatalogRepository {
  CatalogRepositoryMock(this._state);
  final MockApiState Function() _state;

  static const categories_ = [
    ServiceCategory(
      id: 'maid',
      name: 'Maid',
      description: 'Cleaning and chores',
      icon: Icons.cleaning_services_outlined,
      popular: true,
      engagements: _all,
    ),
    ServiceCategory(
      id: 'cook',
      name: 'Cook',
      description: 'Meals and everyday cooking',
      icon: Icons.soup_kitchen_outlined,
      popular: true,
      engagements: _all,
    ),
    ServiceCategory(
      id: 'driver',
      name: 'Driver',
      description: 'Car, school runs, errands',
      icon: Icons.directions_car_outlined,
      engagements: [
        EngagementOption(EngagementType.fullTime),
        EngagementOption(EngagementType.partTime),
        EngagementOption(EngagementType.daily),
        EngagementOption(EngagementType.hourly),
        EngagementOption(
          EngagementType.liveIn,
          unavailableReason: 'Not available for drivers',
        ),
      ],
    ),
    ServiceCategory(
      id: 'nanny',
      name: 'Nanny',
      description: 'Childcare at home',
      icon: Icons.child_care_outlined,
      engagements: _all,
    ),
  ];

  @override
  Future<List<ServiceCategory>> categories() => mockCall(
    _state(),
    () => _state().mode == MockMode.empty
        ? const <ServiceCategory>[]
        : categories_,
  );
}
