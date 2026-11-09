import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/analytics/telemetry.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/interview_trial/domain/interview.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/interview_labels.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_request_parts.dart';
import 'package:sevanest_customer/features/legal/legal_consent.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/features/notifications/presentation/push_prompt.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_profile/presentation/providers/worker_profile_providers.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Interviews can be booked today and the next 13 days (the backend's 14-day horizon).
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

  /// The request that was just created: the "Request sent" card shows until View request.
  String? _sentId;

  /// One key per form, reused by every retry, so a lost response can never become two requests.
  final String _key =
      'iv-${DateTime.now().microsecondsSinceEpoch}-${UniqueKey().hashCode}';

  bool get _isReschedule => widget.rescheduleId != null;
  bool get _dirty =>
      _sentId == null &&
      (_date != null ||
          _slot != null ||
          _note.text != ref.read(requirementNoteProvider));
  bool get _canSubmit =>
      _date != null && _slot != null && !_busy && _check == TimeCheck.ok;

  /// Verdict on the chosen time against now and the worker's free windows from the backend; null
  /// until a date, a time and that day's availability are all known.
  TimeCheck? get _check {
    final date = _date;
    final m = parseSlot(_slot);
    if (date == null || m == null) return null;
    final free = ref
        .read(interviewSlotsProvider((workerId: widget.workerId, date: date)))
        .value;
    if (free == null) return null;
    return checkInterviewTime(
      minutes: m,
      date: date,
      now: ref.read(nowProvider)(),
      slots: free,
    );
  }

  Future<void> _pickTime(List<InterviewSlot> free) async {
    final l10n = AppLocalizations.of(context);
    final now = ref.read(nowProvider)();
    final date = _date!;
    final isToday = DateTime(date.year, date.month, date.day) == _today();
    // Start on the chosen time, else the first free time that is not already past.
    final first = free
        .map((s) => s.startMinutes)
        .where((m) => !isToday || m > now.hour * 60 + now.minute)
        .firstOrNull;
    final start = parseSlot(_slot) ?? first ?? free.first.startMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
      helpText: l10n.interviewSlotLabel,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _slot = slotId(picked.hour * 60 + picked.minute);
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // The note typed on Review carries over to the first request.
    if (!_isReschedule) _note.text = ref.read(requirementNoteProvider);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _pickDate(DateTime d) => setState(() {
    // The chosen time stays: it is re-checked against the new day's availability.
    _date = d;
    _error = null;
  });

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
    if (!_isReschedule && !await ref.read(legalConsentProvider)(context)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Availability is read again right before sending: the list on screen may be old, and a
      // time that was taken meanwhile is reported here instead of being sent and refused.
      final provider = interviewSlotsProvider((
        workerId: widget.workerId,
        date: date,
      ));
      ref.invalidate(provider);
      final fresh = await ref.read(provider.future);
      final verdict = checkInterviewTime(
        minutes: parseSlot(slot)!,
        date: date,
        now: ref.read(nowProvider)(),
        slots: fresh,
      );
      if (verdict != TimeCheck.ok) {
        if (mounted) setState(() => _error = l10n.interviewSlotTaken);
        return;
      }
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
      if (!_isReschedule) telemetry.event(TelemetryEvent.interviewRequest);
      _done(
        result.id,
        messenger,
        router,
        sent: !_isReschedule,
        l10n: l10n,
        bookingId: result.bookingId,
      );
    } on ConflictFailure catch (e) {
      if (e.code == 'DUPLICATE_BOOKING') {
        // Already requested: not a slot problem, so keep the choices and just say so.
        if (mounted) setState(() => _error = l10n.interviewDuplicate);
        return;
      }
      // Someone else took the time: say so and show what is still free.
      ref.invalidate(
        interviewSlotsProvider((workerId: widget.workerId, date: date)),
      );
      // The date, time and note stay; the time now shows as unavailable until another is picked.
      if (mounted) setState(() => _error = l10n.interviewSlotTaken);
    } on NotFoundFailure {
      gone = true;
    } on ValidationFailure catch (e) {
      // A definite refusal, not a lost answer: nothing was created, so keep every choice.
      if (mounted) {
        setState(
          () => _error = e.code == 'WORKER_NOT_ELIGIBLE'
              ? l10n.interviewWorkerNotEligible
              : failureMessage(l10n, e),
        );
      }
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
                (i.workerId.isEmpty || i.workerId == widget.workerId) &&
                i.date == date &&
                i.slot == slot &&
                (i.status == InterviewStatus.requested ||
                    i.status == InterviewStatus.scheduled),
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
    String? bookingId,
  }) {
    // The booking holds the status and time: drop its cached copies too.
    final booking = bookingId == null || bookingId.isEmpty ? id : bookingId;
    ref
      ..invalidate(interviewListProvider)
      ..invalidate(interviewProvider(id))
      ..invalidate(bookingProvider(booking))
      ..invalidate(bookingListProvider)
      ..invalidate(homeProvider);
    if (!mounted) return;
    // A new request is confirmed by the "Request sent" card; View request opens the detail.
    if (sent) {
      setState(() => _sentId = id);
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.interviewRescheduled)));
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.path(Routes.interviewDetail, {'id': id}));
    }
  }

  /// Replaces the form with the detail so Back cannot resubmit it.
  void _viewRequest() {
    final id = _sentId;
    if (id == null) return;
    final router = GoRouter.of(context);
    final push = ref.read(pushControllerProvider);
    router.pushReplacement(Routes.path(Routes.interviewDetail, {'id': id}));
    // The first meaningful action: offer notifications once the detail is on screen (never at
    // launch). The form is gone by then, so the navigator's context is used.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        // The overlay sits below the navigator, so a dialog can find it.
        final c =
            router.routerDelegate.navigatorKey.currentState?.overlay?.context;
        if (c != null && c.mounted) unawaited(askForPushAfterAction(push));
      })
      ..scheduleFrame();
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
    final discard = await showGlassConfirm(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      keepLabel: l10n.keepEditing,
      confirmKey: const Key('interview_discard_confirm_btn'),
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final worker = ref.watch(workerDetailProvider(widget.workerId));
    final date = _date;
    final slots = date == null
        ? null
        : ref.watch(
            interviewSlotsProvider((workerId: widget.workerId, date: date)),
          );
    final kind = interviewTypeName(l10n, _type).toLowerCase();

    return PopScope(
      canPop: !_dirty || _busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: FindGlassPage(
        title: _isReschedule
            ? l10n.interviewRescheduleTitle
            : l10n.interviewRequestTitle,
        backLabel: l10n.back,
        onBack: () => Navigator.of(context).maybePop(),
        body: _form(context, l10n, worker, slots, date),
        bottom: RequestSubmitBar(
          summary: date == null || _slot == null || _check != TimeCheck.ok
              ? null
              : _summary(date, locale),
          hint: date == null
              ? l10n.interviewPickToContinue
              : l10n.interviewNowPickTime,
          label: _isReschedule
              ? l10n.interviewSubmitReschedule
              : l10n.interviewSubmit,
          loadingLabel: l10n.interviewSubmitting,
          loading: _busy,
          onPressed: _canSubmit ? _submit : null,
        ),
        overlay: _sentId == null
            ? null
            : _sentOverlay(
                l10n,
                worker.value?.title ?? '',
                kind,
                _summary(date!, locale),
              ),
      ),
    );
  }

  Widget _sentOverlay(
    AppLocalizations l10n,
    String name,
    String kind,
    String when,
  ) {
    return GlassSuccessOverlay(
      title: l10n.interviewSentTitle,
      body: l10n.interviewSentBody(name, kind, when),
      rows: [
        (l10n.interviewTkWorker, name),
        (l10n.interviewTypeRow, '${kind[0].toUpperCase()}${kind.substring(1)}'),
        (l10n.interviewWhenRow, when),
        (l10n.interviewTkStatus, l10n.interviewTkWaiting),
      ],
      ctaKey: const Key('interview_view_request_btn'),
      ctaLabel: l10n.interviewViewRequest,
      onPressed: _viewRequest,
    );
  }

  /// "Thu, 29 Oct · 10 AM – 11 AM".
  String _summary(DateTime date, String locale) {
    final start = parseSlot(_slot) ?? 0;
    return '${formatDate(date, locale)} · ${formatTimeSpan(start, start + _visitMinutes)}';
  }

  /// Visit length from the loaded availability, for the summary line.
  int _visitMinutes = const InterviewSlot('00:00').minutes;

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<WorkerSummary> worker,
    AsyncValue<List<InterviewSlot>>? slots,
    DateTime? date,
  ) {
    var n = 0;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          worker.when(
            data: (w) => KeyedSubtree(
              key: const Key('interview_worker_mini'),
              child: Consumer(
                builder: (context, ref, _) {
                  final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
                  return RequestWorkerCard(
                    title: w.title,
                    initials: w.initials,
                    photoUrl: w.photoUrl,
                    gradient: avatarGradientFor(w.id),
                    subtitle: [
                      experienceLabel(l10n, w.experienceMonths),
                      ?w.categories.firstOrNull,
                    ].join(' · '),
                    rating: w.hasRating
                        ? ratingText(w.ratingAverage!, scale)
                        : l10n.workerNew,
                  );
                },
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
                    onRetry: () =>
                        ref.invalidate(workerDetailProvider(widget.workerId)),
                  ),
          ),
          if (!_isReschedule)
            RequestSection(
              number: ++n,
              title: l10n.interviewTypeLabel,
              delayMs: 80,
              child: Column(
                children: [
                  TypeOption(
                    key: const Key('interview_type_interview'),
                    title: l10n.interviewTypeInterview,
                    hint: l10n.interviewTypeInterviewHint,
                    selected: _type == InterviewType.interview,
                    onTap: _busy
                        ? null
                        : () => setState(() => _type = InterviewType.interview),
                  ),
                  const SizedBox(height: 10),
                  TypeOption(
                    key: const Key('interview_type_trial'),
                    title: l10n.interviewTypeTrial,
                    hint: l10n.interviewTypeTrialHint,
                    selected: _type == InterviewType.trial,
                    onTap: _busy
                        ? null
                        : () => setState(() => _type = InterviewType.trial),
                  ),
                ],
              ),
            ),
          RequestSection(
            number: ++n,
            title: l10n.interviewDateLabel,
            delayMs: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateStrip(
                  today: _today(),
                  days: interviewWindowDays,
                  selected: date,
                  onSelect: _busy ? null : _pickDate,
                ),
                Text(
                  l10n.interviewDateHorizon(interviewWindowDays),
                  style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
                ),
              ],
            ),
          ),
          RequestSection(
            number: ++n,
            title: l10n.interviewSlotLabel,
            delayMs: 240,
            child: _slots(l10n, slots, date),
          ),
          if (!_isReschedule)
            RequestSection(
              number: ++n,
              title: l10n.interviewNoteTitle,
              delayMs: 320,
              child: RequestNoteField(
                controller: _note,
                enabled: !_busy,
                label: l10n.interviewNoteLabel,
                hint: l10n.interviewNoteHint,
                onChanged: () => setState(() {}),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            FormErrorBanner(_error!, key: const Key('interview_error')),
          ],
        ],
      ),
    );
  }

  Widget _slots(
    AppLocalizations l10n,
    AsyncValue<List<InterviewSlot>>? slots,
    DateTime? date,
  ) {
    if (slots == null) return SlotHint(l10n.interviewPickDateFirst);
    return slots.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => SnErrorState(
        message: failureMessage(l10n, e),
        onRetry: () => ref.invalidate(
          interviewSlotsProvider((workerId: widget.workerId, date: date!)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return SlotHint(
            l10n.interviewNoSlots,
            key: const Key('interview_no_slots'),
          );
        }
        _visitMinutes = list.first.minutes;
        final m = parseSlot(_slot);
        return InterviewTimeField(
          minutes: m,
          visitMinutes: _visitMinutes,
          windows: freeWindows(list),
          check: _check ?? TimeCheck.ok,
          onTap: _busy ? null : () => _pickTime(list),
        );
      },
    );
  }
}
