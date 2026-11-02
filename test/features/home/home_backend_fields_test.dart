// UNIT: Home `todayAttendance` and `topRated[]` parsing.
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';

void main() {
  test(
    'todayAttendance maps every status, unknown falls back to notArrived',
    () {
      for (final (code, want) in [
        ('ARRIVED', HomeAttendanceStatus.arrived),
        ('NOT_ARRIVED', HomeAttendanceStatus.notArrived),
        ('ABSENT', HomeAttendanceStatus.absent),
        ('LEAVE', HomeAttendanceStatus.leave),
        ('EXCEPTION', HomeAttendanceStatus.exception),
        ('SOMETHING_NEW', HomeAttendanceStatus.notArrived),
      ]) {
        expect(
          TodayAttendance.fromJson({
            'bookingId': 'b-1',
            'status': code,
            'workerName': 'Ramesh K.',
          })!.status,
          want,
          reason: code,
        );
      }
      expect(TodayAttendance.fromJson(null), isNull);
    },
  );

  test('arrivedAt is null when the backend sends none', () {
    final a = TodayAttendance.fromJson({
      'bookingId': 'b-1',
      'status': 'ARRIVED',
      'arrivedAt': '2026-11-02T03:35:12.000Z',
    })!;
    expect(a.arrivedAt, isNotNull);
    expect(
      TodayAttendance.fromJson({
        'bookingId': 'b-1',
        'status': 'NOT_ARRIVED',
      })!.arrivedAt,
      isNull,
    );
  });

  test('topRated parses the example row and skips unusable ones', () {
    final w = TopRatedWorker.fromJson({
      'workerId': 'w-1',
      'name': 'Meena P.',
      'photoUrl': null,
      'roleName': 'House Maid',
      'ratingAverage': 5,
      'ratingCount': 1,
      'completedJobs': 1,
      'latestReviewSnippet': 'Excellent work.',
      'verified': true,
    })!;
    expect(w.ratingAverage, 5.0);
    expect(w.ratingCount, 1);
    expect(w.reviewSnippet, 'Excellent work.');
    expect(TopRatedWorker.fromJson({'name': 'no id'}), isNull);
    final cached = HomeData.fromJson({
      ...const HomeData().toJson(),
      'topRated': [w.toJson()],
    });
    expect(cached.topRated.single.workerId, 'w-1');
  });
}
