import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';

void main() {
  const areas = [
    ServiceArea(id: 'a1', name: 'Madhapur'),
    ServiceArea(id: 'a2', name: 'Gachibowli'),
  ];

  test('matches area names ignoring case and spaces', () {
    expect(serviceAreaIdFor(areas, ' madhapur '), 'a1');
    expect(serviceAreaIdFor(areas, 'Gachibowli'), 'a2');
  });

  test(
    'unknown area gives null',
    () => expect(serviceAreaIdFor(areas, 'Kondapur'), isNull),
  );
}
