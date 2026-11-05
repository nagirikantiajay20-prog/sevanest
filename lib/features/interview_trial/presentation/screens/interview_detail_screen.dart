import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_list_parts.dart'
    show interviewStart;
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// `/interviews/:id` (module 07, screen 7.2). Buttons come only from the backend's
/// `allowedActions`.
class InterviewDetailScreen extends ConsumerStatefulWidget {
  const InterviewDetailScreen({required this.interviewId, super.key});
  final String interviewId;

  @override
  ConsumerState<InterviewDetailScreen> createState() => _State();
}

class _State extends ConsumerState<InterviewDetailScreen> {
  bool _busy = false;

  /// Runs one action once (double taps are ignored), then re-reads the interview so the buttons
  /// follow the new `allowedActions`.
  Future<void> _act(
    Future<Interview> Function(InterviewRepository r) call,
    String doneMessage,
  ) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final updated = await call(ref.read(interviewRepositoryProvider));
      ref
        ..invalidate(interviewProvider(widget.interviewId))
        ..invalidate(interviewListProvider)
        ..invalidate(
          bookingProvider(
            updated.bookingId.isEmpty ? updated.id : updated.bookingId,
          ),
        )
        ..invalidate(bookingListProvider)
        ..invalidate(homeProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(doneMessage)));
      // Keep the screen in step even before the refetch lands.
      ref.read(interviewProvider(updated.id));
    } on Object catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final yes = await showGlassConfirm(
      context,
      title: l10n.interviewCancelTitle,
      body: l10n.interviewCancelBody,
      confirmLabel: l10n.interviewCancelYes,
      keepLabel: l10n.interviewCancelKeep,
      confirmKey: const Key('interview_cancel_confirm_btn'),
      destructive: true,
    );
    if (!yes || !mounted) return;
    await _act((r) => r.cancel(widget.interviewId), l10n.interviewCancelled);
  }

  Future<void> _complete() => _act(
    (r) => r.complete(widget.interviewId),
    AppLocalizations.of(context).interviewStatusCompleted,
  );

  Future<void> _answer({required bool accept}) {
    final l10n = AppLocalizations.of(context);
    return _act(
      (r) => r.answerProposal(widget.interviewId, accept: accept),
      accept ? l10n.interviewProposalAccepted : l10n.interviewProposalRejected,
    );
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    final yes = await showGlassConfirm(
      context,
      title: l10n.interviewDeclineTitle,
      body: l10n.interviewDeclineBody,
      confirmLabel: l10n.interviewDeclineConfirm,
      keepLabel: l10n.cancel,
      confirmKey: const Key('interview_decline_confirm_btn'),
    );
    if (!yes || !mounted) return;
    await _act((r) => r.decline(widget.interviewId), l10n.interviewDeclined);
  }

  /// Opens a pre-filled calendar entry for the interview in the phone's calendar / browser.
  Future<void> _addToCalendar(Interview iv, String workerName) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final start = interviewStart(iv);
    if (start == null) return;
    String stamp(DateTime d) => DateFormat("yyyyMMdd'T'HHmmss").format(d);
    final end = start.add(
      Duration(minutes: const InterviewSlot('00:00').minutes),
    );
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.https('calendar.google.com', '/calendar/render', {
          'action': 'TEMPLATE',
          'text': l10n.interviewCalendarTitle(workerName),
          'dates': '${stamp(start)}/${stamp(end)}',
          if (iv.note != null && iv.note!.isNotEmpty) 'details': iv.note,
        }),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.interviewCalendarFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(interviewProvider(widget.interviewId));
    final iv = value.value;
    final primary = iv == null ? null : _primary(l10n, iv);
    return FindGlassPage(
      title: l10n.interviewDetailTitle,
      backLabel: l10n.back,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      body: AsyncValueView<Interview>(
        value: value,
        onRetry: () => ref.invalidate(interviewProvider(widget.interviewId)),
        data: (iv) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(interviewProvider(widget.interviewId));
            try {
              await ref.read(interviewProvider(widget.interviewId).future);
            } on Object {
              // shown by the view
            }
          },
          child: _Body(
            interview: iv,
            busy: _busy,
            primaryKey: primary?.key,
            onCancel: _cancel,
            onDecline: _decline,
            onComplete: _complete,
            onReschedule: () => _reschedule(iv),
            onAnswer: _answer,
            onCalendar: _addToCalendar,
          ),
        ),
      ),
      bottom: primary == null
          ? null
          : _PrimaryBar(action: primary, busy: _busy),
    );
  }

  /// The one big button of the bottom bar: the decision in front of the customer, or the way
  /// on after the request ended. Everything else sits in the body.
  _Primary? _primary(AppLocalizations l10n, Interview iv) {
    final a = iv.actions;
    final ended =
        iv.status == InterviewStatus.notAFit ||
        iv.status == InterviewStatus.declined ||
        iv.status == InterviewStatus.cancelled;
    if (a.contains(InterviewAction.confirm)) {
      return _Primary(
        const Key('interview_confirm_worker_btn'),
        l10n.interviewConfirmWorker,
        () => context.push(
          '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(iv.bookingId.isEmpty ? iv.id : iv.bookingId)}',
        ),
      );
    }
    if (a.contains(InterviewAction.acceptProposal)) {
      return _Primary(
        const Key('interview_accept_proposal_btn'),
        l10n.interviewAcceptProposal,
        () => _answer(accept: true),
      );
    }
    if (a.contains(InterviewAction.complete)) {
      return _Primary(
        const Key('interview_complete_btn'),
        l10n.interviewComplete,
        _complete,
      );
    }
    if (a.contains(InterviewAction.reschedule)) {
      return _Primary(
        const Key('interview_reschedule_btn'),
        iv.date == null ? l10n.interviewSchedule : l10n.interviewReschedule,
        () => _reschedule(iv),
      );
    }
    if (ended) {
      return _Primary(
        const Key('interview_find_another_btn'),
        l10n.workerFindAnother,
        () => context.go(Routes.workers),
        icon: Icons.search_rounded,
      );
    }
    return null;
  }

  void _reschedule(Interview iv) => context.push(
    '${Routes.interviewNew}?workerId=${Uri.encodeComponent(iv.workerId)}&rescheduleId=${Uri.encodeComponent(iv.id)}',
  );
}

