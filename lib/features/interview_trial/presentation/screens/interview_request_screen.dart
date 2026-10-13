import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// How far ahead an interview can be booked (assumed; no backend config yet).
const interviewWindowDays = 14;

/// `/interviews/new?workerId=` (module 07, screen 7.1). With [rescheduleId] it moves an existing
/// request instead of creating one.
class InterviewRequestScreen extends ConsumerStatefulWidget {
  const InterviewRequestScreen({
    required this.workerId,
    this.rescheduleId,
    super.key,
  });

  final String workerId;
  final String? rescheduleId;

  @override
  ConsumerState<InterviewRequestScreen> createState() => _State();
}

class _State extends ConsumerState<InterviewRequestScreen> {
  InterviewType _type = InterviewType.interview;
  DateTime? _date;
  String? _slot;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  /// One key per form, reused by every retry, so a lost response can never become two requests.
  final String _key =
      'iv-${DateTime.now().microsecondsSinceEpoch}-${UniqueKey().hashCode}';

  bool get _isReschedule => widget.rescheduleId != null;
  bool get _dirty => _date != null || _slot != null || _note.text.isNotEmpty;
  bool get _canSubmit => _date != null && _slot != null && !_busy;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 1)),
      // Past dates cannot be picked.
      firstDate: today,
      lastDate: today.add(const Duration(days: interviewWindowDays)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _slot = null;
      _error = null;
    });
  }

  DateTime _today() {
    final n = ref.read(nowProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final repo = ref.read(interviewRepositoryProvider);
    final date = _date!;
    final slot = _slot!;
    final startedAt = DateTime.now();
    var gone = false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Interview result;
      if (_isReschedule) {
        result = await repo.reschedule(
          widget.rescheduleId!,
          date,
          slot,
          idempotencyKey: _key,
        );
      } else {
        result = await repo.create(
          InterviewRequest(
            workerId: widget.workerId,
            type: _type,
            date: date,
            slot: slot,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            requirement: ref.read(requirementDraftProvider),
          ),
          idempotencyKey: _key,
        );
      }
      _done(result.id, messenger, router, sent: !_isReschedule, l10n: l10n);
    } on ConflictFailure {
      // Someone else took the time: say so and show what is still free.
      ref.invalidate(
        interviewSlotsProvider((workerId: widget.workerId, date: date)),
      );
      if (mounted) {
        setState(() {
          _slot = null;
          _error = l10n.interviewSlotTaken;
        });
      }
    } on NotFoundFailure {
      gone = true;
    } on Object catch (e) {
      // The request may have gone through even though the answer was lost: look before failing.
      final found = await _createdMeanwhile(date, slot, startedAt);
      if (found != null) {
        _done(found, messenger, router, sent: !_isReschedule, l10n: l10n);
      } else if (mounted) {
        setState(() => _error = failureMessage(l10n, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // After the spinner stops, so the dialog is not shown over a busy button.
    if (gone && mounted) await _workerGone();
  }

  /// Rule 3 (AGENTS): after a network error, re-read the list and go on if our request exists.
  Future<String?> _createdMeanwhile(
    DateTime date,
    String slot,
    DateTime since,
  ) async {
    if (_isReschedule) return null;
    try {
      final page = await ref.read(interviewRepositoryProvider).list();
      return page.items
          .where(
            (i) =>
                i.workerId == widget.workerId &&
                i.date == date &&
                i.slot == slot &&
                i.status == InterviewStatus.requested,
          )
          .firstOrNull
          ?.id;
    } on Object {
      return null;
    }
  }

  void _done(
    String id,
    ScaffoldMessengerState messenger,
    GoRouter router, {
    required bool sent,
    required AppLocalizations l10n,
  }) {
    ref
      ..invalidate(interviewListProvider)
      ..invalidate(interviewProvider(id))
      ..invalidate(homeProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(sent ? l10n.interviewSent : l10n.interviewRescheduled),
        ),
      );
    if (!mounted) return;
    if (sent) {
      // Replace the form so Back cannot resubmit it.
      router.pushReplacement(Routes.path(Routes.interviewDetail, {'id': id}));
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.path(Routes.interviewDetail, {'id': id}));
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
            key: const Key('interview_find_another_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.workerFindAnother),
          ),
        ],
      ),
    );
    if ((find ?? false) && mounted) context.go(Routes.workers);
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await confirmDialog(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      confirmKey: const Key('interview_discard_confirm_btn'),
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final worker = ref.watch(workerDetailProvider(widget.workerId));
    final date = _date;
    final slots = date == null
        ? null
        : ref.watch(
            interviewSlotsProvider((workerId: widget.workerId, date: date)),
          );

    return PopScope(
      canPop: !_dirty || _busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('app_back_btn'),
            tooltip: l10n.back,
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            _isReschedule
                ? l10n.interviewRescheduleTitle
                : l10n.interviewRequestTitle,
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              worker.when(
                data: (w) => Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    key: const Key('interview_worker_mini'),
                    leading: WorkerAvatar(w),
                    title: Text(
                      w.categories.firstOrNull ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(experienceLabel(l10n, w.experienceMonths)),
                    trailing: RatingLabel(w),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => e is NotFoundFailure
                    ? SnEmptyState(
                        title: l10n.workerUnavailableTitle,
                        message: l10n.workerUnavailableBody,
                        actionLabel: l10n.workerFindAnother,
                        actionKey: const Key('interview_find_another_btn'),
                        onAction: () => context.go(Routes.workers),
                      )
                    : SnErrorState(
                        message: failureMessage(l10n, e),
                        onRetry: () => ref.invalidate(
                          workerDetailProvider(widget.workerId),
                        ),
                      ),
              ),
              if (!_isReschedule) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.interviewTypeLabel, style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<InterviewType>(
                  key: const Key('interview_type_segment'),
                  segments: [
                    ButtonSegment(
                      value: InterviewType.interview,
                      label: Text(
                        l10n.interviewTypeInterview,
                        key: const Key('interview_type_interview'),
                      ),
                    ),
                    ButtonSegment(
                      value: InterviewType.trial,
                      label: Text(
                        l10n.interviewTypeTrial,
                        key: const Key('interview_type_trial'),
                      ),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => setState(() => _type = s.first),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.interviewDateLabel, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: const Key('interview_date_btn'),
                onPressed: _busy ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  date == null
                      ? l10n.interviewDateButton
                      : formatDate(date, locale),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.interviewSlotLabel, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (slots == null)
                Text(l10n.interviewPickDateFirst, style: text.bodyMedium)
              else
                slots.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => SnErrorState(
                    message: failureMessage(l10n, e),
                    onRetry: () => ref.invalidate(
                      interviewSlotsProvider((
                        workerId: widget.workerId,
                        date: date!,
                      )),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? Text(
                          l10n.interviewNoSlots,
                          key: const Key('interview_no_slots'),
                        )
                      : Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final s in list)
                              ChoiceChip(
                                key: Key('interview_slot_${s.id}'),
                                label: Text(
                                  formatTimeSpan(s.startMinutes, s.endMinutes),
                                ),
                                selected: _slot == s.id,
                                onSelected: _busy
                                    ? null
                                    : (on) => setState(() {
                                        _slot = on ? s.id : null;
                                        _error = null;
                                      }),
                              ),
                          ],
                        ),
                ),
              if (!_isReschedule) ...[
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('interview_note_field'),
                  controller: _note,
                  enabled: !_busy,
                  maxLength: 300,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.interviewNoteLabel,
                    hintText: l10n.interviewNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                FormErrorBanner(_error!, key: const Key('interview_error')),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SnButton(
              key: const Key('interview_submit_btn'),
              label: _isReschedule
                  ? l10n.interviewSubmitReschedule
                  : l10n.interviewSubmit,
              loadingLabel: l10n.interviewSubmitting,
              isLoading: _busy,
              onPressed: _canSubmit ? _submit : null,
            ),
          ),
        ),
      ),
    );
  }
}
