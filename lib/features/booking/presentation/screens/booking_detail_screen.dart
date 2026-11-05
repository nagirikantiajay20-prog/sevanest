import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_navigation.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/booking_detail_parts.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/cancel_sheet.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/hire_again_button.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart'
    show minorAmount;
import 'package:sevanest_customer/features/payment/presentation/pending_payment_banner.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_links.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show experienceLabel, ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/bookings/:id` (module 08, screen 8.3). Buttons follow the booking's allowed actions.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({required this.bookingId, super.key});
  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _State();
}

class _State extends ConsumerState<BookingDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The status can change while the app is in the background (a worker acts, a payment lands).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(bookingProvider(widget.bookingId));
    }
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await showCancelSheet(
      context,
      onConfirm: (reason) async {
        await ref
            .read(bookingRepositoryProvider)
            .cancel(widget.bookingId, reason);
      },
    );
    if (done != true) return;
    ref
      ..invalidate(bookingProvider(widget.bookingId))
      ..invalidate(bookingListProvider)
      ..invalidate(interviewProvider(widget.bookingId))
      ..invalidate(interviewListProvider)
      ..invalidate(homeProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.cancelRequested)));
  }

  /// The paid payment of this booking (`GET /payments?bookingId=`); the list when none is found.
  Future<void> _receipt(Booking b) async {
    final id = b.paymentId ?? await paidPaymentIdOf(ref, b.id);
    if (!mounted) return;
    await context.push(
      id == null
          ? Routes.transactions
          : Routes.path(Routes.transactionDetail, {'id': id}),
    );
  }

  Future<void> _copyReference(Booking b) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: b.reference));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.bookingRefCopied)));
  }

  /// A booking and its interview have different ids on the backend: look the interview up, then
  /// open it ([reschedule] false) or move it ([reschedule] true; none open = a new request).
  Future<void> _interview(Booking b, {required bool reschedule}) async {
    if (_opening) return;
    _opening = true;
    try {
      await _openInterview(b, reschedule: reschedule);
    } finally {
      _opening = false;
    }
  }

  bool _opening = false;

  Future<void> _openInterview(Booking b, {required bool reschedule}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final String? id;
    try {
      id = await ref
          .read(interviewRepositoryProvider)
          .interviewIdFor(b.id, openOnly: reschedule);
    } on Object catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(l10n, e))));
      return;
    }
    if (!mounted) return;
    if (reschedule) {
      final worker = Uri.encodeComponent(b.workerId!);
      await context.push(
        '${Routes.interviewNew}?workerId=$worker'
        '${id == null ? '' : '&rescheduleId=${Uri.encodeComponent(id)}'}',
      );
    } else if (id != null) {
      await context.push(Routes.path(Routes.interviewDetail, {'id': id}));
    }
    // This screen stays mounted under the pushed one: read the booking again on the way back so
    // the status, time and buttons show what the backend now holds.
    if (mounted) ref.invalidate(bookingProvider(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(bookingProvider(widget.bookingId));
    // A notification arrived (payment confirmed, interview confirmed...): read the booking again.
    ref.listen(
      notificationTickProvider,
      (_, _) => ref.invalidate(bookingProvider(widget.bookingId)),
    );
    final b = value.value;
    final primary = b == null ? null : _primary(l10n, b);
    return FindGlassPage(
      title: l10n.bookingDetailTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.bookings),
      // Report / block the worker of this booking (module 12), named by the booking.
      trailing: b?.workerId == null
          ? null
          : DiscoverGlass(
              radius: 22,
              child: SafetyMenuButton(
                bookingId: widget.bookingId,
                color: dsNavy,
              ),
            ),
      body: AsyncValueView<Booking>(
        value: value,
        onRetry: () => ref.invalidate(bookingProvider(widget.bookingId)),
        data: (b) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookingProvider(widget.bookingId));
            try {
              await ref.read(bookingProvider(widget.bookingId).future);
            } on Object {
              // shown by the view
            }
          },
          child: _Body(
            booking: b,
            primaryKey: primary?.key,
            onCancel: _cancel,
            onReceipt: () => _receipt(b),
            onCopy: () => _copyReference(b),
            onSchedule: () => _interview(b, reschedule: true),
            onViewInterview: () => _interview(b, reschedule: false),
          ),
        ),
      ),
      bottom: primary == null
          ? null
          : Builder(
              builder: (ctx) => AuthCta(
                key: primary.key,
                clock: DiscoverClock.of(ctx),
                label: primary.label,
                loadingLabel: primary.label,
                loading: false,
                breathe: true,
                icon: primary.icon ?? Icons.arrow_forward_rounded,
                radius: 18,
                height: 58,
                onPressed: primary.onTap,
              ),
            ),
    );
  }

  /// The one big button of the bottom bar: pay, confirm, open the service, rate, or, once it
  /// ended, look for another worker. The other actions sit in the body.
  _Primary? _primary(AppLocalizations l10n, Booking b) {
    final a = b.actions;
    if (a.contains(BookingAction.pay)) {
      final fee = ref.watch(bookingFeeProvider(b.id)).value;
      return _Primary(
        const Key('booking_pay_btn'),
        fee == null
            ? l10n.bookingPayNow
            : l10n.bookingPayNowAmount(minorAmount(fee)),
        () => context.push(paymentStartPath(b.id)),
      );
    }
    if (a.contains(BookingAction.confirmWorker)) {
      return _Primary(
        const Key('booking_confirm_worker_btn'),
        l10n.bookingConfirmWorker,
        () => context.push(
          '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(b.id)}',
        ),
      );
    }
    // Worker matched, nothing booked yet: the next step is the interview/trial request.
    if (b.workerId != null &&
        a.contains(BookingAction.schedule) &&
        b.scheduledAt == null) {
      return _Primary(
        const Key('booking_schedule_btn'),
        l10n.bookingSchedule,
        () => _interview(b, reschedule: true),
        icon: Icons.event_available_rounded,
      );
    }
    if (a.contains(BookingAction.viewService)) {
      return _Primary(
        const Key('booking_view_service_btn'),
        l10n.bookingViewService,
        () => context.push(
          '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
        ),
      );
    }
    if (a.contains(BookingAction.rate)) {
      return _Primary(
        const Key('booking_rate_btn'),
        l10n.bookingRate,
        () => context.push(Routes.path(Routes.rating, {'id': b.id})),
      );
    }
    if (b.status == BookingStatus.cancelled) {
      return _Primary(
        const Key('booking_find_another_btn'),
        l10n.workerFindAnother,
        () => context.go(Routes.workers),
        icon: Icons.search_rounded,
      );
    }
    return null;
  }
}

