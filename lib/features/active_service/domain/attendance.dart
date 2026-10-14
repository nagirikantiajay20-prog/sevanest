import 'package:sevanest_customer/features/booking/domain/booking.dart';

/// What the backend records for one day. LATE and LEAVE are not in the written spec yet (Q-101,
/// awaiting client sign-off). Anything else maps to [unknown] and reads "Updated", never a guess.
enum AttendanceStatus { present, absent, late, leave, exception, unknown }

AttendanceStatus attendanceStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'PRESENT' => AttendanceStatus.present,
      'ABSENT' => AttendanceStatus.absent,
      'LATE' => AttendanceStatus.late,
      'LEAVE' => AttendanceStatus.leave,
      'EXCEPTION' => AttendanceStatus.exception,
      _ => AttendanceStatus.unknown,
    };

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.date,
    required this.status,
    this.note,
    this.checkInAt,
    this.checkOutAt,
  });

  final String id;

  /// India calendar day, `YYYY-MM-DD`.
  final String date;
  final AttendanceStatus status;
  final String? note;

  /// Stamped by the server when the worker taps check-in / check-out; null otherwise.
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

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
      checkInAt: _time(j['checkInAt']),
      checkOutAt: _time(j['checkOutAt']),
    );
  }
}

DateTime? _time(Object? v) {
  final d = v is String ? DateTime.tryParse(v) : null;
  return d != null && d.isUtc ? d.toLocal() : d;
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
    this.late = 0,
    this.leave = 0,
    this.scheduledFrom,
    this.scheduledTo,
    this.worker,
  });

  final String month;
  final int present;
  final int absent;
  final int exception;
  final int late;
  final int leave;

  /// The booking's own hours (`scheduledWindow {from,to}`), `HH:mm`.
  final String? scheduledFrom;
  final String? scheduledTo;
  final WorkerIdentity? worker;

  static AttendanceSummary? fromJson(Object? j) {
    if (j is! Map) return null;
    int n(Object? v) => v is num ? v.toInt() : 0;
    final w = j['scheduledWindow'];
    return AttendanceSummary(
      month: '${j['month'] ?? ''}',
      present: n(j['present']),
      absent: n(j['absent']),
      exception: n(j['exception']),
      late: n(j['late']),
      leave: n(j['leave']),
      scheduledFrom: w is Map && w['from'] is String
          ? w['from'] as String
          : null,
      scheduledTo: w is Map && w['to'] is String ? w['to'] as String : null,
      worker: WorkerIdentity.fromJson(j['worker']),
    );
  }
}

/// Customers read attendance only (`/attendance/bookings/{id}`); the worker records it.
abstract interface class AttendanceRepository {
  Future<AttendancePage> page(String bookingId, {String? cursor});
  Future<AttendanceSummary> summary(String bookingId, String month);

  /// `POST /attendance/bookings/{id}/exceptions`: a day the worker did not record. Only for the
  /// customer's own ACTIVE booking, a date from the start date to today, with no entry yet
  /// (409 otherwise); the note is 1 to 500 characters.
  Future<AttendanceEntry> raiseException(
    String bookingId, {
    required String date,
    required String note,
    required String idempotencyKey,
  });
}