class _Primary {
  const _Primary(this.key, this.label, this.onTap, {this.icon});
  final Key key;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

class _PrimaryBar extends StatelessWidget {
  const _PrimaryBar({required this.action, required this.busy});
  final _Primary action;
  final bool busy;

  @override
  Widget build(BuildContext context) => AuthCta(
    key: action.key,
    clock: DiscoverClock.of(context),
    label: action.label,
    loadingLabel: action.label,
    loading: busy,
    breathe: true,
    icon: action.icon ?? Icons.arrow_forward_rounded,
    radius: 18,
    height: 58,
    onPressed: action.onTap,
  );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.interview,
    required this.busy,
    required this.primaryKey,
    required this.onCancel,
    required this.onDecline,
    required this.onComplete,
    required this.onReschedule,
    required this.onAnswer,
    required this.onCalendar,
  });

  final Interview interview;
  final bool busy;

  /// The bottom bar carries this action; the others are listed in the body.
  final Key? primaryKey;
  final VoidCallback onCancel;
  final VoidCallback onDecline;
  final VoidCallback onComplete;
  final VoidCallback onReschedule;
  final Future<void> Function({required bool accept}) onAnswer;
  final Future<void> Function(Interview, String) onCalendar;

  /// Backend timeline when it sends one; otherwise a template from the status.
  List<TimelineStep> _timeline(
    AppLocalizations l,
    String? when,
    String locale,
  ) {
    String? at(DateTime? d) =>
        d == null ? null : DateFormat('EEE d MMM, h:mm a', locale).format(d);
    if (interview.timeline.isNotEmpty) {
      return [
        for (final e in interview.timeline)
          TimelineStep(e.title, e.state, at(e.at)),
      ];
    }
    final s = interview.status;
    final ended =
        s == InterviewStatus.cancelled || s == InterviewStatus.declined;
    final reached = switch (s) {
      InterviewStatus.requested || InterviewStatus.rescheduleProposed => 0,
      InterviewStatus.scheduled => 1,
      InterviewStatus.completed => 2,
      InterviewStatus.confirmed || InterviewStatus.notAFit => 3,
      _ => 0,
    };
    TimelineState state(int i) => ended && i == reached
        ? TimelineState.failed
        : i < reached
        ? TimelineState.done
        : i == reached
        ? TimelineState.current
        : TimelineState.upcoming;
    return [
      TimelineStep(
        l.interviewTlRequested,
        state(0),
        reached == 0 && !ended ? l.interviewTlWaiting : null,
      ),
      TimelineStep(
        l.interviewTlScheduled,
        state(1),
        reached >= 1 && !ended ? when : null,
      ),
      TimelineStep(
        l.interviewTlCompleted,
        state(2),
        reached == 1 ? l.interviewTlAfter : null,
      ),
      TimelineStep(
        l.interviewTlDecision,
        state(3),
        reached == 2 ? l.interviewTlDecisionHint : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final iv = interview;
    final when = interviewWhen(iv, locale);
    final whenText = when == null
        ? null
        : l10n.interviewWhenValue(when.date, when.time);
    final worker =
        iv.worker ?? ref.watch(workerDetailProvider(iv.workerId)).value;
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final req = iv.requirement;
    final category = ref
        .watch(categoriesProvider)
        .value
        ?.where((c) => c.id == req?.serviceId)
        .firstOrNull;
    final a = iv.actions;
    final s = iv.status;
    final name = worker == null || worker.title.isEmpty
        ? interviewTypeName(l10n, iv.type)
        : worker.title;

    final (head, tone, pct) = switch (s) {
      InterviewStatus.requested || InterviewStatus.rescheduleProposed => (
        l10n.interviewHeadWaiting(name),
        HeroTone.waiting,
        0.12,
      ),
      InterviewStatus.scheduled => (
        l10n.interviewHeadBooked,
        HeroTone.ok,
        0.45,
      ),
      InterviewStatus.completed => (l10n.interviewHeadDone, HeroTone.ok, 0.78),
      InterviewStatus.confirmed => (name, HeroTone.ok, 1.0),
      InterviewStatus.notAFit => (name, HeroTone.waiting, 0.78),
      InterviewStatus.cancelled || InterviewStatus.declined => (
        l10n.interviewHeadCancelled,
        HeroTone.bad,
        0.12,
      ),
      InterviewStatus.unknown => (name, HeroTone.waiting, 0.12),
    };
    final canCalendar =
        interviewStart(iv) != null &&
        (s == InterviewStatus.scheduled || s == InterviewStatus.completed);

    void openWorker() =>
        context.push(Routes.path(Routes.workerDetail, {'id': iv.workerId}));

    final rows = <(String, String)>[
      (l10n.interviewTypeRow, interviewTypeName(l10n, iv.type)),
      if (whenText != null) (l10n.interviewWhenRow, whenText),
      if (req != null)
        (
          l10n.interviewRequirementRow,
          [
            category?.name ?? req.serviceId,
            if (req.engagement != null)
              engagementLabels(l10n, req.engagement!).name,
            req.address?.area,
          ].whereType<String>().join(' · '),
        ),
      if (iv.note != null && iv.note!.isNotEmpty)
        (l10n.interviewNoteLabel, iv.note!),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiscoverRise(
            delayMs: 0,
            child: InterviewHero(
              statusLabel: interviewStatusLabel(l10n, s),
              headline: head,
              copy: interviewStatusCopy(l10n, iv, locale),
              progress: pct,
              tone: tone,
            ),
          ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 80,
            child: KeyedSubtree(
              key: const Key('interview_worker_card'),
              child: worker == null
                  ? _ProfileLink(onTap: openWorker)
                  : InterviewWorkerCard(
                      title: worker.title,
                      initials: worker.initials,
                      photoUrl: worker.photoUrl,
                      gradient: avatarGradientFor(worker.id),
                      verified: worker.verified,
                      rating: worker.hasRating
                          ? ratingText(worker.ratingAverage!, scale)
                          : null,
                      onTap: openWorker,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 160,
            child: InterviewInfoCard(
              rows: rows,
              calendarLabel: canCalendar ? l10n.interviewAddCalendar : null,
              onCalendar: canCalendar ? () => onCalendar(iv, name) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
            child: DiscoverRise(
              delayMs: 220,
              child: Semantics(
                header: true,
                child: Text(l10n.interviewProgress, style: authSerif(22, 1.2)),
              ),
            ),
          ),
          DiscoverRise(
            delayMs: 260,
            child: GlassTimeline(steps: _timeline(l10n, whenText, locale)),
          ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in [
                  (
                    InterviewAction.acceptProposal,
                    const Key('interview_accept_proposal_btn'),
                    l10n.interviewAcceptProposal,
                    () => onAnswer(accept: true),
                  ),
                  (
                    InterviewAction.rejectProposal,
                    const Key('interview_reject_proposal_btn'),
                    l10n.interviewKeepOriginal,
                    () => onAnswer(accept: false),
                  ),
                  (
                    InterviewAction.complete,
                    const Key('interview_complete_btn'),
                    l10n.interviewComplete,
                    onComplete,
                  ),
                  (
                    InterviewAction.reschedule,
                    const Key('interview_reschedule_btn'),
                    iv.date == null
                        ? l10n.interviewSchedule
                        : l10n.interviewReschedule,
                    onReschedule,
                  ),
                  (
                    InterviewAction.decline,
                    const Key('interview_reject_worker_btn'),
                    l10n.interviewDecline,
                    onDecline,
                  ),
                ])
                  if (a.contains(o.$1) && o.$2 != primaryKey) ...[
                    OutlineAction(
                      key: o.$2,
                      label: o.$3,
                      onPressed: busy ? null : o.$4,
                    ),
                    const SizedBox(height: 10),
                  ],
                if (a.contains(InterviewAction.cancel))
                  QuietAction(
                    key: const Key('interview_cancel_btn'),
                    label: l10n.interviewCancel,
                    danger: true,
                    onPressed: busy ? null : onCancel,
                  ),
                QuietAction(
                  key: const Key('interview_support_btn'),
                  label: l10n.interviewSupport,
                  onPressed: () => context.push(
                    '${Routes.supportNew}?bookingId=${Uri.encodeComponent(iv.bookingId.isEmpty ? iv.id : iv.bookingId)}',
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

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InterviewWorkerCard(
    title: AppLocalizations.of(context).workerProfileTitle,
    initials: null,
    photoUrl: null,
    gradient: const [AppColors.slate, AppColors.slate400Light],
    verified: false,
    rating: null,
    onTap: onTap,
  );
}
