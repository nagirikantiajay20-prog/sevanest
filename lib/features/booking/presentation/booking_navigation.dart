import 'package:sevanest_customer/app/router/routes.dart';

/// Where "Complete payment" goes. Module 07 creates the payment (`POST /payments {bookingId}`) on
/// this screen, so the booking id travels as `bookingId` and the path id is the literal `new`.
String paymentStartPath(String bookingId) =>
    '${Routes.path(Routes.payment, {'id': 'new'})}?bookingId=${Uri.encodeComponent(bookingId)}';
