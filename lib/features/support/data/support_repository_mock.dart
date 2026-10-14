import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

/// In-memory tickets behind the dev mock toggle. Seeded with one ticket that support is working
/// on; a ticket the customer raises stays OPEN until [close] is called (staff decide in the real
/// system).
class SupportRepositoryMock implements SupportRepository {
  SupportRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final t = _now();
    final cat = categoriesSeed[1];
    _tickets.add(
      Ticket(
        id: 'tk_1042',
        category: cat,
        bookingId: 'b_2051',
        description:
            'I paid by UPI but the booking still shows payment pending.',
        status: TicketStatus.inProgress,
        createdAt: t.subtract(const Duration(hours: 5)),
        history: [
          TicketEvent(
            from: TicketStatus.open,
            to: TicketStatus.inProgress,
            at: t.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
    );
    _messages['tk_1042'] = [
      TicketMessage(
        id: 'm1',
        from: MessageAuthor.customer,
        body: 'I paid by UPI but the booking still shows payment pending.',
        createdAt: t.subtract(const Duration(hours: 5)),
      ),
      TicketMessage(
        id: 'm2',
        from: MessageAuthor.admin,
        body:
            "We can see your payment. We're checking it with the payment provider.",
        createdAt: t.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  final MockApiState Function() _state;
  final DateTime Function() _now;
  final _tickets = <Ticket>[];
  final _messages = <String, List<TicketMessage>>{};
  final _keys = <String, String>{};
  var _seq = 1042;

  /// Writes that reached the "server" (tests count real writes with these).
  int created = 0;
  int posted = 0;

  static const categoriesSeed = [
    SupportCategory(id: 'c1', code: 'BOOKING', name: 'Booking issue'),
    SupportCategory(id: 'c2', code: 'PAYMENT', name: 'Payment or refund'),
    SupportCategory(id: 'c3', code: 'WORKER', name: 'Worker issue'),
    SupportCategory(id: 'c4', code: 'REPLACEMENT', name: 'Replacement'),
    SupportCategory(id: 'c5', code: 'ACCOUNT', name: 'Account and profile'),
    SupportCategory(id: 'c6', code: 'SAFETY', name: 'Safety or trust concern'),
    SupportCategory(id: 'c7', code: 'OTHER', name: 'Something else'),
  ];

  int _index(String id) {
    final i = _tickets.indexWhere((t) => t.id == id);
    if (i < 0) throw const NotFoundFailure();
    return i;
  }

  /// Staff close a ticket with a resolution.
  void close(String id, String resolution) {
    final i = _index(id);
    final o = _tickets[i];
    _tickets[i] = Ticket(
      id: o.id,
      category: o.category,
      bookingId: o.bookingId,
      description: o.description,
      status: TicketStatus.closed,
      resolution: resolution,
      createdAt: o.createdAt,
      closedAt: _now(),
      history: [
        ...o.history,
        TicketEvent(from: o.status, to: TicketStatus.closed, at: _now()),
      ],
    );
  }

  @override
  Future<List<SupportCategory>> categories() =>
      mockCall(_state(), () => categoriesSeed);

  @override
  Future<Ticket> create({
    required String categoryId,
    required String description,
    String? bookingId,
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final prior = _keys[idempotencyKey];
    if (prior != null) return _tickets[_index(prior)];
    final cat = categoriesSeed.where((c) => c.id == categoryId);
    if (cat.isEmpty) {
      throw const ValidationFailure(null, {}, 'SUPPORT_CATEGORY_INVALID');
    }
    final t = Ticket(
      id: 'tk_${++_seq}',
      category: cat.first,
      bookingId: bookingId,
      description: description.trim(),
      status: TicketStatus.open,
      createdAt: _now(),
    );
    _tickets.add(t);
    _messages[t.id] = [
      TicketMessage(
        id: 'm_${t.id}',
        from: MessageAuthor.customer,
        body: t.description,
        createdAt: t.createdAt,
      ),
    ];
    _keys[idempotencyKey] = t.id;
    created++;
    return t;
  });

  @override
  Future<TicketPage> list({String? cursor}) =>
      mockCall(_state(), () => TicketPage(List.of(_tickets.reversed), null));

  @override
  Future<Ticket> get(String id) =>
      mockCall(_state(), () => _tickets[_index(id)]);

  @override
  Future<MessagePage> messages(String id, {String? cursor}) =>
      mockCall(_state(), () {
        _index(id);
        return MessagePage(List.of(_messages[id] ?? const []), null);
      });

  @override
  Future<TicketMessage> post(
    String id,
    String body, {
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    final i = _index(id);
    final prior = _keys[idempotencyKey];
    final list = _messages.putIfAbsent(id, () => []);
    if (prior != null) return list.firstWhere((m) => m.id == prior);
    if (!ticketAcceptsReplies(_tickets[i].status)) {
      throw const ConflictFailure(null, 'TICKET_CLOSED');
    }
    final m = TicketMessage(
      id: 'm_${++_seq}',
      from: MessageAuthor.customer,
      body: body.trim(),
      createdAt: _now(),
    );
    list.add(m);
    _keys[idempotencyKey] = m.id;
    posted++;
    return m;
  });
}

class SafetyRepositoryMock implements SafetyRepository {
  SafetyRepositoryMock(this._state, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final MockApiState Function() _state;
  final DateTime Function() _now;
  final _blocks = <WorkerBlock>[];

  int reported = 0;
  var _seq = 0;

  /// Worker references the customer blocked in this session.
  Set<String> get blockedWorkerIds => {for (final b in _blocks) ?b.workerId};

  @override
  Future<void> report({
    String? workerId,
    String? bookingId,
    required ReportReason reason,
    String? note,
    bool alsoBlock = false,
    required String idempotencyKey,
  }) => mockCall(_state(), () {
    reported++;
    if (alsoBlock && workerId != null) _add(workerId);
  });

  WorkerBlock _add(String workerId) {
    final existing = _blocks.where((b) => b.workerId == workerId);
    if (existing.isNotEmpty) return existing.first;
    final b = WorkerBlock(
      id: 'blk_${++_seq}',
      workerId: workerId,
      createdAt: _now(),
    );
    _blocks.add(b);
    return b;
  }

  @override
  Future<WorkerBlock> block({
    String? workerId,
    String? bookingId,
    required String idempotencyKey,
  }) => mockCall(_state(), () => _add(workerId ?? bookingId ?? ''));

  @override
  Future<List<WorkerBlock>> blocks() =>
      mockCall(_state(), () => List.of(_blocks));

  @override
  Future<void> unblock(String id) => mockCall(_state(), () {
    final before = _blocks.length;
    _blocks.removeWhere((b) => b.id == id);
    if (_blocks.length == before) throw const NotFoundFailure();
  });
}
