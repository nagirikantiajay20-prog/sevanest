// Module 09: the payment repositories against the shapes of the 2026-10-13 OpenAPI.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_mock.dart';
import 'package:sevanest_customer/features/payment/data/payment_repository_remote.dart';
import 'package:sevanest_customer/features/payment/data/payment_services.dart';
import 'package:sevanest_customer/features/payment/domain/payment.dart';

import '../../helpers/fakes.dart';

const _view =
    '{"id":"p1","bookingId":"b1","status":"SUCCEEDED","amountMinor":49950,"currency":"INR",'
    '"receiptNumber":"R-1","paidAt":"2026-10-13T10:00:00Z","refundStatus":null,"refundedAt":null,'
    '"createdAt":"2026-10-13T09:00:00Z"}';

void main() {
  late List<RequestOptions> seen;

  Dio dio(Future<ResponseBody> Function(RequestOptions) h) {
    seen = [];
    return Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return h(o);
      });
  }

  group('remote', () {
    test('start posts the booking id with an Idempotency-Key', () async {
      final repo = PaymentRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"id":"p1","bookingId":"b1","status":"PENDING","amountMinor":49900,"currency":"INR",'
            '"receiptNumber":null,"paidAt":null,"refundStatus":null,"refundedAt":null,'
            '"createdAt":"2026-10-13T09:00:00Z","checkout":{"gateway":"razorpay","keyId":"rzp_test_x",'
            '"orderId":"order_1","amount":49900,"currency":"INR"}}',
            201,
          ),
        ),
      );
      final p = await repo.start('b1', idempotencyKey: 'key-12345678');
      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/payments');
      expect(seen.single.data, {'bookingId': 'b1'});
      expect(seen.single.headers['Idempotency-Key'], 'key-12345678');
      expect(p.id, 'p1');
      expect(p.status, PaymentStatus.pending);
      expect(p.amountMinor, 49900);
      final c = p.checkout!;
      expect(c.gateway, 'razorpay');
      expect(c.keyId, 'rzp_test_x');
      expect(c.orderId, 'order_1');
      expect(c.amount, 49900);
      expect(c.currency, 'INR');
      expect(c.isRazorpay, isTrue);
      expect(p.canPay, isTrue);
      expect(p.isSettled, isFalse);
    });

    test(
      'fake gateway has no key; CREATED has no checkout and is not payable',
      () {
        final fake = Payment.fromJson({
          'id': 'p1',
          'bookingId': 'b1',
          'status': 'PENDING',
          'amountMinor': 100,
          'checkout': {
            'gateway': 'fake',
            'keyId': null,
            'orderId': 'order_f',
            'amount': 100,
            'currency': 'INR',
          },
        })!;
        expect(
          fake.checkout!.isRazorpay,
          isFalse,
        ); // nothing for the SDK to open
        expect(fake.canPay, isTrue);
        final created = Payment.fromJson({
          'id': 'p1',
          'bookingId': 'b1',
          'status': 'CREATED',
          'amountMinor': 100,
          'checkout': null,
        })!;
        expect(created.checkout, isNull);
        expect(created.canPay, isFalse);
      },
    );

    test('method, masked detail, reference and failure reason are read', () {
      final paid = Payment.fromJson({
        'id': 'p1',
        'bookingId': 'b1',
        'status': 'SUCCEEDED',
        'amountMinor': 100,
        'paymentMethod': 'upi',
        'paymentMethodDetail': 'ab***@okhdfc',
        'gatewayReference': 'pay_abc',
        'failureCode': null,
        'failureReason': null,
      })!;
      expect(paid.paymentMethod, PaymentMethod.upi);
      expect(paid.paymentMethodDetail, 'ab***@okhdfc');
      expect(paid.gatewayReference, 'pay_abc');
      expect(paid.failureReason, isNull);
      final failed = Payment.fromJson({
        'id': 'p2',
        'bookingId': 'b1',
        'status': 'FAILED',
        'amountMinor': 100,
        'paymentMethod': 'somethingnew',
        'failureCode': 'BAD_REQUEST_ERROR',
        'failureReason': 'Your bank declined the payment',
      })!;
      expect(
        failed.paymentMethod,
        isNull,
      ); // unknown method codes stay out of the UI
      expect(failed.failureCode, 'BAD_REQUEST_ERROR');
      expect(failed.failureReason, 'Your bank declined the payment');
    });

    test('refund status and date are read from the payment', () {
      final p = Payment.fromJson({
        'id': 'p1',
        'bookingId': 'b1',
        'status': 'REFUNDED',
        'amountMinor': 100,
        'refundStatus': 'REFUNDED',
        'refundedAt': '2026-10-14T10:00:00Z',
      })!;
      expect(p.refundStatus, 'REFUNDED');
      expect(p.refundedAt, DateTime.utc(2026, 10, 14, 10));
      final none = Payment.fromJson({
        'id': 'p1',
        'bookingId': 'b1',
        'status': 'SUCCEEDED',
        'amountMinor': 100,
        'refundStatus': null,
        'refundedAt': null,
      })!;
      expect(none.refundStatus, isNull);
      expect(none.refundedAt, isNull);
    });

    test('receipt reads GET /payments/{id}/receipt', () async {
      final repo = PaymentRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"receiptNumber":"SN-1","paymentId":"p 1","bookingId":"b1","feeCode":"BOOKING_FEE",'
            '"amountMinor":49900,"currency":"INR","paidAt":"2026-10-13T10:00:00Z",'
            '"paymentMethod":"card","paymentMethodDetail":"Visa **** 4242",'
            '"gatewayReference":"pay_9","status":"REFUNDED","refundStatus":"REFUNDED",'
            '"refundedAt":"2026-10-14T10:00:00Z"}',
            200,
          ),
        ),
      );
      final r = await repo.receipt('p 1');
      expect(seen.single.method, 'GET');
      expect(seen.single.path, '/payments/p%201/receipt');
      expect(r.receiptNumber, 'SN-1');
      expect(r.amountMinor, 49900);
      expect(r.paymentMethod, PaymentMethod.card);
      expect(r.paymentMethodDetail, 'Visa **** 4242');
      expect(r.gatewayReference, 'pay_9');
      expect(r.status, PaymentStatus.refunded);
      expect(r.refundedAt, DateTime.utc(2026, 10, 14, 10));
    });

    test(
      'receipt before payment is 409 RECEIPT_NOT_AVAILABLE; others 404',
      () async {
        Future<Object> thrown(int status, String body) async {
          final repo = PaymentRepositoryRemote(
            dio((o) async => jsonBody(body, status)),
          );
          try {
            await repo.receipt('p1');
          } on Object catch (e) {
            return e;
          }
          fail('should have thrown');
        }

        final early = await thrown(
          409,
          '{"code":"RECEIPT_NOT_AVAILABLE","message":"x"}',
        );
        expect((early as ConflictFailure).code, 'RECEIPT_NOT_AVAILABLE');
        expect(
          await thrown(404, '{"code":"NOT_FOUND"}'),
          isA<NotFoundFailure>(),
        );
      },
    );

    test(
      'verify posts providerPaymentId and signature to the payment',
      () async {
        final repo = PaymentRepositoryRemote(
          dio((o) async => jsonBody(_view, 200)),
        );
        final p = await repo.verify(
          'p 1',
          providerPaymentId: 'pay_9',
          signature: 'sig',
          idempotencyKey: 'key-87654321',
        );
        expect(seen.single.path, '/payments/p%201/verify');
        expect(seen.single.data, {
          'providerPaymentId': 'pay_9',
          'signature': 'sig',
        });
        expect(seen.single.headers['Idempotency-Key'], 'key-87654321');
        expect(p.status, PaymentStatus.succeeded);
        expect(p.receiptNumber, 'R-1');
        expect(p.paidAt, DateTime.utc(2026, 10, 13, 10));
        expect(p.wasPaid && p.isSettled, isTrue);
      },
    );

    test(
      'get reads one payment; refund statuses count as paid and settled',
      () async {
        final repo = PaymentRepositoryRemote(
          dio(
            (o) async => jsonBody(
              _view.replaceFirst('SUCCEEDED', 'REFUND_PENDING'),
              200,
            ),
          ),
        );
        final p = await repo.get('p1');
        expect(seen.single.path, '/payments/p1');
        expect(p.status, PaymentStatus.refundPending);
        expect(p.wasRefunded && p.wasPaid && p.isSettled, isTrue);
      },
    );

    test('list filters by booking and by refunded', () async {
      final repo = PaymentRepositoryRemote(
        dio((o) async => jsonBody('{"data":[],"meta":{"total":0}}', 200)),
      );
      await repo.list(bookingId: 'b1');
      expect(seen.single.queryParameters, {
        'page': 1,
        'limit': 20,
        'bookingId': 'b1',
      });
      await repo.list(refunded: true);
      expect(seen.last.queryParameters, {
        'page': 1,
        'limit': 20,
        'refunded': true,
      });
    });

    test('list pages by number, filters by status, skips bad rows', () async {
      final repo = PaymentRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[$_view,{"nope":1}],"meta":{"page":1,"limit":20,"total":45}}',
            200,
          ),
        ),
      );
      final page = await repo.list(status: PaymentStatus.refunded);
      expect(seen.single.path, '/payments');
      expect(seen.single.queryParameters, {
        'page': 1,
        'limit': 20,
        'status': 'REFUNDED',
      });
      expect(page.items.length, 1);
      expect(page.nextCursor, '2');
      final last = await repo.list(cursor: '3');
      expect(last.nextCursor, isNull);
    });

    test('an unknown status reads as unknown, never as paid', () async {
      final repo = PaymentRepositoryRemote(
        dio(
          (o) async => jsonBody(_view.replaceFirst('SUCCEEDED', 'WEIRD'), 200),
        ),
      );
      final p = await repo.get('p1');
      expect(p.status, PaymentStatus.unknown);
      expect(p.wasPaid, isFalse);
      expect(p.isSettled, isFalse);
    });

    Future<Object> failure(int status, String body) async {
      final repo = PaymentRepositoryRemote(
        dio((o) async => jsonBody(body, status)),
      );
      try {
        await repo.start('b1', idempotencyKey: 'key-12345678');
      } on Object catch (e) {
        return e;
      }
      fail('should have thrown');
    }

    test('error codes of the contract keep their code', () async {
      final notPayable = await failure(
        409,
        '{"code":"BOOKING_NOT_PAYABLE","message":"x"}',
      );
      expect((notPayable as ConflictFailure).code, 'BOOKING_NOT_PAYABLE');
      final inProgress = await failure(
        409,
        '{"code":"IDEMPOTENCY_IN_PROGRESS","message":"x"}',
      );
      expect((inProgress as ConflictFailure).code, 'IDEMPOTENCY_IN_PROGRESS');
      final fee = await failure(
        422,
        '{"code":"FEE_NOT_CONFIGURED","message":"x"}',
      );
      expect((fee as ValidationFailure).code, 'FEE_NOT_CONFIGURED');
      expect(
        await failure(503, '{"code":"PAYMENT_PROVIDER_UNAVAILABLE"}'),
        isA<ServerFailure>(),
      );
      expect(
        await failure(404, '{"code":"NOT_FOUND"}'),
        isA<NotFoundFailure>(),
      );
      expect(
        await failure(401, '{"code":"UNAUTHORIZED"}'),
        isA<UnauthorizedFailure>(),
      );
      expect(
        await failure(429, '{"code":"RATE_LIMITED"}'),
        isA<RateLimitedFailure>(),
      );
    });

    test(
      'verify with a bad signature is 400 PAYMENT_VERIFICATION_FAILED',
      () async {
        final repo = PaymentRepositoryRemote(
          dio(
            (o) async => jsonBody(
              '{"code":"PAYMENT_VERIFICATION_FAILED","message":"x"}',
              400,
            ),
          ),
        );
        await expectLater(
          repo.verify(
            'p1',
            providerPaymentId: 'a',
            signature: 'b',
            idempotencyKey: 'key-12345678',
          ),
          throwsA(
            isA<ValidationFailure>().having(
              (e) => e.code,
              'code',
              'PAYMENT_VERIFICATION_FAILED',
            ),
          ),
        );
      },
    );
  });

  test(
    'Razorpay opens only a razorpay checkout; fake or missing is refused',
    () async {
      for (final co in [
        null,
        const PaymentCheckout(gateway: 'fake', orderId: 'o'),
        const PaymentCheckout(gateway: 'razorpay', orderId: 'o'), // no key
      ]) {
        final out = await RazorpayPaymentService().pay(
          Payment(
            id: 'p',
            bookingId: 'b',
            status: PaymentStatus.pending,
            amountMinor: 100,
            checkout: co,
          ),
        );
        expect(out, isA<PaymentSdkFailed>());
        expect((out as PaymentSdkFailed).code, 'CHECKOUT_UNSUPPORTED');
      }
    },
  );

  group('mock', () {
    var paid = <String>[];
    PaymentRepositoryMock make({bool payable = true}) {
      paid = [];
      return PaymentRepositoryMock(
        () => const MockApiState(returningUser: false),
        isPayable: (_) => payable,
        onPaid: paid.add,
        now: () => testNow,
      );
    }

    test('start is idempotent and resumes the open payment', () async {
      final repo = make();
      final a = await repo.start('b1', idempotencyKey: 'key-1-aaaaaa');
      final again = await repo.start('b1', idempotencyKey: 'key-1-aaaaaa');
      final other = await repo.start('b1', idempotencyKey: 'key-2-bbbbbb');
      expect(again.id, a.id);
      expect(other.id, a.id);
    });

    test('booking and refunded filters; no receipt before payment', () async {
      final repo = make();
      final p = await repo.start('b1', idempotencyKey: 'key-1-aaaaaa');
      expect((await repo.list(bookingId: 'b1')).items.single.id, p.id);
      expect((await repo.list(bookingId: 'zz')).items, isEmpty);
      expect((await repo.list(refunded: true)).items, isEmpty);
      await expectLater(
        repo.receipt(p.id),
        throwsA(
          isA<ConflictFailure>().having(
            (e) => e.code,
            'code',
            'RECEIPT_NOT_AVAILABLE',
          ),
        ),
      );
    });

    test(
      'a booking that is not waiting for payment is 409 BOOKING_NOT_PAYABLE',
      () async {
        await expectLater(
          make(payable: false).start('b1', idempotencyKey: 'key-1-aaaaaa'),
          throwsA(
            isA<ConflictFailure>().having(
              (e) => e.code,
              'code',
              'BOOKING_NOT_PAYABLE',
            ),
          ),
        );
      },
    );

    test(
      'verify settles once and confirms the booking; a bad reference changes nothing',
      () async {
        final repo = make();
        final p = await repo.start('b1', idempotencyKey: 'key-1-aaaaaa');
        await expectLater(
          repo.verify(
            p.id,
            providerPaymentId: 'nope',
            signature: 's',
            idempotencyKey: 'key-v-000001',
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect((await repo.get(p.id)).status, PaymentStatus.pending);
        expect(paid, isEmpty);
        final ok = await repo.verify(
          p.id,
          providerPaymentId: '${PaymentRepositoryMock.fakeProviderPrefix}x',
          signature: 's',
          idempotencyKey: 'key-v-000002',
        );
        expect(ok.status, PaymentStatus.succeeded);
        await repo.verify(
          p.id,
          providerPaymentId: '${PaymentRepositoryMock.fakeProviderPrefix}x',
          signature: 's',
          idempotencyKey: 'key-v-000003',
        );
        expect(paid, ['b1']); // a repeat does not pay twice
      },
    );
  });
}