class _Primary {
  const _Primary(this.key, this.label, this.onTap, {this.icon});
  final Key key;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.booking,
    required this.primaryKey,
    required this.onCancel,
    required this.onReceipt,
    required this.onCopy,
    required this.onSchedule,
    required this.onViewInterview,
  });
  final Booking booking;

  /// The bottom bar carries this action; the others are listed in the body.
  final Key? primaryKey;
  final VoidCallback onCancel;
  final VoidCallback onReceipt;
  final VoidCallback onCopy;
  final VoidCallback onSchedule;
  final VoidCallback onViewInterview;

  static const _path = [
    BookingStatus.newRequest,
    BookingStatus.matched,
    BookingStatus.interviewTrialScheduled,
    BookingStatus.interviewTrialCompleted,
    BookingStatus.pendingPayment,
    BookingStatus.confirmed,
    BookingStatus.active,
    BookingStatus.completed,
  ];

  /// "Fri 30 Oct, 10:00 AM".
  static String _stamp(DateTime d, String locale) =>
      '${formatDate(d, locale)}, ${formatTime(d.hour * 60 + d.minute)}';

  /// Backend events when it sends them (unknown ones read "Updated"); otherwise the happy path
  /// with the current state marked.
  List<TimelineStep> _timeline(AppLocalizations l, String locale) {
    // Deduped again here so a booking built elsewhere (cache, mock) cannot show a stage twice.
    final tl = dedupeTimeline(booking.timeline);
    if (tl.isNotEmpty) {
      final last = tl.length - 1;
      final when = booking.scheduledAt;
      // Only the newest "scheduled" entry carries the time the backend holds now.
      final scheduledIdx = tl.lastIndexWhere(
        (e) => e.status == BookingStatus.interviewTrialScheduled,
      );
      final firstMatched = tl.indexWhere(
        (e) => e.status == BookingStatus.matched,
      );
      return [
        for (var i = 0; i < tl.length; i++)
          TimelineStep(
            // A MATCHED entry after the first one is "not a fit, matched again".
            tl[i].status == BookingStatus.matched && i != firstMatched
                ? l.bookingStatusRematched
                : bookingStatusLabel(l, tl[i].status),
            tl[i].status == BookingStatus.cancelled
                ? TimelineState.failed
                : i == last && !bookingIsPast(booking.status)
                ? TimelineState.current
                : TimelineState.done,
            [
              tl[i].note ??
                  (i == scheduledIdx && when != null
                      ? '${interviewTypeName(l, booking.scheduleType ?? InterviewType.interview)} · ${_stamp(when, locale)}'
                      : null),
              if (tl[i].at != null) _stamp(tl[i].at!, locale),
            ].whereType<String>().join(' · '),
          ),
      ];
    }
    final at = _path.indexOf(booking.status);
    return [
      for (var i = 0; i < _path.length; i++)
        TimelineStep(
          bookingStatusLabel(l, _path[i]),
          at < 0
              ? TimelineState.upcoming
              : i < at
              ? TimelineState.done
              : i == at
              ? TimelineState.current
              : TimelineState.upcoming,
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final a = b.actions;
    final budget = bookingBudgetLabel(l10n, b);
    final at = b.scheduledAt;
    final worker = b.worker;
    final id = b.identity;
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final name = id?.displayName ?? worker?.title;
    final canMove = a.contains(BookingAction.schedule) && b.workerId != null;
    final inInterviewStage =
        b.workerId != null &&
        (b.status == BookingStatus.matched ||
            b.status == BookingStatus.interviewTrialScheduled ||
            b.status == BookingStatus.interviewTrialCompleted);
    final paid =
        b.status == BookingStatus.confirmed ||
        b.status == BookingStatus.active ||
        b.status == BookingStatus.replacementRequested ||
        b.status == BookingStatus.replaced ||
        b.status == BookingStatus.completed;
    final due = b.status == BookingStatus.pendingPayment;
    final tone = switch (b.status) {
      BookingStatus.cancelled => HeroTone.bad,
      BookingStatus.confirmed ||
      BookingStatus.active ||
      BookingStatus.completed => HeroTone.ok,
      _ => HeroTone.waiting,
    };

    final rows = <(String, String)>[
      (
        l10n.bookingServiceRow,
        [
          b.categoryName ?? b.categoryCode,
          if (b.engagement != null) engagementLabels(l10n, b.engagement!).name,
        ].whereType<String>().join(' · '),
      ),
      if (b.startDate != null)
        (l10n.bookingScheduleRow, formatDate(b.startDate!, locale)),
      if (at != null)
        (
          l10n.bookingInterviewRow,
          '${interviewTypeName(l10n, b.scheduleType!)} · ${_stamp(at, locale)}',
        ),
      if (b.areaName != null) (l10n.bookingAreaRow, b.areaName!),
      if (budget != null) (l10n.bookingBudgetRow, budget),
      if (b.note != null) (l10n.bookingNoteRow, b.note!),
      (l10n.bookingReferenceRow, b.reference),
      (
        l10n.bookingPaymentRow,
        due
            ? l10n.bookingPaymentDue
            : paid
            ? l10n.bookingPayPaid
            : l10n.bookingPaymentNone,
      ),
    ];
    final refIndex = rows.indexWhere((r) => r.$1 == l10n.bookingReferenceRow);
    final payIndex = rows.length - 1;

    void openWorker() =>
        context.push(Routes.path(Routes.workerDetail, {'id': b.workerId!}));

    Widget outline(String key, String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: OutlineAction(key: Key(key), label: label, onPressed: onTap),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PendingPaymentBanner(bookingId: b.id),
          if (due)
            DiscoverRise(
              delayMs: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: BookingPayBanner(
                  title: l10n.bookingPayBannerTitle,
                  body: l10n.bookingPayBannerBody,
                ),
              ),
            ),
          DiscoverRise(
            delayMs: 60,
            child: InterviewHero(
              statusLabel: bookingStatusLabel(l10n, b.status),
              headline: bookingHeadline(l10n, b.status, name),
              copy: bookingStatusCopy(l10n, b, locale),
              progress: bookingProgress(b.status),
              tone: tone,
              showSteps: false,
              chipKey: const Key('booking_status_chip'),
              copyKey: const Key('booking_status_copy'),
            ),
          ),
          if (b.workerId != null) ...[
            const SizedBox(height: 14),
            DiscoverRise(
              delayMs: 100,
              child: KeyedSubtree(
                key: const Key('booking_worker_card'),
                child: name == null
                    ? InterviewWorkerCard(
                        title: l10n.workerProfileTitle,
                        initials: null,
                        photoUrl: null,
                        gradient: const [Color(0xFF475569), Color(0xFF94A3B8)],
                        verified: false,
                        rating: null,
                        onTap: openWorker,
                      )
                    : InterviewWorkerCard(
                        title: name,
                        initials: id?.initials ?? worker?.initials,
                        photoUrl: id?.photoUrl ?? worker?.photoUrl,
                        gradient: avatarGradientFor(b.workerId!),
                        verified: id?.verified ?? worker?.verified ?? false,
                        rating: worker != null && worker.hasRating
                            ? ratingText(worker.ratingAverage!, scale)
                            : null,
                        extra: worker?.experienceMonths == null
                            ? null
                            : experienceLabel(l10n, worker!.experienceMonths),
                        onTap: openWorker,
                      ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 160,
            child: InterviewInfoCard(
              rows: rows,
              valueColor: (i) => i != payIndex
                  ? null
                  : due
                  ? const Color(0xFFB45309)
                  : paid
                  ? const Color(0xFF0F766E)
                  : dsMuted,
              trailing: (i) => i == refIndex
                  ? CopyPill(label: l10n.bookingCopyRef, onTap: onCopy)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
            child: DiscoverRise(
              delayMs: 220,
              child: Semantics(
                header: true,
                child: Text(l10n.bookingTimeline, style: authSerif(22, 1.2)),
              ),
            ),
          ),
          DiscoverRise(
            delayMs: 260,
            child: GlassTimeline(steps: _timeline(l10n, locale)),
          ),
          const SizedBox(height: 4),
          DiscoverRise(
            delayMs: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (a.contains(BookingAction.pay) &&
                    primaryKey != const Key('booking_pay_btn'))
                  outline(
                    'booking_pay_btn',
                    l10n.bookingPayNow,
                    () => context.push(paymentStartPath(b.id)),
                  ),
                if (a.contains(BookingAction.confirmWorker) &&
                    primaryKey != const Key('booking_confirm_worker_btn'))
                  outline(
                    'booking_confirm_worker_btn',
                    l10n.bookingConfirmWorker,
                    () => context.push(
                      '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(b.id)}',
                    ),
                  ),
                // Nothing booked yet: offer to schedule. Once the backend holds a time, the
                // interview details lead and the same transition is only a reschedule.
                if (canMove &&
                    at == null &&
                    primaryKey != const Key('booking_schedule_btn'))
                  outline(
                    'booking_schedule_btn',
                    l10n.bookingSchedule,
                    onSchedule,
                  ),
                if (inInterviewStage)
                  outline(
                    'booking_interview_btn',
                    l10n.bookingViewInterview,
                    onViewInterview,
                  ),
                if (canMove && at != null)
                  outline(
                    'booking_reschedule_btn',
                    l10n.interviewReschedule,
                    onSchedule,
                  ),
                if (a.contains(BookingAction.viewService) &&
                    primaryKey != const Key('booking_view_service_btn'))
                  outline(
                    'booking_view_service_btn',
                    l10n.bookingViewService,
                    () => context.push(
                      '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
                    ),
                  ),
                if (a.contains(BookingAction.rate) &&
                    primaryKey != const Key('booking_rate_btn'))
                  outline(
                    'booking_rate_btn',
                    l10n.bookingRate,
                    () =>
                        context.push(Routes.path(Routes.rating, {'id': b.id})),
                  ),
                if (a.contains(BookingAction.receipt))
                  outline(
                    'booking_receipt_btn',
                    l10n.bookingReceipt,
                    onReceipt,
                  ),
                if (a.contains(BookingAction.rebook))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: HireAgainButton(bookingId: b.id, glass: true),
                  ),
                if (a.contains(BookingAction.replace))
                  outline(
                    'booking_replace_btn',
                    l10n.bookingReplace,
                    () => context.push(
                      '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(b.id)}',
                    ),
                  ),
                ReplacementLinks(booking: b),
                const SizedBox(height: 6),
                if (a.contains(BookingAction.cancel))
                  QuietAction(
                    key: const Key('booking_cancel_btn'),
                    label: l10n.bookingCancel,
                    danger: true,
                    onPressed: onCancel,
                  ),
                if (b.previousBookingId != null)
                  QuietAction(
                    key: const Key('booking_previous_link'),
                    label: l10n.bookingPreviousLink,
                    onPressed: () => context.push(
                      Routes.path(Routes.bookingDetail, {
                        'id': b.previousBookingId!,
                      }),
                    ),
                  ),
                QuietAction(
                  key: const Key('booking_support_btn'),
                  label: l10n.bookingSupport,
                  onPressed: () => context.push(
                    '${Routes.supportNew}?bookingId=${Uri.encodeComponent(b.id)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
