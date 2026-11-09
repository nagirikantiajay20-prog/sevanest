// Thin test of the real GeolocatorLocationService over a mocked geolocator platform channel and a
// stand-in geocoder: every outcome the UI reacts to (module 3 DISC-10).
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:sevanest_customer/core/services/location_service.dart';

const _channel = MethodChannel('flutter.baseflow.com/geolocator');

class _FakeGeocoding extends Geocoding {
  _FakeGeocoding(super.params) : super.implementation();
  static List<Placemark> marks = const [];
  static Object? error;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async {
    if (error != null) throw error!;
    return marks;
  }
}

class _FakeFactory extends GeocodingPlatformFactory {
  @override
  Geocoding createGeocoding(GeocodingCreationParams params) =>
      _FakeGeocoding(params);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var serviceEnabled = true;
  var permission = 2; // whileInUse
  var requestResult = 2;
  var requested = 0;
  Object? positionError;
  const position = {
    'latitude': 17.44,
    'longitude': 78.39,
    'timestamp': 1700000000000,
    'accuracy': 5.0,
    'altitude': 0.0,
    'heading': 0.0,
    'speed': 0.0,
    'speed_accuracy': 0.0,
  };

  setUp(() {
    serviceEnabled = true;
    permission = 2;
    requestResult = 2;
    requested = 0;
    positionError = null;
    _FakeGeocoding.error = null;
    _FakeGeocoding.marks = const [
      Placemark(
        subLocality: 'Madhapur',
        locality: 'Hyderabad',
        postalCode: '500081',
      ),
    ];
    GeocodingPlatformFactory.instance = _FakeFactory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return serviceEnabled;
            case 'checkPermission':
              return permission;
            case 'requestPermission':
              requested++;
              return requestResult;
            case 'getCurrentPosition':
              if (positionError != null) throw positionError!;
              return position;
            case 'openAppSettings':
              return true;
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  final service = GeolocatorLocationService();

  test(
    'permission granted: reverse-geocodes to area, city and pincode',
    () async {
      final r = await service.currentAddress();
      expect(r.outcome, LocationOutcome.found);
      expect(r.input?.area, 'Madhapur');
      expect(r.input?.city, 'Hyderabad');
      expect(r.input?.pincode, '500081');
      expect(r.input?.line, isEmpty);
    },
  );

  test('no sub-locality falls back to the locality', () async {
    _FakeGeocoding.marks = const [
      Placemark(locality: 'Secunderabad', postalCode: '500003'),
    ];
    final r = await service.currentAddress();
    expect(r.input?.area, 'Secunderabad');
  });

  test('location services off -> gpsOff', () async {
    serviceEnabled = false;
    expect((await service.currentAddress()).outcome, LocationOutcome.gpsOff);
  });

  test(
    'geocoder network failure -> network, other failure -> unavailable',
    () async {
      _FakeGeocoding.error = PlatformException(code: 'IO_ERROR');
      expect((await service.currentAddress()).outcome, LocationOutcome.network);
      _FakeGeocoding.error = const SocketException('offline');
      expect((await service.currentAddress()).outcome, LocationOutcome.network);
      _FakeGeocoding.error = StateError('boom');
      expect(
        (await service.currentAddress()).outcome,
        LocationOutcome.unavailable,
      );
    },
  );

  test('asks once when undecided; refusing -> denied', () async {
    permission = 0;
    requestResult = 0;
    expect((await service.currentAddress()).outcome, LocationOutcome.denied);
    expect(requested, 1);
  });

  test('asks once when undecided; accepting -> found', () async {
    permission = 0;
    requestResult = 2;
    expect((await service.currentAddress()).outcome, LocationOutcome.found);
  });

  test('denied forever -> deniedForever without prompting', () async {
    permission = 1;
    expect(
      (await service.currentAddress()).outcome,
      LocationOutcome.deniedForever,
    );
    expect(requested, 0);
  });

  test('GPS failure -> unavailable', () async {
    positionError = PlatformException(code: 'LOCATION_UPDATE_FAILURE');
    expect(
      (await service.currentAddress()).outcome,
      LocationOutcome.unavailable,
    );
  });

  test('geocoder returns nothing or throws -> unavailable', () async {
    _FakeGeocoding.marks = const [];
    expect(
      (await service.currentAddress()).outcome,
      LocationOutcome.unavailable,
    );
    _FakeGeocoding.error = Exception('no network');
    expect(
      (await service.currentAddress()).outcome,
      LocationOutcome.unavailable,
    );
  });
}
