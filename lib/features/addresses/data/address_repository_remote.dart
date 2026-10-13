import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';

class AddressRepositoryRemote implements AddressRepository {
  AddressRepositoryRemote(this._dio);
  final Dio _dio;

  static const _base = '/customers/me/addresses';

  String _path(String id, [String suffix = '']) =>
      '$_base/${Uri.encodeComponent(id)}$suffix';

  @override
  Future<List<Address>> list() async {
    final res = await guarded(() => _dio.get<dynamic>(_base));
    return listOf(res.data).map(parseAddress).whereType<Address>().toList();
  }

  @override
  Future<Address> create(AddressInput input) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        _base,
        data: {..._fields(input), 'isDefault': input.isDefault},
      ),
    );
    return _one(res.data);
  }

  @override
  Future<Address> update(String id, AddressInput input) async {
    final res = await guarded(
      () => _dio.patch<dynamic>(_path(id), data: _fields(input)),
    );
    return _one(res.data);
  }

  @override
  Future<void> delete(String id) async {
    await guarded(() => _dio.delete<dynamic>(_path(id)));
  }

  @override
  Future<void> setDefault(String id) async {
    await guarded(() => _dio.put<dynamic>(_path(id, '/default')));
  }

  @override
  Future<List<ServiceArea>> serviceAreas({String? city}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/service-areas',
        queryParameters: {'limit': 100, 'city': ?city},
      ),
    );
    return [
      for (final m in listOf(res.data))
        if (m['name'] is String)
          ServiceArea(
            id: '${m['id'] ?? m['name']}',
            name: m['name'] as String,
            city: m['city'] as String?,
          ),
    ];
  }

  Address _one(Object? body) =>
      parseAddress(body) ?? (throw const UnknownFailure());
}

Map<String, Object> _fields(AddressInput i) => {
  'line': i.line.trim(),
  'area': i.area.trim(),
  'city': i.city.trim(),
  'pincode': i.pincode.trim(),
  if (i.latitude != null && i.longitude != null) ...{
    'latitude': i.latitude!,
    'longitude': i.longitude!,
  },
};

/// Null when the payload has no id (fail closed rather than showing a half-built card).
Address? parseAddress(Object? body) {
  if (body is! Map) return null;
  final id = body['id'];
  if (id == null) return null;
  String s(String k) => body[k] is String ? body[k] as String : '';
  double? n(String k) => body[k] is num ? (body[k] as num).toDouble() : null;
  return Address(
    id: '$id',
    line: s('line'),
    area: s('area'),
    city: s('city'),
    pincode: s('pincode'),
    latitude: n('latitude'),
    longitude: n('longitude'),
    isDefault: body['isDefault'] == true,
  );
}
