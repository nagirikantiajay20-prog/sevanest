/// Support tickets and safety (docs/backend_openapi_2026-10-13.json: `/support/*`, `/safety/*`).
/// The customer view never carries owner, priority or escalation: the schema has none of them and
/// `ESCALATED` is shown as "In progress".
library;

/// `TicketView.status`. Unknown codes map to [unknown] and read "Updated".
enum TicketStatus { open, inProgress, escalated, closed, unknown }

TicketStatus ticketStatusFrom(Object? code) =>
    switch (code is String ? code.toUpperCase() : null) {
      'OPEN' => TicketStatus.open,
      'IN_PROGRESS' => TicketStatus.inProgress,
      'ESCALATED' => TicketStatus.escalated,
      'CLOSED' => TicketStatus.closed,
      _ => TicketStatus.unknown,
    };

/// The customer may still write (the server says 409 `TICKET_CLOSED` otherwise).
bool ticketAcceptsReplies(TicketStatus s) =>
    s == TicketStatus.open ||
    s == TicketStatus.inProgress ||
    s == TicketStatus.escalated;

/// `ESCALATED` is an internal state: the customer sees "In progress".
TicketStatus ticketStatusForCustomer(TicketStatus s) =>
    s == TicketStatus.escalated ? TicketStatus.inProgress : s;

String? _s(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _date(Object? v) {
  final t = v is String ? DateTime.tryParse(v) : null;
  return t != null && t.isUtc ? t.toLocal() : t;
}

Map<dynamic, dynamic>? _obj(Object? json) {
  if (json is! Map) return null;
  return json['data'] is Map ? json['data'] as Map : json;
}

/// `SupportCategoryView`.
class SupportCategory {
  const SupportCategory({
    required this.id,
    required this.code,
    required this.name,
  });
  final String id;
  final String code;
  final String name;

  /// Safety-type categories get the emergency notice (design "Urgent"). The code is the backend's.
  bool get isSafety => code.toUpperCase().contains('SAFETY');

  static SupportCategory? fromJson(Object? json) {
    final j = _obj(json);
    final id = j == null ? null : _s(j['id']);
    final name = j == null ? null : _s(j['name']);
    if (j == null || id == null || name == null) return null;
    return SupportCategory(id: id, code: _s(j['code']) ?? '', name: name);
  }
}

/// `TicketEventView`: what happened and when. Only status changes are shown.
class TicketEvent {
  const TicketEvent({this.from, this.to, this.at});
  final TicketStatus? from;
  final TicketStatus? to;
  final DateTime? at;

  static TicketEvent fromJson(Map<dynamic, dynamic> j) => TicketEvent(
    from: j['fromStatus'] == null ? null : ticketStatusFrom(j['fromStatus']),
    to: j['toStatus'] == null ? null : ticketStatusFrom(j['toStatus']),
    at: _date(j['createdAt']),
  );
}

/// `TicketView` / `TicketDetailView`. There is no subject in the schema: the first words of the
/// description stand in as the title.
class Ticket {
  const Ticket({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    this.bookingId,
    this.resolution,
    this.dueAt,
    this.createdAt,
    this.closedAt,
    this.history = const [],
  });

  final String id;
  final SupportCategory category;
  final String? bookingId;
  final String description;
  final TicketStatus status;
  final String? resolution;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? closedAt;
  final List<TicketEvent> history;

  /// "TK-1A2B3C" style reference taken from the id.
  String get reference {
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return 'TK-${tail.toUpperCase()}';
  }

  /// First line of the description, cut at [max] characters.
  String title([int max = 80]) {
    final line = description.trim().split('\n').first.trim();
    return line.length <= max
        ? line
        : '${line.substring(0, max - 1).trimRight()}…';
  }

  /// Latest known change, for "Updated 2 hours ago".
  DateTime? get updatedAt {
    DateTime? t = closedAt ?? createdAt;
    for (final e in history) {
      final at = e.at;
      if (at != null && (t == null || at.isAfter(t))) t = at;
    }
    return t;
  }

  static Ticket? fromJson(Object? json) {
    final j = _obj(json);
    final id = j == null ? null : _s(j['id']);
    final cat = j == null ? null : SupportCategory.fromJson(j['category']);
    if (j == null || id == null || cat == null) return null;
    final raw = j['history'];
    return Ticket(
      id: id,
      category: cat,
      bookingId: _s(j['bookingId']),
      description: _s(j['description']) ?? '',
      status: ticketStatusFrom(j['status']),
      resolution: _s(j['resolution']),
      dueAt: _date(j['dueAt']),
      createdAt: _date(j['createdAt']),
      closedAt: _date(j['closedAt']),
      history: [
        if (raw is List)
          for (final e in raw)
            if (e is Map) TicketEvent.fromJson(e),
      ],
    );
  }
}

enum MessageAuthor { customer, worker, admin, unknown }

/// `MessageView`. Staff are never identified to the customer.
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.from,
    required this.body,
    this.createdAt,
  });
  final String id;
  final MessageAuthor from;
  final String body;
  final DateTime? createdAt;

  bool get isMine => from == MessageAuthor.customer;

  static TicketMessage? fromJson(Object? json) {
    final j = _obj(json);
    final id = j == null ? null : _s(j['id']);
    final body = j == null ? null : _s(j['body']);
    if (j == null || id == null || body == null) return null;
    return TicketMessage(
      id: id,
      from: switch ('${j['from']}'.toUpperCase()) {
        'CUSTOMER' => MessageAuthor.customer,
        'WORKER' => MessageAuthor.worker,
        'ADMIN' => MessageAuthor.admin,
        _ => MessageAuthor.unknown,
      },
      body: body,
      createdAt: _date(j['createdAt']),
    );
  }
}

