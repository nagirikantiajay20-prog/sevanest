import 'package:dio/dio.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';

/// `/payments` of the deployed backend (Swagger 2026-10-13).
class PaymentRepositoryRemote implements PaymentRepository {
  PaymentRepositoryRemote(this._dio);
  final Dio _dio;

  static const pageSize = 20;

  Payment _parse(Object? body) =>
      Payment.fromJson(body) ?? (throw const UnknownFailure());

  Options _key(String k) => Options(headers: {'Idempotency-Key': k});

  @override
  Future<Payment> start(
    String bookingId, {
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/payments',
        options: _key(idempotencyKey),
        data: {'bookingId': bookingId},
      ),
    );
    return _parse(res.data);
  }

  @override
  Future<Payment> verify(
    String id, {
    required String providerPaymentId,
    required String signature,
    required String idempotencyKey,
  }) async {
    final res = await guarded(
      () => _dio.post<dynamic>(
        '/payments/${Uri.encodeComponent(id)}/verify',
        options: _key(idempotencyKey),
        data: {'providerPaymentId': providerPaymentId, 'signature': signature},
      ),
    );
    return _parse(res.data);
  }

  @override
  Future<Payment> get(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/payments/${Uri.encodeComponent(id)}',
        cancelToken: cancel,
      ),
    );
    return _parse(res.data);
  }

  @override
  Future<Receipt> receipt(String id, {CancelToken? cancel}) async {
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/payments/${Uri.encodeComponent(id)}/receipt',
        cancelToken: cancel,
      ),
    );
    return Receipt.fromJson(res.data) ?? (throw const UnknownFailure());
  }

  @override
  Future<PaymentPage> list({
    String? cursor,
    PaymentStatus? status,
    String? bookingId,
    bool refunded = false,
  }) async {
    final page = int.tryParse(cursor ?? '') ?? 1;
    final res = await guarded(
      () => _dio.get<dynamic>(
        '/payments',
        queryParameters: {
          'page': page,
          'limit': pageSize,
          if (status != null && !refunded) 'status': paymentStatusCode(status),
          'bookingId': ?bookingId,
          if (refunded) 'refunded': true,
        },
      ),
    );
    final body = res.data;
    final meta = body is Map ? body['meta'] : null;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : 0;
    return PaymentPage([
      for (final m in listOf(body)) ?Payment.fromJson(m),
    ], page * pageSize < total ? '${page + 1}' : null);
  }
}
