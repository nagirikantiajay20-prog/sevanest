import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

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
    final yes = await confirmDialog(
      context,
      title: l10n.interviewCancelTitle,
      body: l10n.interviewCancelBody,
      confirmLabel: l10n.interviewCancel,
      cancelLabel: l10n.interviewCancelKeep,
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
    final yes = await confirmDialog(
      context,
      title: l10n.interviewDeclineTitle,
      body: l10n.interviewDeclineBody,
      confirmLabel: l10n.interviewDeclineConfirm,
      cancelLabel: l10n.cancel,
      confirmKey: const Key('interview_decline_confirm_btn'),
    );
    if (!yes || !mounted) return;
    await _act((r) => r.decline(widget.interviewId), l10n.interviewDeclined);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(interviewProvider(widget.interviewId));
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.interviewDetailTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(child: _content(value)),
        ],
      ),
    );
  }

  Widget _content(AsyncValue<Interview> value) {
    return AsyncValueView<Interview>(
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
          onCancel: _cancel,
          onDecline: _decline,
          onComplete: _complete,
          onAnswer: _answer,
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.interview,
    required this.busy,
    required this.onCancel,
    required this.onDecline,
    required this.onComplete,
    required this.onAnswer,
  });

  final Interview interview;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onDecline;
  final VoidCallback onComplete;
  final Future<void> Function({required bool accept}) onAnswer;

  /// Backend timeline when it sends one; otherwise a template from the status.
  List<SnTimelineItem> _timeline(AppLocalizations l) {
    if (interview.timeline.isNotEmpty) {
      return [
        for (final e in interview.timeline)
          SnTimelineItem(
            title: e.title,
            state: switch (e.state) {
              TimelineState.done => SnTimelineState.done,
              TimelineState.current => SnTimelineState.current,
              TimelineState.failed => SnTimelineState.failed,
              TimelineState.upcoming => SnTimelineState.upcoming,
            },
          ),
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
    SnTimelineState at(int i) => ended && i == reached
        ? SnTimelineState.failed
        : i < reached
        ? SnTimelineState.done
        : i == reached
        ? SnTimelineState.current
        : SnTimelineState.upcoming;
    return [
      SnTimelineItem(title: l.interviewTlRequested, state: at(0)),
      SnTimelineItem(title: l.interviewTlScheduled, state: at(1)),
      SnTimelineItem(title: l.interviewTlCompleted, state: at(2)),
      SnTimelineItem(title: l.interviewTlDecision, state: at(3)),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final iv = interview;
    final when = interviewWhen(iv, locale);
    final worker =
        iv.worker ?? ref.watch(workerDetailProvider(iv.workerId)).value;
    final req = iv.requirement;
    final category = ref
        .watch(categoriesProvider)
        .value
        ?.where((c) => c.id == req?.serviceId)
        .firstOrNull;
    final a = iv.actions;
    final ended =
        iv.status == InterviewStatus.notAFit ||
        iv.status == InterviewStatus.declined;

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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SnCard(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SnBadge(
                  key: const Key('interview_status_chip'),
                  label: interviewStatusLabel(l10n, iv.status),
                  tone: interviewStatusTone(iv.status),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  interviewStatusCopy(l10n, iv, locale),
                  key: const Key('interview_status_copy'),
                  style: AppText.card,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (worker != null)
            WorkerCard(
              key: const Key('interview_worker_card'),
              worker: worker,
              onTap: () => context.push(
                Routes.path(Routes.workerDetail, {'id': iv.workerId}),
              ),
            )
          else
            SnCard(
              key: const Key('interview_worker_card'),
              onTap: () => context.push(
                Routes.path(Routes.workerDetail, {'id': iv.workerId}),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: AppSpacing.md),
                  Text(l10n.workerProfileTitle, style: AppText.card),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SnCard(
            child: Column(
              children: [
                row(l10n.interviewTypeRow, interviewTypeName(l10n, iv.type)),
                if (when != null)
                  row(
                    l10n.interviewWhenRow,
                    l10n.interviewWhenValue(when.date, when.time),
                  ),
                if (req != null)
                  row(
                    l10n.interviewRequirementRow,
                    [
                      category?.name ?? req.serviceId,
                      if (req.engagement != null)
                        engagementLabels(l10n, req.engagement!).name,
                      req.address?.area,
                    ].whereType<String>().join(' · '),
                  ),
                if (iv.note != null && iv.note!.isNotEmpty)
                  row(l10n.interviewNoteLabel, iv.note!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.interviewProgress, style: AppText.heading),
          const SizedBox(height: AppSpacing.sm),
          SnCard(child: SnTimeline(items: _timeline(l10n))),
          const SizedBox(height: AppSpacing.md),
          if (a.contains(InterviewAction.confirm))
            SnButton(
              key: const Key('interview_confirm_worker_btn'),
              label: l10n.interviewConfirmWorker,
              variant: SnButtonVariant.deep,
              onPressed: busy
                  ? null
                  : () => context.push(
                      '${Routes.bookingConfirm}?interviewId=${Uri.encodeComponent(iv.bookingId.isEmpty ? iv.id : iv.bookingId)}',
                    ),
            ),
          if (a.contains(InterviewAction.acceptProposal)) ...[
            SnButton(
              key: const Key('interview_accept_proposal_btn'),
              label: l10n.interviewAcceptProposal,
              variant: SnButtonVariant.deep,
              onPressed: busy ? null : () => onAnswer(accept: true),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (a.contains(InterviewAction.rejectProposal)) ...[
            SnButton(
              key: const Key('interview_reject_proposal_btn'),
              label: l10n.interviewKeepOriginal,
              variant: SnButtonVariant.secondary,
              onPressed: busy ? null : () => onAnswer(accept: false),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (a.contains(InterviewAction.complete)) ...[
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('interview_complete_btn'),
              label: l10n.interviewComplete,
              variant: SnButtonVariant.secondary,
              onPressed: busy ? null : onComplete,
            ),
          ],
          if (a.contains(InterviewAction.reschedule)) ...[
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('interview_reschedule_btn'),
              label: iv.date == null
                  ? l10n.interviewSchedule
                  : l10n.interviewReschedule,
              variant: SnButtonVariant.secondary,
              onPressed: busy
                  ? null
                  : () => context.push(
                      '${Routes.interviewNew}?workerId=${Uri.encodeComponent(iv.workerId)}&rescheduleId=${Uri.encodeComponent(iv.id)}',
                    ),
            ),
          ],
          if (a.contains(InterviewAction.decline)) ...[
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('interview_reject_worker_btn'),
              label: l10n.interviewDecline,
              variant: SnButtonVariant.secondary,
              onPressed: busy ? null : onDecline,
            ),
          ],
          if (a.contains(InterviewAction.cancel)) ...[
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('interview_cancel_btn'),
              label: l10n.interviewCancel,
              variant: SnButtonVariant.text,
              onPressed: busy ? null : onCancel,
            ),
          ],
          if (ended) ...[
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('interview_find_another_btn'),
              label: l10n.workerFindAnother,
              onPressed: () => context.go(Routes.workers),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SnButton(
            key: const Key('interview_support_btn'),
            label: l10n.interviewSupport,
            variant: SnButtonVariant.text,
            onPressed: () => context.push(
              '${Routes.supportNew}?bookingId=${Uri.encodeComponent(iv.bookingId.isEmpty ? iv.id : iv.bookingId)}',
            ),
          ),
        ],
      ),
    );
  }
}
