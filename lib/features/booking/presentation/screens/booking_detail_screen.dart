import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_navigation.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/cancel_sheet.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/hire_again_button.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/worker_identity_tile.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/pending_payment_banner.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_links.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/safety_actions.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
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
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.bookingDetailTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.bookings),
            // Report / block the worker of this booking (module 12), named by the booking.
            trailing: value.hasValue && value.requireValue.workerId != null
                ? SafetyMenuButton(bookingId: widget.bookingId)
                : null,
          ),
          Expanded(child: _content(value)),
        ],
      ),
    );
  }

  Widget _content(AsyncValue<Booking> value) {
    return AsyncValueView<Booking>(
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
          onCancel: _cancel,
          onReceipt: () => _receipt(b),
          onSchedule: () => _interview(b, reschedule: true),
          onViewInterview: () => _interview(b, reschedule: false),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.booking,
    required this.onCancel,
    required this.onReceipt,
    required this.onSchedule,
    required this.onViewInterview,
  });
  final Booking booking;
  final VoidCallback onCancel;
  final VoidCallback onReceipt;
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

  /// Backend events when it sends them (unknown ones read "Updated"); otherwise the happy path
  /// with the current state marked.
  List<SnTimelineItem> _timeline(AppLocalizations l, String locale) {
    if (booking.timeline.isNotEmpty) {
      final last = booking.timeline.length - 1;
      final when = booking.scheduledAt;
      // Only the newest "scheduled" entry carries the time the backend holds now.
      final scheduledIdx = booking.timeline.lastIndexWhere(
        (e) => e.status == BookingStatus.interviewTrialScheduled,
      );
      return [
        for (var i = 0; i < booking.timeline.length; i++)
          SnTimelineItem(
            title: bookingStatusLabel(l, booking.timeline[i].status),
            subtitle:
                booking.timeline[i].note ??
                (i == scheduledIdx && when != null
                    ? '${interviewTypeName(l, booking.scheduleType ?? InterviewType.interview)} · ${formatDate(when, locale)}, ${formatTime(when.hour * 60 + when.minute)}'
                    : null),
            timestamp: booking.timeline[i].at == null
                ? null
                : '${formatDate(booking.timeline[i].at!, locale)}, ${formatTime(booking.timeline[i].at!.hour * 60 + booking.timeline[i].at!.minute)}',
            state: booking.timeline[i].status == BookingStatus.cancelled
                ? SnTimelineState.failed
                : i == last && !bookingIsPast(booking.status)
                ? SnTimelineState.current
                : SnTimelineState.done,
          ),
      ];
    }
    final at = _path.indexOf(booking.status);
    return [
      for (var i = 0; i < _path.length; i++)
        SnTimelineItem(
          title: bookingStatusLabel(l, _path[i]),
          state: at < 0
              ? SnTimelineState.upcoming
              : i < at
              ? SnTimelineState.done
              : i == at
              ? SnTimelineState.current
              : SnTimelineState.upcoming,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final a = b.actions;
    final budget = bookingBudgetLabel(l10n, b);
    final at = b.scheduledAt;
    final canMove = a.contains(BookingAction.schedule) && b.workerId != null;
    final inInterviewStage =
        b.workerId != null &&
        (b.status == BookingStatus.matched ||
            b.status == BookingStatus.interviewTrialScheduled ||
            b.status == BookingStatus.interviewTrialCompleted);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppText.meta)),
          Expanded(child: Text(value, style: AppText.bodyLarge)),
        ],
      ),
    );

    Widget action(
      String key,
      String label,
      VoidCallback onTap, {
      SnButtonVariant variant = SnButtonVariant.secondary,
    }) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SnButton(
        key: Key(key),
        label: label,
        variant: variant,
        onPressed: onTap,
      ),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PendingPaymentBanner(bookingId: b.id),
          SnCard(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SnBadge(
                  key: const Key('booking_status_chip'),
                  label: bookingStatusLabel(l10n, b.status),
                  tone: bookingStatusTone(b.status),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  bookingStatusCopy(l10n, b, locale),
                  key: const Key('booking_status_copy'),
                  style: AppText.card,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (b.identity != null && b.workerId != null)
            WorkerIdentityTile(
              key: const Key('booking_worker_card'),
              identity: b.identity!,
              onTap: () => context.push(
                Routes.path(Routes.workerDetail, {'id': b.workerId!}),
              ),
            )
          else if (b.worker != null)
            WorkerCard(
              key: const Key('booking_worker_card'),
              worker: b.worker!,
              onTap: () => context.push(
                Routes.path(Routes.workerDetail, {'id': b.worker!.id}),
              ),
            )
          else if (b.workerId != null)
            ListTile(
              key: const Key('booking_worker_card'),
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.workerProfileTitle),
              onTap: () => context.push(
                Routes.path(Routes.workerDetail, {'id': b.workerId!}),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SnCard(
            child: Column(
              children: [
                row(
                  l10n.bookingServiceRow,
                  [
                    b.categoryName ?? b.categoryCode,
                    if (b.engagement != null)
                      engagementLabels(l10n, b.engagement!).name,
                  ].whereType<String>().join(' · '),
                ),
                if (b.startDate != null)
                  row(
                    l10n.bookingScheduleRow,
                    formatDate(b.startDate!, locale),
                  ),
                if (at != null)
                  row(
                    l10n.bookingInterviewRow,
                    '${interviewTypeName(l10n, b.scheduleType!)} · ${formatDate(at, locale)}, ${formatTime(at.hour * 60 + at.minute)}',
                  ),
                if (b.areaName != null) row(l10n.bookingAreaRow, b.areaName!),
                if (budget != null) row(l10n.bookingBudgetRow, budget),
                if (b.note != null) row(l10n.bookingNoteRow, b.note!),
                row(l10n.bookingReferenceRow, b.reference),
                row(
                  l10n.bookingPaymentRow,
                  b.status == BookingStatus.pendingPayment
                      ? l10n.bookingPaymentDue
                      : l10n.bookingPaymentNone,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.bookingTimeline, style: AppText.heading),
          const SizedBox(height: AppSpacing.sm),
          SnCard(child: SnTimeline(items: _timeline(l10n, locale))),
          const SizedBox(height: AppSpacing.md),
          if (a.contains(BookingAction.pay))
            action(
              'booking_pay_btn',
              l10n.bookingPayNow,
              () => context.push(paymentStartPath(b.id)),
              variant: SnButtonVariant.deep,
            ),
          if (a.contains(BookingAction.confirmWorker))
            action(
              'booking_confirm_worker_btn',
              l10n.bookingConfirmWorker,
              () => context.push(
                '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(b.id)}',
              ),
              variant: SnButtonVariant.deep,
            ),
          // Nothing booked yet: offer to schedule. Once the backend holds a time, the interview
          // details lead and the same transition is only a reschedule.
          if (canMove && at == null)
            action('booking_schedule_btn', l10n.bookingSchedule, onSchedule),
          if (inInterviewStage)
            action(
              'booking_interview_btn',
              l10n.bookingViewInterview,
              onViewInterview,
            ),
          if (canMove && at != null)
            action(
              'booking_reschedule_btn',
              l10n.interviewReschedule,
              onSchedule,
            ),
          if (a.contains(BookingAction.viewService))
            action(
              'booking_view_service_btn',
              l10n.bookingViewService,
              () => context.push(
                '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
              ),
              variant: SnButtonVariant.deep,
            ),
          if (a.contains(BookingAction.rate))
            action(
              'booking_rate_btn',
              l10n.bookingRate,
              () => context.push(Routes.path(Routes.rating, {'id': b.id})),
              variant: SnButtonVariant.deep,
            ),
          if (a.contains(BookingAction.rebook))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: HireAgainButton(
                bookingId: b.id,
                variant: SnButtonVariant.deep,
              ),
            ),
          if (a.contains(BookingAction.replace))
            action(
              'booking_replace_btn',
              l10n.bookingReplace,
              () => context.push(
                '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(b.id)}',
              ),
            ),
          ReplacementLinks(booking: b),
          if (a.contains(BookingAction.receipt))
            action('booking_receipt_btn', l10n.bookingReceipt, onReceipt),
          if (a.contains(BookingAction.cancel))
            action(
              'booking_cancel_btn',
              l10n.bookingCancel,
              onCancel,
              variant: SnButtonVariant.text,
            ),
          if (b.previousBookingId != null)
            action(
              'booking_previous_link',
              l10n.bookingPreviousLink,
              () => context.push(
                Routes.path(Routes.bookingDetail, {'id': b.previousBookingId!}),
              ),
              variant: SnButtonVariant.text,
            ),
          action(
            'booking_support_btn',
            l10n.bookingSupport,
            () => context.push(
              '${Routes.supportNew}?bookingId=${Uri.encodeComponent(b.id)}',
            ),
            variant: SnButtonVariant.text,
          ),
        ],
      ),
    );
  }
}
