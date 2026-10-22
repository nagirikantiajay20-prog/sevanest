import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_labels.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_widgets.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// What the screen shows. Derived only from what the backend sent: the status, the alternatives it
/// lists and the start date of the replacement booking.
enum ReplacementView {
  review,
  finding,
  ready,
  scheduled,
  complete,
  rejected,
  cancelled,
  unknown,
}

/// Table-driven: the same mapper feeds the banner, the timeline and the buttons.
ReplacementView replacementView(
  Replacement r, {
  List<WorkerSummary> alternatives = const [],
  Booking? replacementBooking,
  required DateTime today,
}) => switch (r.status) {
  ReplacementStatus.requested => ReplacementView.review,
  ReplacementStatus.approved =>
    alternatives.isEmpty ? ReplacementView.finding : ReplacementView.ready,
  ReplacementStatus.completed =>
    replacementBooking?.startDate != null &&
            replacementBooking!.startDate!.isAfter(today)
        ? ReplacementView.scheduled
        : ReplacementView.complete,
  ReplacementStatus.rejected => ReplacementView.rejected,
  ReplacementStatus.cancelled => ReplacementView.cancelled,
  ReplacementStatus.unknown => ReplacementView.unknown,
};

/// `/replacements/:id` (module doc 11.2, design screen 26): status, request, progress and the
/// choice of the replacement worker. A customer only requests; staff decide.
class ReplacementStatusScreen extends ConsumerStatefulWidget {
  const ReplacementStatusScreen({required this.replacementId, super.key});
  final String replacementId;

  @override
  ConsumerState<ReplacementStatusScreen> createState() => _State();
}

