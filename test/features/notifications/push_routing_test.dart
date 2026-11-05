import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/notifications/domain/notification.dart';

void main() {
  test('payload forms route to the right screen', () {
    expect(routeForPushData({'route': 'rating:b1'}), '/ratings/b1');
    expect(
      routeForPushData({
        'route': {'type': 'ticket', 'id': 't1'},
      }),
      '/support/t1',
    );
    expect(routeForPushData({'type': 'booking', 'id': 'b1'}), '/bookings/b1');
    expect(routeForPushData({'type': 'rating'}), '/notifications');
    expect(routeForPushData({}), '/notifications');
  });
}
