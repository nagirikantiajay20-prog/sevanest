import 'package:flutter/material.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';

/// Seeded catalogue behind the mock-API toggle: the client's "Initial Service Categories" table.
/// Monthly (Driver, Cook) is an engagement type since the backend added MONTHLY.
class CatalogRepositoryMock implements CatalogRepository {
  CatalogRepositoryMock(this._state);
  final MockApiState Function() _state;

  static const categories_ = [
    ServiceCategory(
      id: 'maid',
      name: 'House Maid',
      description: 'Cleaning, utensils, basic household support',
      icon: Icons.cleaning_services_outlined,
      popular: true,
      engagements: [
        EngagementOption(EngagementType.partTime),
        EngagementOption(EngagementType.fullTime),
        EngagementOption(EngagementType.liveIn),
      ],
    ),
    ServiceCategory(
      id: 'driver',
      name: 'Driver',
      description: 'Personal or family driver, temporary driver',
      icon: Icons.directions_car_outlined,
      engagements: [
        EngagementOption(EngagementType.hourly),
        EngagementOption(EngagementType.daily),
        EngagementOption(EngagementType.monthly),
      ],
    ),
    ServiceCategory(
      id: 'cook',
      name: 'Cook',
      description: 'Breakfast, lunch and dinner preparation',
      icon: Icons.soup_kitchen_outlined,
      popular: true,
      engagements: [
        EngagementOption(EngagementType.partTime),
        EngagementOption(EngagementType.monthly),
      ],
    ),
    ServiceCategory(
      id: 'babysitter',
      name: 'Babysitter',
      description: 'Child supervision and basic care',
      icon: Icons.child_care_outlined,
      engagements: [
        EngagementOption(EngagementType.hourly),
        EngagementOption(EngagementType.fullTime),
      ],
    ),
    ServiceCategory(
      id: 'elderly',
      name: 'Elderly Care Helper',
      description: 'Non-clinical assistance and companionship',
      icon: Icons.volunteer_activism_outlined,
      engagements: [
        EngagementOption(EngagementType.shift),
        EngagementOption(EngagementType.fullTime),
      ],
    ),
    ServiceCategory(
      id: 'cleaner',
      name: 'Cleaning Helper',
      description: 'Deep or basic cleaning assistance',
      icon: Icons.auto_awesome_outlined,
      engagements: [
        EngagementOption(EngagementType.oneTime),
        EngagementOption(EngagementType.hourly),
      ],
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
