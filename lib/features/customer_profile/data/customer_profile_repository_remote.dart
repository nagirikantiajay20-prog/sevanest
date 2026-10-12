import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_profile.dart';

class CustomerProfileRepositoryRemote implements CustomerProfileRepository {
  CustomerProfileRepositoryRemote(this._dio);
  final Dio _dio;

  @override
  Future<CustomerProfile> get() async => parseProfile(
    (await guarded(() => _dio.get<dynamic>('/customers/me'))).data,
  );

  @override
  Future<CustomerProfile> create({
    required String name,
    required String email,
    required String preferredLanguage,
  }) => _write('POST', name, email, preferredLanguage);

  @override
  Future<CustomerProfile> update({
    required String name,
    required String email,
    required String preferredLanguage,
  }) => _write('PATCH', name, email, preferredLanguage);

  Future<CustomerProfile> _write(
    String method,
    String name,
    String email,
    String language,
  ) async {
    final body = {
      'name': name.trim(),
      'email': email.trim(),
      'preferredLanguage': language,
    };
    final res = await guarded(
      () => _dio.request<dynamic>(
        '/customers/me',
        data: body,
        options: Options(method: method),
      ),
    );
    // Success schema is unpublished: fall back to what we sent for any missing field.
    return parseProfile(res.data, fallback: body);
  }
}

/// Defensive: a missing or non-string field never throws.
CustomerProfile parseProfile(
  Object? body, {
  Map<String, String> fallback = const {},
}) {
  final d = body is Map ? body : const <String, dynamic>{};
  String? s(String k) => d[k] is String && (d[k] as String).isNotEmpty
      ? d[k] as String
      : fallback[k];
  return CustomerProfile(
    name: s('name') ?? '',
    email: s('email') ?? '',
    preferredLanguage: s('preferredLanguage') ?? 'en',
    mobile: s('mobile'),
    verificationStatus: s('verificationStatus'),
  );
}
