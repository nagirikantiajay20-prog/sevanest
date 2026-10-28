import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';

/// Mirrors the worker photo contract (`/workers/me/photo`): request a short-lived `PUT` link,
/// upload the bytes to it, confirm. The customer routes are not in the checked-in OpenAPI yet, so
/// the request and response shapes are the worker ones (docs/BACKEND_REQUESTS.md).
class CustomerPhotoRepositoryRemote implements CustomerPhotoRepository {
  CustomerPhotoRepositoryRemote(this._dio, {Dio? uploader})
    : _uploader = uploader ?? Dio();

  final Dio _dio;

  /// The upload link is pre-signed: it must not carry our bearer token or base URL.
  final Dio _uploader;

  @override
  Future<ProfilePhoto?> current() async {
    try {
      final res = await guarded(() => _dio.get<dynamic>('/customers/me/photo'));
      final url = res.data is Map ? (res.data as Map)['url'] : null;
      return url is String && url.isNotEmpty ? ProfilePhoto(url: url) : null;
    } on NotFoundFailure {
      return null;
    }
  }

  @override
  Future<void> upload(PickedPhoto photo) async {
    final ask = await guarded(
      () => _dio.post<dynamic>(
        '/customers/me/photo',
        data: {
          'contentType': photo.contentType,
          'sizeBytes': photo.bytes.length,
        },
      ),
    );
    final d = ask.data is Map<String, dynamic>
        ? ask.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final id = d['photoId'];
    final url = d['url'];
    if (id is! String || url is! String) throw const ServerFailure();
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
        '/customers/me/photo/${Uri.encodeComponent(id)}/confirm',
      ),
    );
  }
}
