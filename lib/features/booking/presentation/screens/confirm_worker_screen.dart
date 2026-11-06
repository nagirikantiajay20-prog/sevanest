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
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/domain/booking_quote.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/booking/presentation/widgets/booking_confirm_parts.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/policy_sheet.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show InterviewWorkerCard;
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_request_parts.dart'
    show RequestSection;
import 'package:sevanest_customer/features/payment/presentation/payment_labels.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart'
    show istDate;
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show experienceLabel, ratingText;
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

  /// Set once the backend accepted the worker: the day the booking starts, shown on the ticket.
  DateTime? _confirmedFor;

  DateTime _today() => istDate(ref.read(nowProvider)());

  DateTime _effectiveStart(Booking b) {
    final today = _today();
    final d = _startDate ?? b.startDate;
    return d == null || d.isBefore(today)
        ? today.add(const Duration(days: 1))
        : d;
  }

  DateTime _lastDay() => _today().add(const Duration(days: 365));
  void _step(DateTime from, int days) => setState(() {
    _startDate = from.add(Duration(days: days));
    _error = null;
  });
  Future<void> _pickDate(Booking b) async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveStart(b),
      firstDate: today,
      lastDate: _lastDay(),
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
    final repo = ref.read(bookingRepositoryProvider);
    final start = _effectiveStart(b);
    var gone = false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.confirmWorker(b.id, start);
      _after(b.id);
      // The ticket says what was booked; payment is next, from the booking (Back from there
      // lands on the booking, not here).
      if (mounted) setState(() => _confirmedFor = start);
    } on NotFoundFailure {
      gone = true;
    } on ValidationFailure catch (e) {
      // Worker no longer eligible, or a bad start date.
      if (e.code == 'WORKER_NOT_ELIGIBLE') {
        gone = true;
      } else if (mounted) {
        setState(
          () => _error = isNotServiceable(e)
              ? failureMessage(l10n, e)
              : e.message ?? l10n.confirmDateInvalid,
        );
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
        if (mounted) setState(() => _confirmedFor = start);
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
    final value = ref.watch(bookingProvider(widget.bookingId));
    final fee = ref.watch(bookingFeeProvider(widget.bookingId)).value;
    final quote = bookingQuote(backendFeeMinor: fee);
    final booking = value.value;
    return FindGlassPage(
      title: l10n.confirmTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.bookings),
      body: AsyncValueView<Booking>(
        value: value,
        onRetry: () => ref.invalidate(bookingProvider(widget.bookingId)),
        data: (b) => _content(l10n, b, quote),
      ),
      bottom: _bottomBar(l10n, value, quote),
      overlay: _confirmedFor == null || booking == null
          ? null
          : _success(l10n, booking, quote),
    );
  }

  Widget _bottomBar(
    AppLocalizations l10n,
    AsyncValue<Booking> value,
    BookingQuote? quote,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (quote != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l10n.confirmTotalRow,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dsText,
                  ),
                ),
              ),
              Text(
                minorAmount(quote.totalMinor),
                key: const Key('confirm_total'),
                style: authSerif(26, 1.2),
              ),
            ],
          ),
        ),
      if (quote != null) const SizedBox(height: 8),
      Builder(
        builder: (ctx) => AuthCta(
          key: const Key('confirm_pay_btn'),
          clock: DiscoverClock.of(ctx),
          label: l10n.confirmButton,
          loadingLabel: l10n.confirmButtonBusy,
          loading: _busy,
          breathe: true,
          radius: 18,
          height: 58,
          onPressed: value.hasValue && !_busy
              ? () => _confirm(value.requireValue)
              : null,
        ),
      ),
    ],
  );

  Widget _content(AppLocalizations l10n, Booking b, BookingQuote? quote) {
    final locale = Localizations.localeOf(context).toString();
    final start = _effectiveStart(b);
    final budget = bookingBudgetLabel(l10n, b);
    final worker = b.worker;
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final id = b.identity;
    final name = id?.displayName ?? worker?.title;
    final policy = ref.watch(accountConfigProvider).value?.policy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiscoverRise(
            delayMs: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                header: true,
                child: Text(l10n.confirmHeading, style: authSerif(30, 1.15)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DiscoverRise(
            delayMs: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                l10n.confirmSub,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: dsText,
                ),
              ),
            ),
          ),
          if (name != null && b.workerId != null) ...[
            const SizedBox(height: 16),
            DiscoverRise(
              delayMs: 100,
              child: KeyedSubtree(
                key: const Key('confirm_worker_card'),
                child: InterviewWorkerCard(
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
                  onTap: () => context.push(
                    Routes.path(Routes.workerDetail, {'id': b.workerId!}),
                  ),
                ),
              ),
            ),
          ],
          RequestSection(
            title: l10n.confirmSummary,
            delayMs: 180,
            trailing: TextButton(
              key: const Key('confirm_edit_req_btn'),
              onPressed: () => context.push(Routes.discoverReview),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                minimumSize: const Size(0, 44),
                textStyle: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.confirmEditRequirement),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConfirmRows(
                  rows: [
                    (
                      l10n.bookingServiceRow,
                      [
                        b.categoryName ?? b.categoryCode,
                        if (b.engagement != null)
                          engagementLabels(l10n, b.engagement!).name,
                      ].whereType<String>().join(' · '),
                    ),
                    if (b.areaName != null) (l10n.bookingAreaRow, b.areaName!),
                    if (budget != null) (l10n.bookingBudgetRow, budget),
                  ],
                ),
                const SizedBox(height: 14),
                ConfirmDatePager(
                  label: l10n.confirmStartDate,
                  date: formatDate(start, locale),
                  earlierTip: l10n.confirmEarlier,
                  laterTip: l10n.confirmLater,
                  onEarlier: _busy || !start.isAfter(_today())
                      ? null
                      : () => _step(start, -1),
                  onLater: _busy || !start.isBefore(_lastDay())
                      ? null
                      : () => _step(start, 1),
                  onPick: _busy ? null : () => _pickDate(b),
                ),
              ],
            ),
          ),
          RequestSection(
            title: l10n.confirmPriceDetails,
            delayMs: 260,
            child: ConfirmPrice(
              lines: [
                if (quote != null)
                  (l10n.confirmFeeRow, minorAmount(quote.feeMinor)),
              ],
              totalLabel: l10n.confirmTotalRow,
              total: quote == null ? null : minorAmount(quote.totalMinor),
              note: quote == null
                  ? l10n.confirmFeeNote
                  : l10n.confirmFeeTaxNote,
            ),
          ),
          if (policy != null && !policy.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('confirm_policy_btn'),
                onPressed: () => showPolicySheet(context, ref, policy),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  minimumSize: const Size(0, 44),
                  textStyle: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: Text(l10n.policyLink),
              ),
            ),
          if (_error != null)
            FormErrorBanner(_error!, key: const Key('confirm_error')),
        ],
      ),
    );
  }

  /// "Worker confirmed": the ticket of what was booked and the way on to payment.
  Widget _success(AppLocalizations l10n, Booking b, BookingQuote? quote) {
    final locale = Localizations.localeOf(context).toString();
    final name = b.identity?.displayName ?? b.worker?.title ?? '';
    final date = formatDate(_confirmedFor!, locale);
    return GlassSuccessOverlay(
      title: l10n.confirmDone,
      body: l10n.confirmSuccessBody(name, date),
      rows: [
        (l10n.interviewTkWorker, name),
        (l10n.confirmTkStarts, date),
        if (quote != null)
          (l10n.confirmTkAmount, minorAmount(quote.totalMinor)),
        (l10n.interviewTkStatus, l10n.bookingPayBannerTitle),
      ],
      ctaKey: const Key('confirm_continue_btn'),
      ctaLabel: l10n.confirmContinue,
      onPressed: () => context.pushReplacement(
        Routes.path(Routes.bookingDetail, {'id': b.id}),
      ),
    );
  }
}
