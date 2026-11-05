import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_labels.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_widgets.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
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
    final ok = await showGlassConfirm(
      context,
      title: l10n.repWithdrawTitle,
      body: l10n.repWithdrawBody,
      confirmLabel: l10n.repWithdrawYes,
      keepLabel: l10n.repKeep,
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
    final ok = await showGlassConfirm(
      context,
      title: l10n.repSelectTitle,
      body: l10n.repSelectBody,
      confirmLabel: l10n.repSelectYes,
      keepLabel: l10n.repGoBack,
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
    final r = value.value;
    final ready = r != null && _viewOf(r) == ReplacementView.ready;
    return FindGlassPage(
      title: ready ? l10n.repChooseWorkerTitle : l10n.repStatusTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.bookings),
      bottom: ready ? _bottom(l10n, r) : null,
      body: GlassAsyncView<Replacement>(
        value: value,
        onRetry: _refresh,
        data: (r) => _content(l10n, r, stale: value.hasError),
      ),
    );
  }

  /// What the request looks like now: its status, the alternatives the backend lists and the start
  /// date of the replacement booking.
  ReplacementView _viewOf(Replacement r) {
    final now = ref.read(nowProvider)();
    final fresh = r.replacementBookingId == null
        ? null
        : ref.watch(bookingProvider(r.replacementBookingId!)).value;
    return replacementView(
      r,
      alternatives: r.status == ReplacementStatus.approved
          ? ref.watch(replacementAlternativesProvider(_id)).value ?? const []
          : const [],
      replacementBooking: fresh,
      today: DateTime(now.year, now.month, now.day),
    );
  }

  Widget _content(AppLocalizations l10n, Replacement r, {required bool stale}) {
    final locale = Localizations.localeOf(context).toString();
    final old = ref.watch(bookingProvider(r.bookingId)).value;
    final fresh = r.replacementBookingId == null
        ? null
        : ref.watch(bookingProvider(r.replacementBookingId!)).value;
    final alts = r.status == ReplacementStatus.approved
        ? ref.watch(replacementAlternativesProvider(_id))
        : null;
    final choices = alts?.value ?? const <WorkerSummary>[];
    final view = _viewOf(r);

    String when(DateTime d) =>
        '${formatDayMonth(d, locale)}, ${formatTime(d.hour * 60 + d.minute)}';

    final start = fresh?.startDate;
    final oldName = old == null ? null : bookingWorkerName(old);
    final (title, body, tone) = switch (view) {
      ReplacementView.review => (
        l10n.repBannerReviewTitle,
        l10n.repBannerReviewBody,
        ReplacementTone.review,
      ),
      ReplacementView.finding => (
        l10n.repBannerFindingTitle,
        l10n.repBannerFindingBody,
        ReplacementTone.review,
      ),
      ReplacementView.ready => (
        l10n.repBannerReadyTitle,
        oldName == null
            ? l10n.repBannerReadyBody
            : l10n.repBannerReadyFor(oldName),
        ReplacementTone.good,
      ),
      ReplacementView.scheduled => (
        l10n.repBannerScheduledTitle,
        start == null
            ? null
            : l10n.repBannerScheduledBody(formatDate(start, locale)),
        ReplacementTone.good,
      ),
      ReplacementView.complete => (
        l10n.repBannerCompleteTitle,
        l10n.repBannerCompleteBody,
        ReplacementTone.good,
      ),
      ReplacementView.rejected => (
        l10n.repBannerRejectedTitle,
        l10n.repBannerRejectedBody,
        ReplacementTone.bad,
      ),
      ReplacementView.cancelled => (
        l10n.repBannerCancelledTitle,
        null,
        ReplacementTone.neutral,
      ),
      ReplacementView.unknown => (
        l10n.repBannerUnknownTitle,
        null,
        ReplacementTone.neutral,
      ),
    };

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          if (stale || _offline || (alts?.hasError ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SupportNotice(
                key: const Key('replacement_offline_banner'),
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.orange8A4B06,
                tint: supportWarnTint,
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: DiscoverRise(
              delayMs: 0,
              child: ReplacementBanner(
                key: Key('replacement_banner_${view.name}'),
                label: replacementStatusLabel(l10n, r.status),
                title: title,
                body: body,
                tone: tone,
              ),
            ),
          ),
          if (view == ReplacementView.ready) ..._choices(l10n, choices),
          ...[
            _requestCard(l10n, r, old, when),
            SupportSection(
              title: l10n.repProgress,
              delayMs: 100,
              child: ReplacementProgress(
                key: const Key('replacement_timeline'),
                items: _timeline(l10n, r, view, when),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SupportNotice(
                key: const Key('replacement_select_error'),
                icon: Icons.error_outline_rounded,
                iconColor: supportDanger,
                title: _error!,
              ),
            ),
          ..._actions(l10n, r, view),
        ],
      ),
    );
  }

  /// The request: the worker being replaced, its number, the reason and what the team wrote.
  Widget _requestCard(
    AppLocalizations l10n,
    Replacement r,
    Booking? old,
    String Function(DateTime) when,
  ) {
    final line = AppText.body.copyWith(
      fontSize: 14.5,
      height: 1.45,
      color: dsText,
    );
    return SupportSection(
      key: const Key('replacement_request_card'),
      delayMs: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (old != null) ...[
            ReplacementWorker(
              booking: old,
              muted: true,
              tag: old.status == BookingStatus.replaced
                  ? l10n.repTagPrevious
                  : l10n.repTagCurrent,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.repRequestNo(r.reference),
                  key: const Key('replacement_request_no'),
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dsNavy,
                  ),
                ),
              ),
              IconButton(
                key: const Key('replacement_copy_btn'),
                tooltip: l10n.repCopyId,
                icon: const Icon(Icons.copy_outlined, color: AppColors.teal),
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
            spacing: 4,
            children: [
              Text(
                '${l10n.repRowReason}:',
                style: line.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                replacementReasonText(l10n, r.reason),
                key: const Key('replacement_reason_value'),
                style: line,
              ),
            ],
          ),
          if (r.notes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(r.notes!, style: line),
            ),
          if (r.decisionRemarks != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.repTeamNote,
              style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
            ),
            Text(
              r.decisionRemarks!,
              key: const Key('replacement_team_note'),
              style: line,
            ),
          ],
          if (r.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.repSubmitted(when(r.createdAt!)),
                key: const Key('replacement_submitted'),
                style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
              ),
            ),
        ],
      ),
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
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: Text(
          l10n.repChooseSub,
          style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
        ),
      ),
      for (final w in workers)
        AlternativePick(
          worker: w,
          scale: scale,
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

  /// Buttons under the content, by what the request is now.
  List<Widget> _actions(
    AppLocalizations l10n,
    Replacement r,
    ReplacementView view,
  ) {
    ReplacementAction act(
      String key,
      String label,
      VoidCallback? onTap, {
      bool danger = false,
    }) => ReplacementAction(
      key: Key(key),
      label: label,
      danger: danger,
      onPressed: onTap,
    );
    final support = act(
      view == ReplacementView.ready || view == ReplacementView.cancelled
          ? 'replacement_help_support_btn'
          : 'replacement_support_btn',
      l10n.contactSupport,
      () => _support(r),
    );
    final withdraw = act(
      'replacement_withdraw_btn',
      l10n.repWithdraw,
      _busy ? null : () => _withdraw(r),
      danger: true,
    );
    final back = act(
      'replacement_back_booking_btn',
      l10n.repBackBooking,
      () => _toBooking(r.bookingId),
    );
    return switch (view) {
      ReplacementView.review ||
      ReplacementView.finding ||
      ReplacementView.ready => [support, withdraw],
      ReplacementView.scheduled || ReplacementView.complete => [
        act(
          'replacement_view_booking_btn',
          l10n.repViewBooking,
          () => _toBooking(r.replacementBookingId ?? r.bookingId),
        ),
        act(
          'replacement_view_old_btn',
          l10n.repViewOld,
          () => context.push(
            Routes.path(Routes.bookingDetail, {'id': r.bookingId}),
          ),
        ),
      ],
      ReplacementView.rejected => [
        act(
          'replacement_again_btn',
          l10n.repRequestAgain,
          () => context.pushReplacement(
            '${Routes.replacementNew}?bookingId=${Uri.encodeComponent(r.bookingId)}',
          ),
        ),
        support,
        act(
          'replacement_find_worker_btn',
          l10n.repFindWorker,
          () => context.go(Routes.discoverCategory),
        ),
        back,
      ],
      ReplacementView.cancelled || ReplacementView.unknown => [support, back],
    };
  }

  /// Confirm bar of the "Choose a worker" view.
  Widget _bottom(AppLocalizations l10n, Replacement r) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_picked == null || _offline)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _offline ? l10n.repOfflineContinue : l10n.repSelectHint,
            key: const Key('replacement_select_hint'),
            style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
          ),
        ),
      Builder(
        builder: (ctx) => AuthCta(
          key: const Key('replacement_select_btn'),
          clock: DiscoverClock.of(ctx),
          label: l10n.repConfirm,
          loadingLabel: l10n.repConfirm,
          loading: _busy,
          breathe: true,
          showArrow: false,
          radius: 18,
          height: 58,
          onPressed: _picked == null || _offline
              ? null
              : () => _confirmSelection(r),
        ),
      ),
    ],
  );
}
