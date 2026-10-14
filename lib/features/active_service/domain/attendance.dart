/// What the backend records for one day (Swagger `AttendanceView.status`). Anything else maps to
/// [unknown] and reads "Updated", never a guess.
enum AttendanceStatus { present, absent, exception, unknown }

AttendanceStatus attendanceStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'PRESENT' => AttendanceStatus.present,
      'ABSENT' => AttendanceStatus.absent,
      'EXCEPTION' => AttendanceStatus.exception,
      _ => AttendanceStatus.unknown,
    };

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.date,
    required this.status,
    this.note,
  });

  final String id;

  /// India calendar day, `YYYY-MM-DD`.
  final String date;
  final AttendanceStatus status;
  final String? note;

  DateTime? get day => DateTime.tryParse(date);

  static AttendanceEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final date = j['date'];
    if (date is! String || date.isEmpty) return null;
    final note = j['note'];
    return AttendanceEntry(
      id: '${j['id'] ?? date}',
      date: date.length > 10 ? date.substring(0, 10) : date,
      status: attendanceStatusFrom(j['status']),
      note: note is String && note.isNotEmpty ? note : null,
    );
  }
}

class AttendancePage {
  const AttendancePage(this.items, this.nextCursor);
  final List<AttendanceEntry> items;
  final String? nextCursor;
}

/// `GET /attendance/bookings/{id}/summary?month=YYYY-MM`.
class AttendanceSummary {
  const AttendanceSummary({
    required this.month,
    required this.present,
    required this.absent,
    required this.exception,
  });

  final String month;
  final int present;
  final int absent;
  final int exception;

  static AttendanceSummary? fromJson(Object? j) {
    if (j is! Map) return null;
    int n(Object? v) => v is num ? v.toInt() : 0;
    return AttendanceSummary(
      month: '${j['month'] ?? ''}',
      present: n(j['present']),
      absent: n(j['absent']),
      exception: n(j['exception']),
    );
  }
}

/// Customers read attendance only (`/attendance/bookings/{id}`); the worker records it.
abstract interface class AttendanceRepository {
  Future<AttendancePage> page(String bookingId, {String? cursor});
  Future<AttendanceSummary> summary(String bookingId, String month);
}
