import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_navigation.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/cancel_sheet.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(bookingProvider(widget.bookingId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.bookings),
        ),
        title: Text(l10n.bookingDetailTitle),
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
          child: _Body(booking: b, onCancel: _cancel),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.booking, required this.onCancel});
  final Booking booking;
  final VoidCallback onCancel;

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
      return [
        for (var i = 0; i < booking.timeline.length; i++)
          SnTimelineItem(
            title: bookingStatusLabel(l, booking.timeline[i].status),
            subtitle: booking.timeline[i].note,
            timestamp: booking.timeline[i].at == null
                ? null
                : formatDate(booking.timeline[i].at!, locale),
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
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final a = b.actions;
    final budget = bookingBudgetLabel(l10n, b);
    final at = b.scheduledAt;
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
          SizedBox(width: 110, child: Text(label, style: text.bodySmall)),
          Expanded(child: Text(value, style: text.bodyMedium)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SnBadge(
                key: const Key('booking_status_chip'),
                label: bookingStatusLabel(l10n, b.status),
                tone: bookingStatusTone(b.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            bookingStatusCopy(l10n, b, locale),
            key: const Key('booking_status_copy'),
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (b.worker != null)
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
          row(
            l10n.bookingServiceRow,
            [
              b.categoryName ?? b.categoryCode,
              if (b.engagement != null)
                engagementLabels(l10n, b.engagement!).name,
            ].whereType<String>().join(' · '),
          ),
          if (b.startDate != null)
            row(l10n.bookingScheduleRow, formatDate(b.startDate!, locale)),
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
          const Divider(height: AppSpacing.lg * 2),
          Text(l10n.bookingTimeline, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SnTimeline(items: _timeline(l10n, locale)),
          const SizedBox(height: AppSpacing.md),
          if (a.contains(BookingAction.pay))
            action(
              'booking_pay_btn',
              l10n.bookingPayNow,
              () => context.push(paymentStartPath(b.id)),
              variant: SnButtonVariant.primary,
            ),
          if (a.contains(BookingAction.confirmWorker))
            action(
              'booking_confirm_worker_btn',
              l10n.bookingConfirmWorker,
              () => context.push(
                '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(b.id)}',
              ),
              variant: SnButtonVariant.primary,
            ),
          if (a.contains(BookingAction.schedule) && b.workerId != null)
            action(
              'booking_schedule_btn',
              l10n.bookingSchedule,
              () => context.push(
                '${Routes.interviewNew}?workerId=${Uri.encodeComponent(b.workerId!)}&rescheduleId=${Uri.encodeComponent(b.id)}',
              ),
            ),
          if (inInterviewStage)
            action(
              'booking_interview_btn',
              l10n.bookingViewInterview,
              () => context.push(
                Routes.path(Routes.interviewDetail, {'id': b.id}),
              ),
            ),
          if (a.contains(BookingAction.viewService))
            action(
              'booking_view_service_btn',
              l10n.bookingViewService,
              () => context.push(
                '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(b.id)}',
              ),
              variant: SnButtonVariant.primary,
            ),
          if (a.contains(BookingAction.rate))
            action(
              'booking_rate_btn',
              l10n.bookingRate,
              () => context.push(Routes.path(Routes.rating, {'id': b.id})),
              variant: SnButtonVariant.primary,
            ),
          if (a.contains(BookingAction.replace))
            action(
              'booking_replace_btn',
              l10n.bookingReplace,
              () => context.push(
                '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(b.id)}',
              ),
            ),
          if (a.contains(BookingAction.receipt))
            action(
              'booking_receipt_btn',
              l10n.bookingReceipt,
              // BookingView has no payment id (docs/BACKEND_REQUESTS.md): fall back to the list.
              () => context.push(
                b.paymentId == null
                    ? Routes.transactions
                    : Routes.path(Routes.transactionDetail, {
                        'id': b.paymentId!,
                      }),
              ),
            ),
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
