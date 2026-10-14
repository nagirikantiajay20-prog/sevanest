import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/active_service/domain/attendance.dart';

/// Seeded attendance for the active mock booking `bk_2048` (dev toggle only).
class AttendanceRepositoryMock implements AttendanceRepository {
  AttendanceRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MockApiState Function() _state;
  final DateTime Function() _now;

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final _raised = <AttendanceEntry>[];

  List<AttendanceEntry> _entries() {
    final n = _now();
    final today = DateTime(n.year, n.month, n.day);
    return [
      ..._raised,
      for (var i = 0; i < 3; i++)
        AttendanceEntry(
          id: 'at_$i',
          date: _day(today.subtract(Duration(days: i))),
          status: i == 1 ? AttendanceStatus.absent : AttendanceStatus.present,
          note: i == 1 ? 'Called in sick' : null,
        ),
    ];
  }

  @override
  Future<AttendancePage> page(String bookingId, {String? cursor}) => mockCall(
    _state(),
    () => AttendancePage(
      _state().mode == MockMode.empty || bookingId != 'bk_2048'
          ? const []
          : _entries(),
      null,
    ),
  );

  @override
  Future<AttendanceSummary> summary(String bookingId, String month) =>
      mockCall(_state(), () {
        final e = bookingId == 'bk_2048'
            ? _entries().where((x) => x.date.startsWith(month))
            : const <AttendanceEntry>[];
        int c(AttendanceStatus s) => e.where((x) => x.status == s).length;
        return AttendanceSummary(
          month: month,
          present: c(AttendanceStatus.present),
          absent: c(AttendanceStatus.absent),
          exception: c(AttendanceStatus.exception),
          late: c(AttendanceStatus.late),
          leave: c(AttendanceStatus.leave),
        );
      });

  @override
  Future<AttendanceEntry> raiseException(
    String bookingId, {
    required String date,
    required String note,
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    if (_entries().any((e) => e.date == date)) {
      throw const ConflictFailure('Entry exists', 'ATTENDANCE_EXISTS');
    }
    final e = AttendanceEntry(
      id: 'at_x${_raised.length}',
      date: date,
      status: AttendanceStatus.exception,
      note: note,
    );
    _raised.add(e);
    return e;
  });
}
