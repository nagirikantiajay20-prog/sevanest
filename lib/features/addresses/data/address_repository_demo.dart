import 'dart:convert';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/data/auth_repository_demo.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hyderabad areas of the launch market, standing in for `GET /service-areas` (which needs a real
/// session).
const _areas = [
  'Banjara Hills',
  'Begumpet',
  'Gachibowli',
  'Hitech City',
  'Jubilee Hills',
  'Kondapur',
  'Kukatpally',
  'Madhapur',
  'Miyapur',
  'Secunderabad',
];

/// Dev flavor only: addresses of the demo login live on the device, one list per mobile number.
class AddressRepositoryDemo implements AddressRepository {
  Future<(SharedPreferences, String)> _slot() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(demoMobileKey);
    if (mobile == null) throw const UnauthorizedFailure();
    return (prefs, mobile);
  }

  List<Address> _read(SharedPreferences p, String mobile) {
    final raw = p.getString(demoAddressesKey(mobile));
    if (raw == null) return [];
    return [
      for (final m in jsonDecode(raw) as List<dynamic>)
        _fromJson(m as Map<String, dynamic>),
    ];
  }

  Future<void> _write(SharedPreferences p, String mobile, List<Address> all) =>
      p.setString(
        demoAddressesKey(mobile),
        jsonEncode([for (final a in all) _toJson(a)]),
      );

  // Demo login has no storage service: home photos are not kept.
  @override
  Future<void> uploadPhoto(String id, PickedPhoto photo) async {}

  @override
  Future<void> removePhoto(String id) async {}

  @override
  Future<List<Address>> list() async {
    final (p, mobile) = await _slot();
    final all = _read(p, mobile);
    return [
      ...all.where((a) => a.isDefault),
      ...all.where((a) => !a.isDefault),
    ];
  }

  @override
  Future<Address> create(AddressInput input) async {
    final (p, mobile) = await _slot();
    final all = _read(p, mobile);
    final makeDefault = input.isDefault || all.isEmpty;
    final saved = _from(
      'demo-${DateTime.now().microsecondsSinceEpoch}',
      input,
      makeDefault,
    );
    await _write(p, mobile, [
      for (final a in all) makeDefault ? _from(a.id, _input(a), false) : a,
      saved,
    ]);
    return saved;
  }

  @override
  Future<Address> update(String id, AddressInput input) async {
    final (p, mobile) = await _slot();
    final all = _read(p, mobile);
    final old = all.where((a) => a.id == id).firstOrNull;
    if (old == null) throw const NotFoundFailure();
    final saved = _from(id, input, old.isDefault);
    await _write(p, mobile, [for (final a in all) a.id == id ? saved : a]);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    final (p, mobile) = await _slot();
    final all = _read(p, mobile)..removeWhere((a) => a.id == id);
    final needsDefault = all.isNotEmpty && !all.any((a) => a.isDefault);
    await _write(p, mobile, [
      for (final (i, a) in all.indexed)
        i == 0 && needsDefault ? _from(a.id, _input(a), true) : a,
    ]);
  }

  @override
  Future<void> setDefault(String id) async {
    final (p, mobile) = await _slot();
    final all = _read(p, mobile);
    await _write(p, mobile, [
      for (final a in all) _from(a.id, _input(a), a.id == id),
    ]);
  }

  @override
  Future<List<ServiceArea>> serviceAreas({String? city}) async => [
    for (final n in _areas) ServiceArea(id: n, name: n, city: 'Hyderabad'),
  ];

  @override
  Future<ServiceArea?> resolveServiceArea({
    double? latitude,
    double? longitude,
    String? name,
    String? city,
  }) async {
    final n = (name ?? '').trim().toLowerCase();
    for (final a in _areas) {
      if (a.toLowerCase() == n) {
        return ServiceArea(id: a, name: a, city: 'Hyderabad');
      }
    }
    return null;
  }
}

Address _from(String id, AddressInput i, bool isDefault) => Address(
  id: id,
  line: i.line,
  line2: i.line2,
  label: i.label,
  state: i.state,
  area: i.area,
  city: i.city,
  pincode: i.pincode,
  latitude: i.latitude,
  longitude: i.longitude,
  isDefault: isDefault,
);

AddressInput _input(Address a) => AddressInput(
  line: a.line,
  line2: a.line2,
  label: a.label,
  state: a.state,
  area: a.area,
  city: a.city,
  pincode: a.pincode,
  latitude: a.latitude,
  longitude: a.longitude,
);

Map<String, dynamic> _toJson(Address a) => {
  'id': a.id,
  'line': a.line,
  'line2': a.line2,
  'label': a.label,
  'state': a.state,
  'area': a.area,
  'city': a.city,
  'pincode': a.pincode,
  'lat': a.latitude,
  'lng': a.longitude,
  'isDefault': a.isDefault,
};

Address _fromJson(Map<String, dynamic> m) => Address(
  id: m['id'] as String,
  line: m['line'] as String? ?? '',
  line2: m['line2'] as String?,
  label: m['label'] as String?,
  state: m['state'] as String?,
  area: m['area'] as String? ?? '',
  city: m['city'] as String? ?? '',
  pincode: m['pincode'] as String? ?? '',
  latitude: (m['lat'] as num?)?.toDouble(),
  longitude: (m['lng'] as num?)?.toDouble(),
  isDefault: m['isDefault'] as bool? ?? false,
);
