import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';

enum LocationOutcome { found, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult(this.outcome, [this.input]);
  final LocationOutcome outcome;

  /// Area / city / pincode from reverse geocoding (house and street stay for the user to fill).
  final AddressInput? input;
}

/// Device GPS + reverse geocoding behind an interface so widget tests need no platform plugin.
abstract interface class LocationService {
  Future<LocationResult> currentAddress();
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> currentAddress() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationOutcome.denied);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(LocationOutcome.deniedForever);
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult(LocationOutcome.denied);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      final marks = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (marks.isEmpty) {
        return const LocationResult(LocationOutcome.unavailable);
      }
      final m = marks.first;
      final area = (m.subLocality?.isNotEmpty ?? false)
          ? m.subLocality!
          : (m.locality ?? '');
      return LocationResult(
        LocationOutcome.found,
        AddressInput(
          line: '',
          area: area,
          city: m.locality ?? '',
          pincode: m.postalCode ?? '',
        ),
      );
    } on Object {
      return const LocationResult(LocationOutcome.unavailable);
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);