class _State extends ConsumerState<ReplacementStatusScreen>
    with WidgetsBindingObserver {
  String? _picked;
  var _busy = false;
  var _offline = false;
  String? _error;
  late var _selectKey = const Uuid().v4();
  final _withdrawKey = const Uuid().v4();

  String get _id => widget.replacementId;

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

  /// The decision is made by staff while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  /// Read the request, its alternatives and its booking again (a rejection puts the booking back
  /// to ACTIVE).
  void _reload() {
    final booking = ref.read(replacementProvider(_id)).value?.bookingId;
    ref
      ..invalidate(replacementProvider(_id))
      ..invalidate(replacementAlternativesProvider(_id));
    if (booking != null) {
      ref
        ..invalidate(bookingProvider(booking))
        ..invalidate(openReplacementProvider(booking));
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _offline = false;
      _error = null;
    });
    _reload();
    try {
      await ref.read(replacementProvider(_id).future);
    } on Object {
      // shown by the view
    }
  }

  void _changed(Replacement r) {
    ref
      ..invalidate(replacementProvider(_id))
      ..invalidate(replacementAlternativesProvider(_id))
      ..invalidate(bookingProvider(r.bookingId))
      ..invalidate(bookingListProvider)
      ..invalidate(openReplacementProvider(r.bookingId));
    if (r.replacementBookingId != null) {
      ref.invalidate(bookingProvider(r.replacementBookingId!));
    }
  }

  void _toBooking(String bookingId) =>
      context.go(Routes.path(Routes.bookingDetail, {'id': bookingId}));

  Future<void> _withdraw(Replacement r) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l10n.repWithdrawTitle,
      body: l10n.repWithdrawBody,
      confirmLabel: l10n.repWithdrawYes,
      cancelLabel: l10n.repKeep,
      confirmKey: const Key('replacement_withdraw_confirm_btn'),
      destructive: true,
    );
    if (!ok || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final done = await ref
          .read(replacementRepositoryProvider)
          .cancel(_id, idempotencyKey: _withdrawKey);
      _changed(done);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ConflictFailure ? l10n.repChanged : l10n.repWithdrawFail,
            ),
          ),
        );
      }
      _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSelection(Replacement r) async {
    final worker = _picked;
    if (worker == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l10n.repSelectTitle,
      body: l10n.repSelectBody,
      confirmLabel: l10n.repSelectYes,
      cancelLabel: l10n.repGoBack,
      confirmKey: const Key('replacement_select_confirm_btn'),
    );
    if (ok && mounted) await _select(r, worker);
  }

  Future<void> _select(Replacement r, String worker) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _offline = false;
      _error = null;
    });
    try {
      final done = await ref
          .read(replacementRepositoryProvider)
          .select(_id, worker, idempotencyKey: _selectKey);
      _changed(done);
      if (mounted) setState(() => _picked = null);
    } on ConflictFailure catch (e) {
      // WORKER_UNAVAILABLE: booked meanwhile. INVALID_TRANSITION: the request is no longer APPROVED.
      _lost(
        e.code == 'INVALID_TRANSITION' ? l10n.repChanged : l10n.repSelectGone,
      );
    } on ValidationFailure catch (e) {
      // WORKER_NOT_ELIGIBLE, SAME_WORKER.
      _lost(e.code == 'SAME_WORKER' ? l10n.repSelectSame : l10n.repSelectGone);
    } on NetworkFailure {
      if (mounted) setState(() => _offline = true);
    } on Object {
      // The answer may have been lost: read the request again before saying it failed.
      try {
        final fresh = await ref.read(replacementRepositoryProvider).get(_id);
        if (fresh.status == ReplacementStatus.completed) {
          _changed(fresh);
        } else if (mounted) {
          setState(() => _error = l10n.repSelectFail);
        }
      } on Object {
        if (mounted) setState(() => _error = l10n.repSelectFail);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The chosen worker is gone: show the list the backend has now.
  void _lost(String message) {
    _reload();
    if (!mounted) return;
    setState(() {
      _picked = null;
      _selectKey = const Uuid().v4();
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(replacementProvider(_id));
    // "Alternatives ready" and similar arrive as notifications: read the request again.
    ref.listen(notificationTickProvider, (_, _) => _reload());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.bookings),
        ),
        title: Text(l10n.repStatusTitle),
      ),
      body: value.hasValue
          ? _content(l10n, value.requireValue, stale: value.hasError)
          : value.hasError
          ? _LoadError(onRetry: _refresh)
          : const SnSkeletonList(count: 3),
    );
  }

  Widget _content(AppLocalizations l10n, Replacement r, {required bool stale}) {
    final locale = Localizations.localeOf(context).toString();
    final now = ref.read(nowProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final old = ref.watch(bookingProvider(r.bookingId)).value;
    final fresh = r.replacementBookingId == null
        ? null
        : ref.watch(bookingProvider(r.replacementBookingId!)).value;
    final alts = r.status == ReplacementStatus.approved
        ? ref.watch(replacementAlternativesProvider(_id))
        : null;
    final choices = alts?.value ?? const <WorkerSummary>[];
    final view = replacementView(
      r,
      alternatives: choices,
      replacementBooking: fresh,
      today: today,
    );
    final text = Theme.of(context).textTheme;

    String when(DateTime d) =>
        '${formatDayMonth(d, locale)}, ${formatTime(d.hour * 60 + d.minute)}';

    final start = fresh?.startDate;
    final banner = switch (view) {
      ReplacementView.review => (
        Icons.schedule,
        l10n.repBannerReviewTitle,
        l10n.repBannerReviewBody,
        AppColors.warnBg,
        AppColors.warn,
      ),
      ReplacementView.finding => (
        Icons.hourglass_top,
        l10n.repBannerFindingTitle,
        l10n.repBannerFindingBody,
        AppColors.warnBg,
        AppColors.warn,
      ),
      ReplacementView.ready => (
        Icons.groups_outlined,
        l10n.repBannerReadyTitle(choices.length),
        l10n.repBannerReadyBody,
        AppColors.tealMist,
        AppColors.teal,
      ),
      ReplacementView.scheduled => (
        Icons.check_circle_outline,
        l10n.repBannerScheduledTitle,
        start == null
            ? null
            : l10n.repBannerScheduledBody(formatDate(start, locale)),
        AppColors.successBg,
        AppColors.success,
      ),
      ReplacementView.complete => (
        Icons.check_circle_outline,
        l10n.repBannerCompleteTitle,
        l10n.repBannerCompleteBody,
        AppColors.successBg,
        AppColors.success,
      ),
      ReplacementView.rejected => (
        Icons.cancel_outlined,
        l10n.repBannerRejectedTitle,
        l10n.repBannerRejectedBody,
        AppColors.dangerBg,
        AppColors.danger,
      ),
      ReplacementView.cancelled => (
        Icons.block,
        l10n.repBannerCancelledTitle,
        null,
        AppColors.fieldBg,
        AppColors.slate,
      ),
      ReplacementView.unknown => (
        Icons.info_outline,
        l10n.repBannerUnknownTitle,
        null,
        AppColors.fieldBg,
        AppColors.slate,
      ),
    };

    final steps = _timeline(l10n, r, view, when);
    final engagement = old?.engagement == null
        ? null
        : engagementLabels(l10n, old!.engagement!).name;

    final body = <Widget>[
      if (stale || _offline || (alts?.hasError ?? false))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReplacementNotice(
            key: const Key('replacement_offline_banner'),
            icon: Icons.wifi_off,
            title: l10n.repOfflineBanner,
            trailing: TextButton(
              key: const Key('replacement_offline_retry_btn'),
              onPressed: _busy
                  ? null
                  : _offline && _picked != null
                  ? () => _select(r, _picked!)
                  : _refresh,
              child: Text(l10n.retry),
            ),
          ),
        ),
      ReplacementNotice(
        key: Key('replacement_banner_${view.name}'),
        icon: banner.$1,
        title: banner.$2,
        body: banner.$3,
        color: banner.$4,
        iconColor: banner.$5,
      ),
      const SizedBox(height: AppSpacing.lg),
      Card(
        key: const Key('replacement_request_card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.repRequestNo(r.reference),
                      key: const Key('replacement_request_no'),
                      style: text.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('replacement_copy_btn'),
                    tooltip: l10n.repCopyId,
                    icon: const Icon(
                      Icons.copy_outlined,
                      color: AppColors.teal,
                    ),
                    onPressed: () {
                      unawaited(Clipboard.setData(ClipboardData(text: r.id)));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.repCopied)));
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    [
                      ?(old?.categoryName ?? old?.categoryCode),
                      ?engagement,
                      if (old != null) '#${old.reference}',
                    ].join(' · '),
                    key: const Key('replacement_previous_line'),
                    style: text.bodyMedium,
                  ),
                  if (old != null)
                    SnBadge(
                      key: const Key('replacement_previous_tag'),
                      label: old.status == BookingStatus.replaced
                          ? l10n.repTagPrevious
                          : l10n.repTagCurrent,
                    ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Text(l10n.repRowReason, style: text.bodySmall),
              Text(
                replacementReasonText(l10n, r.reason),
                key: const Key('replacement_reason_value'),
                style: text.titleMedium,
              ),
              if (r.notes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(r.notes!, style: text.bodyMedium),
              ],
              if (r.decisionRemarks != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.repTeamNote, style: text.bodySmall),
                Text(
                  r.decisionRemarks!,
                  key: const Key('replacement_team_note'),
                  style: text.bodyMedium,
                ),
              ],
              if (r.createdAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.repSubmitted(when(r.createdAt!)),
                  key: const Key('replacement_submitted'),
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.repProgress, style: text.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      Card(
        key: const Key('replacement_timeline'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SnTimeline(items: steps),
        ),
      ),
      if (view == ReplacementView.ready) ..._choices(l10n, choices),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            _error!,
            key: const Key('replacement_select_error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (view == ReplacementView.ready ||
          view == ReplacementView.cancelled) ...[
        const SizedBox(height: AppSpacing.md),
        _HelpRow(
          onSupport: () => _support(r),
          onWithdraw: view == ReplacementView.ready && !_busy
              ? () => _withdraw(r)
              : null,
        ),
      ],
    ];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: body,
            ),
          ),
        ),
        _bar(l10n, r, view),
      ],
    );
  }

  void _support(Replacement r) => context.push(
    '${Routes.supportNew}?replacementId=${Uri.encodeComponent(r.id)}',
  );

  List<SnTimelineItem> _timeline(
    AppLocalizations l10n,
    Replacement r,
    ReplacementView view,
    String Function(DateTime) when,
  ) {
    SnTimelineItem item(
      String title,
      SnTimelineState state, {
      DateTime? at,
      String? subtitle,
    }) => SnTimelineItem(
      title: title,
      state: state,
      subtitle: subtitle,
      timestamp: at == null ? null : when(at),
      chip: switch (state) {
        SnTimelineState.done => l10n.repChipDone,
        SnTimelineState.current => l10n.repChipNow,
        SnTimelineState.upcoming => l10n.repChipUpcoming,
        SnTimelineState.failed => l10n.repChipCancelled,
      },
    );
    const done = SnTimelineState.done;
    const now = SnTimelineState.current;
    const next = SnTimelineState.upcoming;
    final received = item(
      l10n.repStepReceived,
      done,
      at: r.at(ReplacementStatus.requested),
    );
    return switch (view) {
      ReplacementView.review => [
        received,
        item(l10n.repStepReview, now),
        item(l10n.repStepReady, next),
        item(l10n.repStepChoose, next),
        item(l10n.repStepStarts, next),
      ],
      ReplacementView.finding => [
        received,
        item(l10n.repStepReview, done, at: r.at(ReplacementStatus.approved)),
        item(l10n.repStepReady, now),
        item(l10n.repStepChoose, next),
        item(l10n.repStepStarts, next),
      ],
      ReplacementView.ready => [
        received,
        item(l10n.repStepReview, done, at: r.at(ReplacementStatus.approved)),
        item(l10n.repStepReady, now),
        item(l10n.repStepChoose, next),
        item(l10n.repStepStarts, next),
      ],
      ReplacementView.scheduled => [
        received,
        item(l10n.repStepReview, done, at: r.at(ReplacementStatus.approved)),
        item(l10n.repStepReady, done),
        item(l10n.repStepChoose, done, at: r.at(ReplacementStatus.completed)),
        item(l10n.repStepStarts, now),
      ],
      ReplacementView.complete => [
        received,
        item(l10n.repStepReview, done, at: r.at(ReplacementStatus.approved)),
        item(l10n.repStepReady, done),
        item(l10n.repStepChoose, done, at: r.at(ReplacementStatus.completed)),
        item(l10n.repStepStarts, done),
      ],
      ReplacementView.rejected => [
        received,
        item(l10n.repStepReview, done),
        item(
          l10n.repStepRejected,
          SnTimelineState.failed,
          at: r.at(ReplacementStatus.rejected),
        ),
      ],
      ReplacementView.cancelled => [
        received,
        item(
          l10n.repStepCancelled,
          SnTimelineState.failed,
          at: r.at(ReplacementStatus.cancelled),
          subtitle: l10n.repStepCancelledSub,
        ),
      ],
      ReplacementView.unknown => [received],
    };
  }

  List<Widget> _choices(AppLocalizations l10n, List<WorkerSummary> workers) {
    final text = Theme.of(context).textTheme;
    return [
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.repChooseTitle, style: text.titleLarge),
      Text(l10n.repChooseSub, style: text.bodyMedium),
      const SizedBox(height: AppSpacing.sm),
      for (final w in workers)
        _Alternative(
          worker: w,
          selected: _picked == w.id,
          enabled: !_busy,
          onSelect: () => setState(() {
            _picked = w.id;
            _selectKey = const Uuid().v4();
            _error = null;
          }),
          onProfile: () =>
              context.push(Routes.path(Routes.workerDetail, {'id': w.id})),
        ),
    ];
  }

  Widget _bar(AppLocalizations l10n, Replacement r, ReplacementView view) {
    SnButton btn(
      String key,
      String label,
      VoidCallback? onTap, {
      SnButtonVariant variant = SnButtonVariant.primary,
      bool loading = false,
    }) => SnButton(
      key: Key(key),
      label: label,
      variant: variant,
      isLoading: loading,
      onPressed: onTap,
    );
    const gap = SizedBox(height: AppSpacing.sm);
    final kids = switch (view) {
      ReplacementView.review || ReplacementView.finding => <Widget>[
        Row(
          children: [
            Expanded(
              child: btn(
                'replacement_support_btn',
                l10n.contactSupport,
                () => _support(r),
                variant: SnButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              key: const Key('replacement_withdraw_btn'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: _busy ? null : () => _withdraw(r),
              child: Text(l10n.repWithdraw),
            ),
          ],
        ),
      ],
      ReplacementView.ready => <Widget>[
        if (_picked == null || _offline)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _offline ? l10n.repOfflineContinue : l10n.repSelectHint,
              key: const Key('replacement_select_hint'),
            ),
          ),
        btn(
          'replacement_select_btn',
          l10n.repConfirm,
          _picked == null || _offline ? null : () => _confirmSelection(r),
          loading: _busy,
        ),
      ],
      ReplacementView.scheduled => <Widget>[
        btn(
          'replacement_view_booking_btn',
          l10n.repViewBooking,
          () => _toBooking(r.replacementBookingId ?? r.bookingId),
          variant: SnButtonVariant.secondary,
        ),
        TextButton(
          key: const Key('replacement_view_old_btn'),
          onPressed: () => context.push(
            Routes.path(Routes.bookingDetail, {'id': r.bookingId}),
          ),
          child: Text(l10n.repViewOld),
        ),
      ],
      ReplacementView.complete => <Widget>[
        btn(
          'replacement_view_booking_btn',
          l10n.repViewBooking,
          () => _toBooking(r.replacementBookingId ?? r.bookingId),
        ),
        TextButton(
          key: const Key('replacement_view_old_btn'),
          onPressed: () => context.push(
            Routes.path(Routes.bookingDetail, {'id': r.bookingId}),
          ),
          child: Text(l10n.repViewOld),
        ),
      ],
      ReplacementView.rejected => <Widget>[
        btn(
          'replacement_again_btn',
          l10n.repRequestAgain,
          () => context.pushReplacement(
            '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(r.bookingId)}',
          ),
        ),
        gap,
        btn(
          'replacement_support_btn',
          l10n.contactSupport,
          () => _support(r),
          variant: SnButtonVariant.secondary,
        ),
        gap,
        btn(
          'replacement_find_worker_btn',
          l10n.repFindWorker,
          () => context.go(Routes.discoverCategory),
          variant: SnButtonVariant.secondary,
        ),
        TextButton(
          key: const Key('replacement_back_booking_btn'),
          onPressed: () => _toBooking(r.bookingId),
          child: Text(l10n.repBackBooking),
        ),
      ],
      ReplacementView.cancelled || ReplacementView.unknown => <Widget>[
        btn(
          'replacement_back_booking_btn',
          l10n.repBackBooking,
          () => _toBooking(r.bookingId),
        ),
      ],
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: kids),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.onSupport, this.onWithdraw});
  final VoidCallback onSupport;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          key: const Key('replacement_help_support_btn'),
          onPressed: onSupport,
          icon: const Icon(Icons.headset_mic_outlined),
          label: Text('${l10n.repNeedHelp} ${l10n.contactSupport}'),
        ),
        if (onWithdraw != null)
          TextButton(
            key: const Key('replacement_withdraw_btn'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: onWithdraw,
            child: Text(l10n.repWithdraw),
          ),
      ],
    );
  }
}

/// One alternative: the shared [WorkerCard], a select mark and a link to the full profile.
class _Alternative extends StatelessWidget {
  const _Alternative({
    required this.worker,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onProfile,
  });
  final WorkerSummary worker;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            WorkerCard(
              key: Key('replacement_alt_${worker.id}'),
              worker: worker,
              onTap: enabled ? onSelect : () {},
              trailing: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.teal : AppColors.slate,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: Key('replacement_alt_profile_${worker.id}'),
                onPressed: onProfile,
                child: Text('${l10n.repViewProfile} ›'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Design "Error": the request could not be read at all.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.dangerBg,
                child: Icon(Icons.error_outline, color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.repLoadErrTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.repLoadErrBody, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              SnButton(
                key: const Key('error_retry_btn'),
                label: l10n.repTryAgain,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
