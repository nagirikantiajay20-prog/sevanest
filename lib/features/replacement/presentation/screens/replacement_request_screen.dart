import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_labels.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Longest note the form accepts. The Swagger caps `notes` at 2000 (the design says 500, see
/// BACKEND_REQUESTS 37); tests and a future config override this provider.
final replacementNotesMaxProvider = Provider<int>((ref) => 2000);

IconData _reasonIcon(ReplacementReason r) => switch (r) {
  ReplacementReason.notOnTime => Icons.schedule,
  ReplacementReason.frequentAbsences => Icons.event_busy_outlined,
  ReplacementReason.workQuality => Icons.assignment_late_outlined,
  ReplacementReason.behaviour => Icons.feedback_outlined,
  ReplacementReason.scheduleChanged => Icons.edit_calendar_outlined,
  ReplacementReason.workerLeft => Icons.person_off_outlined,
  ReplacementReason.safety => Icons.gpp_maybe_outlined,
  ReplacementReason.other => Icons.more_horiz,
};

/// `/replacements/new?bookingId=` (module doc 11.1, design screen 25). Create is one
/// `POST /replacement-requests` with one Idempotency-Key per form content; the server decides
/// eligibility, so 403 / 422 lock the form and 409 opens the request that already exists.
class ReplacementRequestScreen extends ConsumerStatefulWidget {
  const ReplacementRequestScreen({this.bookingId, super.key});
  final String? bookingId;

  @override
  ConsumerState<ReplacementRequestScreen> createState() => _State();
}

class _State extends ConsumerState<ReplacementRequestScreen> {
  final _notes = TextEditingController();
  ReplacementReason? _reason;
  var _sending = false;
  var _offline = false;
  var _locked = false;
  var _redirecting = false;
  var _failed = false;
  Replacement? _created;
  String? _error;

  /// One key per form content: a retry after a lost answer returns the first request, and a changed
  /// form gets a fresh key (the backend refuses one key with two bodies).
  var _key = const Uuid().v4();

  String get _id => widget.bookingId ?? '';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _created == null && (_reason != null || _notes.text.trim().isNotEmpty);

  bool get _needsNote =>
      _reason == ReplacementReason.other && _notes.text.trim().isEmpty;

  bool get _canSubmit =>
      _reason != null && !_needsNote && !_sending && !_offline;

  void _edited(VoidCallback change) => setState(() {
    change();
    _key = const Uuid().v4();
    _failed = false;
    _error = null;
  });

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await confirmDialog(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      confirmKey: const Key('replacement_discard_confirm_btn'),
    );
    if (discard && mounted) context.pop();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l10n.repConfirmTitle,
      body: l10n.repConfirmBody,
      confirmLabel: l10n.repConfirmYes,
      cancelLabel: l10n.repGoBack,
      confirmKey: const Key('replacement_confirm_btn'),
    );
    if (ok && mounted) await _send();
  }

  void _markCreated(Replacement r) {
    ref
      ..invalidate(bookingProvider(_id))
      ..invalidate(bookingListProvider)
      ..invalidate(openReplacementProvider(_id));
    if (!mounted) return;
    setState(() {
      _created = r;
      _offline = false;
      _failed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).repSent)),
    );
  }

  /// The request that is already open for this booking (409, or after a lost answer).
  Future<Replacement?> _existing() async {
    ref.invalidate(openReplacementProvider(_id));
    try {
      return await ref.read(openReplacementProvider(_id).future);
    } on Object {
      return null;
    }
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
      _failed = false;
      _offline = false;
    });
    try {
      final r = await ref
          .read(replacementRepositoryProvider)
          .create(
            bookingId: _id,
            reason: reason.text,
            notes: _notes.text,
            idempotencyKey: _key,
          );
      _markCreated(r);
    } on ConflictFailure catch (e) {
      if (e.code == 'IDEMPOTENCY_IN_PROGRESS') {
        if (mounted) setState(() => _failed = true);
      } else {
        final open = await _existing();
        if (!mounted) return;
        if (open != null) {
          context.pushReplacement(
            Routes.path(Routes.replacementDetail, {'id': open.id}),
          );
        } else {
          setState(() => _failed = true);
        }
      }
    } on ForbiddenFailure {
      if (mounted) setState(() => _locked = true);
    } on NotFoundFailure {
      if (mounted) setState(() => _locked = true);
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'REPLACEMENT_NOT_ELIGIBLE') {
          _locked = true;
        } else {
          _key = const Uuid().v4();
          _failed = true;
        }
      });
    } on Object catch (e) {
      // The answers stay. The request may still have gone through, so look for it.
      final open = await _existing();
      if (!mounted) return;
      if (open != null && open.bookingId == _id) {
        _markCreated(open);
      } else {
        setState(() {
          if (e is NetworkFailure) {
            _offline = true;
          } else {
            _failed = true;
            _error = e is ServerFailure || e is UnauthorizedFailure
                ? failureMessage(l10n, e)
                : null;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openSupport() => context.push(
    '${Routes.supportNew}?bookingId=${Uri.encodeComponent(_id)}',
  );

  /// A booking that already has an open request goes straight to it.
  void _redirectToOpen() {
    if (_redirecting) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final open = await _existing();
      if (!mounted) return;
      if (open != null) {
        context.pushReplacement(
          Routes.path(Routes.replacementDetail, {'id': open.id}),
        );
      } else {
        setState(() => _locked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final booking = _id.isEmpty ? null : ref.watch(bookingProvider(_id));
    final created = _created;
    return PopScope(
      canPop: !_dirty || _sending,
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
          title: Text(l10n.repRequestTitle),
        ),
        body: created != null
            ? _Received(
                replacement: created,
                onTrack: () => context.pushReplacement(
                  Routes.path(Routes.replacementDetail, {'id': created.id}),
                ),
                onBack: () =>
                    context.go(Routes.path(Routes.bookingDetail, {'id': _id})),
              )
            : booking == null
            ? _NotEligible(onSupport: _openSupport)
            : AsyncValueView<Booking>(
                value: booking,
                onRetry: () => ref.invalidate(bookingProvider(_id)),
                data: (b) {
                  if (b.status == BookingStatus.replacementRequested) {
                    _redirectToOpen();
                    if (!_locked) {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }
                  if (_locked || !b.actions.contains(BookingAction.replace)) {
                    return _NotEligible(booking: b, onSupport: _openSupport);
                  }
                  return _form(l10n, b);
                },
              ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n, Booking b) {
    final text = Theme.of(context).textTheme;
    final max = ref.watch(replacementNotesMaxProvider);
    final hint = _reason == null
        ? l10n.repChooseReasonHint
        : _needsNote
        ? l10n.repNoteHint
        : _offline
        ? l10n.repOfflineHint
        : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_offline)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReplacementNotice(
                    key: const Key('replacement_offline_banner'),
                    icon: Icons.wifi_off,
                    title: l10n.repOfflineBanner,
                    trailing: TextButton(
                      key: const Key('replacement_offline_retry_btn'),
                      onPressed: _sending ? null : _send,
                      child: Text(l10n.retry),
                    ),
                  ),
                ),
              ReplacementBookingCard(booking: b),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.repHeadline,
                style: text.headlineMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.repIntro, style: text.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: l10n.repWhy,
                  style: text.titleMedium,
                  children: [
                    TextSpan(
                      text: '  ${l10n.repRequired}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final r in ReplacementReason.values)
                _ReasonTile(
                  reason: r,
                  selected: _reason == r,
                  enabled: !_sending,
                  onTap: () => _edited(() => _reason = r),
                ),
              if (_reason == ReplacementReason.safety)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: DecoratedBox(
                    key: const Key('replacement_safety_card'),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.gpp_maybe_outlined,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.repSafetyTitle,
                                      style: text.titleMedium,
                                    ),
                                    Text(l10n.repSafetyBody),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SnButton(
                            key: const Key('replacement_safety_support_btn'),
                            label: l10n.repSafetyBtn,
                            variant: SnButtonVariant.secondary,
                            icon: Icons.headset_mic_outlined,
                            onPressed: _openSupport,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: l10n.repMore,
                  style: text.titleMedium,
                  children: [
                    TextSpan(
                      text:
                          '  ${_reason == ReplacementReason.other ? l10n.repRequired : l10n.repOptional}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('replacement_notes_field'),
                controller: _notes,
                enabled: !_sending,
                maxLength: max,
                maxLines: 4,
                onChanged: (_) => _edited(() {}),
                decoration: InputDecoration(
                  hintText: l10n.repNotesHint,
                  errorText: _reason == ReplacementReason.other && _needsNote
                      ? l10n.repNotesRequired
                      : null,
                  helperText: l10n.repNotesNote,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NextSteps(),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l10n.repStaysActive, style: text.bodyMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failed || _error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ReplacementNotice(
                        key: const Key('replacement_error_card'),
                        icon: Icons.error_outline,
                        iconColor: AppColors.danger,
                        color: AppColors.surface,
                        title: l10n.repErrTitle,
                        body: _error ?? l10n.repErrBody,
                      ),
                    ),
                  if (hint != null && !_failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        hint,
                        key: const Key('replacement_submit_hint'),
                        style: text.bodyMedium,
                      ),
                    ),
                  SnButton(
                    key: const Key('replacement_submit_btn'),
                    label: _failed ? l10n.repTryAgain : l10n.repSubmit,
                    isLoading: _sending,
                    loadingLabel: l10n.repSubmitting,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                  TextButton(
                    key: const Key('replacement_cancel_btn'),
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final ReplacementReason reason;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? const Color(0xFFF0FDFA) : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: selected ? AppColors.teal : AppColors.slate,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            key: Key('replacement_reason_${reason.name}'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTapTarget + 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE6F7F4),
                      child: Icon(
                        _reasonIcon(reason),
                        size: 22,
                        color: reason == ReplacementReason.safety
                            ? AppColors.danger
                            : AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        replacementReasonLabel(l10n, reason),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.teal : AppColors.slate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [l10n.repNext1, l10n.repNext2, l10n.repNext3];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFCCEFE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.repNextTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Not eligible (design "Not eligible"): the server said no, or the booking has no `replace` action.
class _NotEligible extends StatelessWidget {
  const _NotEligible({this.booking, required this.onSupport});
  final Booking? booking;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      key: const Key('replacement_not_eligible'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (booking != null) ReplacementBookingCard(booking: booking!),
        const SizedBox(height: AppSpacing.md),
        ReplacementNotice(
          icon: Icons.warning_amber_rounded,
          title: l10n.repNotEligibleTitle,
          body: l10n.repNotEligibleBody,
          trailing: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SnButton(
              key: const Key('replacement_support_btn'),
              label: l10n.contactSupport,
              variant: SnButtonVariant.secondary,
              icon: Icons.headset_mic_outlined,
              onPressed: onSupport,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Request received" (design screen 25): the request is made; Track opens its status.
class _Received extends ConsumerWidget {
  const _Received({
    required this.replacement,
    required this.onTrack,
    required this.onBack,
  });
  final Replacement replacement;
  final VoidCallback onTrack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget row(String k, Widget v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(k, style: text.bodyMedium)),
          Flexible(child: v),
        ],
      ),
    );
    return SafeArea(
      key: const Key('replacement_received'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.repReceivedTitle,
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.repReceivedBody,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            row(
                              l10n.repRowRequest,
                              Text(
                                '#${replacement.reference}',
                                key: const Key('replacement_received_ref'),
                                style: text.titleSmall,
                              ),
                            ),
                            const Divider(height: 1),
                            row(
                              l10n.repRowReason,
                              Text(
                                replacementReasonText(l10n, replacement.reason),
                                textAlign: TextAlign.end,
                                style: text.titleSmall,
                              ),
                            ),
                            const Divider(height: 1),
                            row(
                              l10n.repRowStatus,
                              Align(
                                alignment: Alignment.centerRight,
                                child: SnBadge(
                                  key: const Key('replacement_received_status'),
                                  label: replacementStatusLabel(
                                    l10n,
                                    replacement.status,
                                  ),
                                  tone: replacementStatusTone(
                                    replacement.status,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SnButton(
              key: const Key('replacement_track_btn'),
              label: l10n.repTrack,
              onPressed: onTrack,
            ),
            TextButton(
              key: const Key('replacement_back_booking_btn'),
              onPressed: onBack,
              child: Text(l10n.repBackBooking),
            ),
          ],
        ),
      ),
    );
  }
}