class TicketPage {
  const TicketPage(this.items, this.nextCursor);
  final List<Ticket> items;
  final String? nextCursor;
}

class MessagePage {
  const MessagePage(this.items, this.nextCursor);
  final List<TicketMessage> items;
  final String? nextCursor;
}

/// `GET /app-config` -> `support`. Both are null until operations set them.
class SupportContact {
  const SupportContact({this.phone, this.email});
  final String? phone;
  final String? email;
  bool get hasPhone => phone != null;
  bool get hasEmail => email != null;
}

/// `/support/*` of the deployed backend.
abstract interface class SupportRepository {
  /// `GET /support/categories`: the enabled categories, in the backend's order.
  Future<List<SupportCategory>> categories();

  /// `POST /support/tickets`. One key per form: repeating it returns the first ticket.
  /// 422 `SUPPORT_CATEGORY_INVALID`, 404 `BOOKING_NOT_FOUND`.
  Future<Ticket> create({
    required String categoryId,
    required String description,
    String? bookingId,
    required String idempotencyKey,
  });

  /// `GET /support/tickets`: mine, newest first.
  Future<TicketPage> list({String? cursor});

  Future<Ticket> get(String id);

  /// `GET /support/tickets/{id}/messages`: staff internal notes never come back.
  Future<MessagePage> messages(String id, {String? cursor});

  /// `POST /support/tickets/{id}/messages`. 409 `TICKET_CLOSED` once closed.
  Future<TicketMessage> post(
    String id,
    String body, {
    required String idempotencyKey,
  });
}

/// `CreateReportDto.reasonCode`.
enum ReportReason {
  noShow('NO_SHOW'),
  misconduct('MISCONDUCT'),
  harassment('HARASSMENT'),
  theft('THEFT'),
  fraud('FRAUD'),
  safetyConcern('SAFETY_CONCERN'),
  other('OTHER');

  const ReportReason(this.code);
  final String code;
}

/// `BlockView`: the worker reference the customer blocked.
class WorkerBlock {
  const WorkerBlock({required this.id, this.workerId, this.createdAt});
  final String id;
  final String? workerId;
  final DateTime? createdAt;

  static WorkerBlock? fromJson(Object? json) {
    final j = _obj(json);
    final id = j == null ? null : _s(j['id']);
    if (j == null || id == null) return null;
    return WorkerBlock(
      id: id,
      workerId: _s(j['workerId']),
      createdAt: _date(j['createdAt']),
    );
  }
}

/// `/safety/*`. A customer names the worker by `workerId` or by a booking they are a party to.
abstract interface class SafetyRepository {
  /// `POST /safety/reports` (staff are alerted). `alsoBlock` blocks the worker as well.
  Future<void> report({
    String? workerId,
    String? bookingId,
    required ReportReason reason,
    String? note,
    bool alsoBlock = false,
    required String idempotencyKey,
  });

  /// `POST /safety/blocks` (repeating is harmless; 404 for a worker with no relationship).
  Future<WorkerBlock> block({
    String? workerId,
    String? bookingId,
    required String idempotencyKey,
  });

  /// `GET /safety/blocks`.
  Future<List<WorkerBlock>> blocks();

  /// `DELETE /safety/blocks/{id}` (409 `BLOCK_ADMIN_APPLIED` when staff applied it).
  Future<void> unblock(String id);
}
