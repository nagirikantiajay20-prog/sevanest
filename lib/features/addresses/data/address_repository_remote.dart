import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart'
    show uploadBaseOptions;
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';

class AddressRepositoryRemote implements AddressRepository {
  AddressRepositoryRemote(this._dio, {Dio? uploader})
    : _uploader = uploader ?? Dio(uploadBaseOptions());
  final Dio _dio;

  /// The upload link is pre-signed: it must not carry our bearer token or base URL.
  final Dio _uploader;

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
  Future<void> uploadPhoto(String id, PickedPhoto photo) async {
    final ask = await guarded(
      () => _dio.post<dynamic>(
        _path(id, '/photo'),
        data: {
          'contentType': photo.contentType,
          'sizeBytes': photo.bytes.length,
        },
      ),
    );
    final d = ask.data is Map<String, dynamic>
        ? ask.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final photoId = d['photoId'];
    final url = d['url'];
    if (photoId is! String || url is! String) throw const ServerFailure();
    await guarded(
      () => _uploader.put<dynamic>(
        url,
        data: Stream.value(photo.bytes),
        options: Options(
          method: (d['method'] as String?) ?? 'PUT',
          headers: {
            Headers.contentTypeHeader: photo.contentType,
            Headers.contentLengthHeader: photo.bytes.length,
          },
        ),
      ),
    );
    await guarded(
      () => _dio.post<dynamic>(
        _path(id, '/photo/${Uri.encodeComponent(photoId)}/confirm'),
      ),
    );
  }

  @override
  Future<void> removePhoto(String id) async {
    try {
      await guarded(() => _dio.delete<dynamic>(_path(id, '/photo')));
    } on NotFoundFailure {
      // already gone
    }
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

  @override
  Future<ServiceArea?> resolveServiceArea({
    double? latitude,
    double? longitude,
    String? name,
    String? city,
  }) async {
    try {
      final res = await guarded(
        () => _dio.get<dynamic>(
          '/locations/service-area',
          queryParameters: {
            'latitude': ?latitude,
            'longitude': ?longitude,
            if (name != null && name.isNotEmpty) 'name': name,
            if (city != null && city.isNotEmpty) 'city': city,
          },
        ),
      );
      final m = res.data;
      return m is Map && m['name'] is String
          ? ServiceArea(
              id: '${m['id'] ?? m['name']}',
              name: m['name'] as String,
              city: m['city'] as String?,
            )
          : null;
    } on NotFoundFailure {
      return null;
    }
  }

  Address _one(Object? body) =>
      parseAddress(body) ?? (throw const UnknownFailure());
}

String? _nullIfBlank(String? s) =>
    s == null || s.trim().isEmpty ? null : s.trim();

Map<String, Object?> _fields(AddressInput i) => {
  'line': i.line.trim(),
  'area': i.area.trim(),
  'city': i.city.trim(),
  'pincode': i.pincode.trim(),
  // Null clears the value on an edit.
  'label': _nullIfBlank(i.label),
  'line2': _nullIfBlank(i.line2),
  'state': _nullIfBlank(i.state),
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
  // A field of an unexpected type reads as absent; a cast would throw out of the whole list.
  String? o(String k) =>
      _nullIfBlank(body[k] is String ? body[k] as String : null);
  return Address(
    id: '$id',
    line: s('line'),
    area: s('area'),
    city: s('city'),
    pincode: s('pincode'),
    label: o('label'),
    line2: o('line2'),
    state: o('state'),
    latitude: n('latitude'),
    longitude: n('longitude'),
    isDefault: body['isDefault'] == true,
    photoUrl: o('photoUrl'),
    isServiceable: body['isServiceable'] is bool
        ? body['isServiceable'] as bool
        : null,
    unserviceableReason: o('unserviceableReason'),
  );
}
