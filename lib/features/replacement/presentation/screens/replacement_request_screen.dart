import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/replacement/domain/replacement.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_labels.dart';
import 'package:sevanest_customer/features/replacement/presentation/replacement_widgets.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Longest note the form accepts. The Swagger caps `notes` at 2000 (the design says 500, see
/// BACKEND_REQUESTS 37); tests and a future config override this provider.
final replacementNotesMaxProvider = Provider<int>((ref) => 2000);

/// `/replacements/new?bookingId=` (module doc 11.1, design screen 25). Create is one
/// `POST /replacement-requests` with one Idempotency-Key per form content; the server decides
/// eligibility, so 403 / 422 lock the form and 409 opens the request that already exists. A made
/// request opens its status screen.
class ReplacementRequestScreen extends ConsumerStatefulWidget {
  const ReplacementRequestScreen({this.bookingId, super.key});
  final String? bookingId;

  @override
  ConsumerState<ReplacementRequestScreen> createState() => _State();
}

class _State extends ConsumerState<ReplacementRequestScreen> {
  final _notes = TextEditingController();
  ReplacementReason? _reason;
  DateTime? _neededFrom;
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
      _created == null &&
      (_reason != null || _notes.text.trim().isNotEmpty || _neededFrom != null);

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

  Future<void> _pickNeededFrom() async {
    final n = ref.read(nowProvider)();
    final today = DateTime(n.year, n.month, n.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _neededFrom ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      _edited(() => _neededFrom = DateTime(d.year, d.month, d.day));
    }
  }

