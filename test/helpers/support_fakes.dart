// Fakes for the support and safety tests (never shipped).
import 'dart:async';

import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';

const fakeCategories = [
  SupportCategory(id: 'c1', code: 'BOOKING', name: 'Booking issue'),
  SupportCategory(id: 'c2', code: 'PAYMENT', name: 'Payment or refund'),
  SupportCategory(id: 'c3', code: 'SAFETY', name: 'Safety or trust concern'),
  SupportCategory(id: 'c4', code: 'OTHER', name: 'Something else'),
];

Ticket ticket(
  String id, {
  TicketStatus status = TicketStatus.open,
  String? bookingId,
  String description = 'The payment was taken twice for my booking.',
  SupportCategory? category,
  String? resolution,
  DateTime? createdAt,
  List<TicketEvent> history = const [],
}) => Ticket(
  id: id,
  category: category ?? fakeCategories[1],
  bookingId: bookingId,
  description: description,
  status: status,
  resolution: resolution,
  createdAt: createdAt ?? DateTime(2026, 10, 9, 8),
  closedAt: status == TicketStatus.closed ? DateTime(2026, 10, 9, 10) : null,
  history: history,
);

TicketMessage msg(
  String id,
  String body, {
  MessageAuthor from = MessageAuthor.admin,
  DateTime? at,
}) => TicketMessage(
  id: id,
  from: from,
  body: body,
  createdAt: at ?? DateTime(2026, 10, 9, 9),
);

class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    List<SupportCategory>? categories,
    List<Ticket>? tickets,
  }) : cats = categories ?? fakeCategories,
       tickets = tickets ?? [];

  List<SupportCategory> cats;
  List<Ticket> tickets;
  final messagesOf = <String, List<TicketMessage>>{};

  Object? categoriesFail;
  Object? listFail;
  Object? getFail;
  Object? messagesFail;
  Object? createFail;
  Object? postFail;

  /// The ticket / message exists on the server although the answer was lost.
  var storeThenFail = false;
  Completer<void>? createGate;
  Completer<void>? postGate;

  int createCalls = 0;
  int postCalls = 0;
  int getCalls = 0;
  final createKeys = <String>[];
  final postKeys = <String>[];
  String? lastCategory;
  String? lastDescription;
  String? lastBooking;
  String? lastBody;
  var _seq = 100;

  @override
  Future<List<SupportCategory>> categories() async {
    final f = categoriesFail;
    if (f != null) throw f;
    return cats;
  }

  @override
  Future<Ticket> create({
    required String categoryId,
    required String description,
    String? bookingId,
    required String idempotencyKey,
  }) async {
    createCalls++;
    createKeys.add(idempotencyKey);
    lastCategory = categoryId;
    lastDescription = description;
    lastBooking = bookingId;
    await createGate?.future;
    final t = ticket(
      'tk_${++_seq}',
      category: cats.firstWhere((c) => c.id == categoryId),
      bookingId: bookingId,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    final f = createFail;
    if (f != null) {
      if (storeThenFail) tickets = [t, ...tickets];
      throw f;
    }
    tickets = [t, ...tickets];
    return t;
  }

  @override
  Future<TicketPage> list({String? cursor}) async {
    final f = listFail;
    if (f != null) throw f;
    return TicketPage(List.of(tickets), null);
  }

  @override
  Future<Ticket> get(String id) async {
    getCalls++;
    final f = getFail;
    if (f != null) throw f;
    return tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<MessagePage> messages(String id, {String? cursor}) async {
    final f = messagesFail;
    if (f != null) throw f;
    return MessagePage(List.of(messagesOf[id] ?? const []), null);
  }

  @override
  Future<TicketMessage> post(
    String id,
    String body, {
    required String idempotencyKey,
  }) async {
    postCalls++;
    postKeys.add(idempotencyKey);
    lastBody = body;
    await postGate?.future;
    final m = msg(
      'm_${++_seq}',
      body.trim(),
      from: MessageAuthor.customer,
      at: DateTime(2026, 10, 9, 11),
    );
    final f = postFail;
    if (f != null) {
      if (storeThenFail) messagesOf[id] = [...?messagesOf[id], m];
      throw f;
    }
    messagesOf[id] = [...?messagesOf[id], m];
    return m;
  }
}

class FakeSafetyRepository implements SafetyRepository {
  Object? reportFail;
  Object? blockFail;
  Completer<void>? gate;
  int reportCalls = 0;
  int blockCalls = 0;
  String? lastWorker;
  String? lastBooking;
  ReportReason? lastReason;
  String? lastNote;
  bool? lastAlsoBlock;
  String? lastKey;

  @override
  Future<void> report({
    String? workerId,
    String? bookingId,
    required ReportReason reason,
    String? note,
    bool alsoBlock = false,
    required String idempotencyKey,
  }) async {
    reportCalls++;
    lastKey = idempotencyKey;
    lastWorker = workerId;
    lastBooking = bookingId;
    lastReason = reason;
    lastNote = note;
    lastAlsoBlock = alsoBlock;
    await gate?.future;
    final f = reportFail;
    if (f != null) throw f;
  }

  @override
  Future<WorkerBlock> block({
    String? workerId,
    String? bookingId,
    required String idempotencyKey,
  }) async {
    blockCalls++;
    lastKey = idempotencyKey;
    lastWorker = workerId;
    lastBooking = bookingId;
    final f = blockFail;
    if (f != null) throw f;
    return WorkerBlock(id: 'blk_1', workerId: workerId);
  }

  @override
  Future<List<WorkerBlock>> blocks() async => const [];

  @override
  Future<void> unblock(String id) async {}
}
