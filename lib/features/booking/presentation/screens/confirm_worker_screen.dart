import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/domain/booking_quote.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/policy_sheet.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/bookings/confirm?interviewId=` (module 08, screen 8.1). Confirming the worker moves the
/// booking to PENDING_PAYMENT; the booking fee comes from `GET /fees/booking`; without it the note says it shows
/// at the payment step.
class ConfirmWorkerScreen extends ConsumerStatefulWidget {
  const ConfirmWorkerScreen({required this.bookingId, super.key});
  final String bookingId;

  @override
  ConsumerState<ConfirmWorkerScreen> createState() => _State();
}

class _State extends ConsumerState<ConfirmWorkerScreen> {
  DateTime? _startDate;
  bool _busy = false;
  String? _error;

  DateTime _today() {
    final n = ref.read(nowProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _effectiveStart(Booking b) {
    final today = _today();
    final d = _startDate ?? b.startDate;
    return d == null || d.isBefore(today)
        ? today.add(const Duration(days: 1))
        : d;
  }

  Future<void> _pickDate(Booking b) async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveStart(b),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _error = null;
      });
    }
  }

  void _after(String id) {
    ref
      ..invalidate(bookingProvider(id))
      ..invalidate(bookingListProvider)
      ..invalidate(interviewProvider(id))
      ..invalidate(interviewListProvider)
      ..invalidate(homeProvider);
  }

  Future<void> _confirm(Booking b) async {
    if (_busy) return; // double tap confirms once
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final repo = ref.read(bookingRepositoryProvider);
    var gone = false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.confirmWorker(b.id, _effectiveStart(b));
      _after(b.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.confirmDone)));
      // Payment is next, from the booking (Back from there lands on the booking, not here).
      if (mounted) {
        unawaited(
          router.pushReplacement(
            Routes.path(Routes.bookingDetail, {'id': b.id}),
          ),
        );
      }
    } on NotFoundFailure {
      gone = true;
    } on ValidationFailure catch (e) {
      // Worker no longer eligible, or a bad start date.
      if (e.code == 'WORKER_NOT_ELIGIBLE') {
        gone = true;
      } else if (mounted) {
        setState(() => _error = e.message ?? l10n.confirmDateInvalid);
      }
    } on ConflictFailure {
      // Not a state this can be confirmed from any more: show what the server holds now.
      _after(b.id);
      if (mounted) setState(() => _error = l10n.confirmNotAllowed);
    } on Object catch (e) {
      // The confirmation may have gone through with the answer lost: look before failing.
      final now = await _reread(b.id);
      if (now?.status == BookingStatus.pendingPayment) {
        _after(b.id);
        if (mounted) {
          unawaited(
            router.pushReplacement(
              Routes.path(Routes.bookingDetail, {'id': b.id}),
            ),
          );
        }
      } else if (mounted) {
        setState(() => _error = failureMessage(l10n, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (gone && mounted) await _workerGone();
  }

  Future<Booking?> _reread(String id) async {
    try {
      return await ref.read(bookingRepositoryProvider).get(id);
    } on Object {
      return null;
    }
  }

  Future<void> _workerGone() async {
    final l10n = AppLocalizations.of(context);
    final find = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workerUnavailableTitle),
        content: Text(l10n.workerUnavailableBody),
        actions: [
          TextButton(
            key: const Key('confirm_find_another_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.workerFindAnother),
          ),
        ],
      ),
    );
    if ((find ?? false) && mounted) context.go(Routes.workers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final value = ref.watch(bookingProvider(widget.bookingId));
    final fee = ref.watch(bookingFeeProvider(widget.bookingId)).value;
    final quote = bookingQuote(backendFeeMinor: fee);
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.confirmTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.bookings),
          ),
          Expanded(child: _content(l10n, text, locale, value, quote)),
          _bottomBar(l10n, value, quote),
        ],
      ),
    );
  }

  Widget _bottomBar(
    AppLocalizations l10n,
    AsyncValue<Booking> value,
    BookingQuote quote,
  ) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      boxShadow: AppShadows.floating,
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.confirmTotalRow, style: AppText.body),
                ),
                Text(
                  minorAmount(quote.totalMinor),
                  key: const Key('confirm_total'),
                  style: AppText.title,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('confirm_pay_btn'),
              label: l10n.confirmButton,
              loadingLabel: l10n.confirmButtonBusy,
              isLoading: _busy,
              variant: SnButtonVariant.deep,
              onPressed: value.hasValue && !_busy
                  ? () => _confirm(value.requireValue)
                  : null,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content(
    AppLocalizations l10n,
    TextTheme text,
    String locale,
    AsyncValue<Booking> value,
    BookingQuote quote,
  ) {
    return AsyncValueView<Booking>(
      value: value,
      onRetry: () => ref.invalidate(bookingProvider(widget.bookingId)),
      data: (b) {
        final start = _effectiveStart(b);
        final budget = bookingBudgetLabel(l10n, b);
        Widget row(String label, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 110, child: Text(label, style: AppText.meta)),
              Expanded(child: Text(v, style: AppText.bodyLarge)),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.confirmHeading, style: AppText.title),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.confirmSub, style: AppText.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              if (b.worker != null)
                WorkerCard(
                  key: const Key('confirm_worker_card'),
                  worker: b.worker!,
                  onTap: () => context.push(
                    Routes.path(Routes.workerDetail, {'id': b.worker!.id}),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.confirmSummary,
                            style: AppText.heading,
                          ),
                        ),
                        TextButton(
                          key: const Key('confirm_edit_req_btn'),
                          onPressed: () => context.push(Routes.discoverReview),
                          child: Text(l10n.confirmEditRequirement),
                        ),
                      ],
                    ),
                    row(
                      l10n.bookingServiceRow,
                      [
                        b.categoryName ?? b.categoryCode,
                        if (b.engagement != null)
                          engagementLabels(l10n, b.engagement!).name,
                      ].whereType<String>().join(' · '),
                    ),
                    if (b.areaName != null)
                      row(l10n.bookingAreaRow, b.areaName!),
                    if (budget != null) row(l10n.bookingBudgetRow, budget),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.confirmStartDate, style: AppText.label),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      key: const Key('confirm_start_date_btn'),
                      onPressed: _busy ? null : () => _pickDate(b),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(formatDate(start, locale)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.confirmPriceDetails, style: AppText.heading),
                    const SizedBox(height: AppSpacing.sm),
                    row(l10n.confirmFeeRow, minorAmount(quote.feeMinor)),
                    if (quote.taxMinor != null)
                      row(l10n.confirmTaxRow, minorAmount(quote.taxMinor!)),
                    if (quote.isEstimate)
                      Text(
                        l10n.confirmFeeNote,
                        key: const Key('confirm_fee_note'),
                        style: AppText.meta,
                      ),
                  ],
                ),
              ),
              if (ref.watch(accountConfigProvider).value?.policy
                  case final policy? when !policy.isEmpty)
                TextButton(
                  key: const Key('confirm_policy_btn'),
                  onPressed: () => showPolicySheet(context, ref, policy),
                  child: Text(l10n.policyLink),
                ),
              if (_error != null)
                FormErrorBanner(_error!, key: const Key('confirm_error')),
            ],
          ),
        );
      },
    );
  }
}