  String? get _neededFromIso {
    final d = _neededFrom;
    if (d == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showGlassConfirm(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      keepLabel: l10n.keepEditing,
      confirmKey: const Key('replacement_discard_confirm_btn'),
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showGlassConfirm(
      context,
      title: l10n.repConfirmTitle,
      body: l10n.repConfirmBody,
      confirmLabel: l10n.repConfirmYes,
      keepLabel: l10n.repRequestCancel,
      confirmKey: const Key('replacement_confirm_btn'),
    );
    if (ok && mounted) await _send();
  }

  /// The request is made: open its status.
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
            neededFrom: _neededFromIso,
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
          if (isOffline(e)) {
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
    final b = booking?.value;
    final form =
        b != null &&
        !_locked &&
        b.status != BookingStatus.replacementRequested &&
        b.actions.contains(BookingAction.replace);
    return PopScope(
      canPop: !_dirty || _sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: FindGlassPage(
        title: l10n.repRequestTitle,
        backLabel: l10n.back,
        onBack: () => Navigator.of(context).maybePop(),
        overlay: _created == null ? null : _receivedOverlay(l10n, _created!),
        bottom: form && _created == null ? _bottom(l10n) : null,
        body: booking == null
            ? _NotEligible(onSupport: _openSupport)
            : GlassAsyncView<Booking>(
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

  Widget _receivedOverlay(AppLocalizations l10n, Replacement r) => KeyedSubtree(
    key: const Key('replacement_received'),
    child: GlassSuccessOverlay(
      title: l10n.repReceivedTitle,
      body: l10n.repReceivedBody,
      rows: [
        (l10n.repRowRequest, '#${r.reference}'),
        (l10n.repRowReason, replacementReasonText(l10n, r.reason)),
        (l10n.repRowStatus, replacementStatusLabel(l10n, r.status)),
      ],
      ctaKey: const Key('replacement_track_btn'),
      ctaLabel: l10n.repTrack,
      onPressed: () => context.pushReplacement(
        Routes.path(Routes.replacementDetail, {'id': r.id}),
      ),
      secondary: TextButton(
        key: const Key('replacement_back_booking_btn'),
        onPressed: () =>
            context.go(Routes.path(Routes.bookingDetail, {'id': _id})),
        child: Text(l10n.repBackBooking),
      ),
    ),
  );

  Widget _bottom(AppLocalizations l10n) {
    final hint = _reason == null
        ? l10n.repChooseReasonHint
        : _needsNote
        ? l10n.repNoteHint
        : _offline
        ? l10n.repOfflineHint
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_failed || _error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SupportNotice(
              key: const Key('replacement_error_card'),
              icon: Icons.error_outline_rounded,
              iconColor: supportDanger,
              title: l10n.repErrTitle,
              body: _error ?? l10n.repErrBody,
            ),
          ),
        if (hint != null && !_failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              hint,
              key: const Key('replacement_submit_hint'),
              style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
            ),
          ),
        Builder(
          builder: (ctx) => AuthCta(
            key: const Key('replacement_submit_btn'),
            clock: DiscoverClock.of(ctx),
            label: _failed ? l10n.repTryAgain : l10n.repSubmit,
            loadingLabel: l10n.repSubmitting,
            loading: _sending,
            breathe: true,
            showArrow: false,
            radius: 18,
            height: 58,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
        TextButton(
          key: const Key('replacement_cancel_btn'),
          onPressed: _sending ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _form(AppLocalizations l10n, Booking b) {
    final max = ref.watch(replacementNotesMaxProvider);
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_offline)
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
                onPressed: _sending ? null : _send,
                child: Text(l10n.retry),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(l10n.repHeadline, style: authSerif(26, 1.2)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: DiscoverRise(delayMs: 0, child: ReplacementInfo(l10n.repInfo)),
        ),
        SupportSection(delayMs: 60, child: ReplacementWorker(booking: b)),
        SupportSection(
          title: l10n.repWhy,
          delayMs: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in ReplacementReason.values)
                ReasonRadio(
                  key: Key('replacement_reason_${r.name}'),
                  label: replacementReasonLabel(l10n, r),
                  selected: _reason == r,
                  enabled: !_sending,
                  onTap: () => _edited(() => _reason = r),
                ),
              if (_reason == ReplacementReason.safety)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SupportNotice(
                    key: const Key('replacement_safety_card'),
                    icon: Icons.gpp_maybe_outlined,
                    iconColor: supportDanger,
                    tint: supportDangerTint,
                    title: l10n.repSafetyTitle,
                    body: l10n.repSafetyBody,
                    trailing: TextButton.icon(
                      key: const Key('replacement_safety_support_btn'),
                      onPressed: _openSupport,
                      icon: const Icon(Icons.headset_mic_outlined),
                      label: Text(l10n.repSafetyBtn),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SupportSection(
          title: l10n.repNotesTitle,
          hint: _reason == ReplacementReason.other
              ? l10n.hintRequired
              : l10n.hintOptional,
          delayMs: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassNoteField(
                key: const Key('replacement_notes_field'),
                controller: _notes,
                enabled: !_sending,
                maxLength: max,
                hint: l10n.repNotesHint,
                onChanged: (_) => _edited(() {}),
              ),
              if (_reason == ReplacementReason.other && _needsNote)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.repNotesRequired,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: supportDanger,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.repNotesNote,
                style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
              ),
            ],
          ),
        ),
        SupportSection(
          title: l10n.repNeededFrom,
          delayMs: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeededFromField(
                text: _neededFrom == null
                    ? l10n.repNeededFromPick
                    : formatDate(_neededFrom!, locale),
                onPick: _sending ? null : _pickNeededFrom,
                onClear: _neededFrom == null || _sending
                    ? null
                    : () => _edited(() => _neededFrom = null),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.repNeededFromNote,
                style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
              ),
            ],
          ),
        ),
        SupportSection(
          title: l10n.repNextTitle,
          delayMs: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in [
                l10n.repNext1,
                l10n.repNext2,
                l10n.repNext3,
              ].indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.teal,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: AppColors.surface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.repStaysActive)),
                ],
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (booking != null)
          SupportSection(child: ReplacementWorker(booking: booking!)),
        const SizedBox(height: 14),
        SupportNotice(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.orange8A4B06,
          tint: supportWarnTint,
          title: l10n.repNotEligibleTitle,
          body: l10n.repNotEligibleBody,
          trailing: TextButton.icon(
            key: const Key('replacement_support_btn'),
            onPressed: onSupport,
            icon: const Icon(Icons.headset_mic_outlined),
            label: Text(l10n.contactSupport),
          ),
        ),
      ],
    );
  }
}
