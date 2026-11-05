import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/new_ticket_parts.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// `/support/new?bookingId=|paymentId=|replacementId=|interviewId=` (module doc 12.2, design
/// screen 28). The backend ticket has a category, a description and an optional booking, so a
/// payment, a replacement request or an interview is linked through its booking. NOT built, no
/// backend support: subject, photos, urgent priority (BACKEND_REQUESTS 46).
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({
    this.bookingId,
    this.paymentId,
    this.replacementId,
    this.interviewId,
    this.categoryId,
    this.safety = false,
    super.key,
  });
  final String? bookingId;
  final String? paymentId;
  final String? replacementId;

  /// An interview is a booking in this backend, so its id names the booking.
  final String? interviewId;
  final String? categoryId;

  /// Opened from "Report a safety issue": the safety category starts selected.
  final bool safety;

  @override
  ConsumerState<NewTicketScreen> createState() => _State();
}

class _State extends ConsumerState<NewTicketScreen> {
  final _text = TextEditingController();
  String? _category;
  String? _picked;
  var _unlinked = false;
  var _sending = false;
  var _offline = false;
  var _failed = false;
  String? _error;
  Ticket? _created;

  /// One key per form content: a retry after a lost answer returns the first ticket, and an edit
  /// gets a fresh key.
  var _key = const Uuid().v4();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _dirty => _created == null && _text.text.trim().isNotEmpty;

  /// The booking the ticket will name: picked by hand, or the one the entry point linked.
  String? _bookingId() {
    if (_unlinked) return null;
    if (_picked != null) return _picked;
    final direct = widget.bookingId ?? widget.interviewId;
    if (direct != null && direct.isNotEmpty) return direct;
    final pay = widget.paymentId;
    if (pay != null && pay.isNotEmpty) {
      return ref.watch(paymentProvider(pay)).value?.bookingId;
    }
    final rep = widget.replacementId;
    if (rep != null && rep.isNotEmpty) {
      return ref.watch(replacementProvider(rep)).value?.bookingId;
    }
    return null;
  }

  /// True when an entry point linked something (the chip shows instead of the picker).
  bool get _linkedByRoute => [
    widget.bookingId,
    widget.interviewId,
    widget.paymentId,
    widget.replacementId,
  ].any((e) => e != null && e.isNotEmpty);

  String? _selected(List<SupportCategory> cats) {
    final id = _category ?? widget.categoryId;
    if (id != null && cats.any((c) => c.id == id)) return id;
    if (_category == null && widget.safety) {
      for (final c in cats) {
        if (c.isSafety) return c.id;
      }
    }
    return null;
  }

  int get _min => ref.read(ticketDescriptionMinProvider);

  void _edited(VoidCallback change) => setState(() {
    change();
    _key = const Uuid().v4();
    _failed = false;
    _error = null;
  });

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showGlassConfirm(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      keepLabel: l10n.keepEditing,
      confirmKey: const Key('ticket_discard_confirm_btn'),
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  void _done(Ticket t) {
    ref.invalidate(ticketListProvider);
    if (!mounted) return;
    setState(() {
      _created = t;
      _offline = false;
      _failed = false;
    });
  }

  /// The ticket may exist although the answer was lost: look for it before offering a retry.
  Future<Ticket?> _findLost(String category, DateTime since) async {
    try {
      final page = await ref.read(supportRepositoryProvider).list();
      for (final t in page.items) {
        final at = t.createdAt;
        if (t.category.id == category &&
            t.description.trim() == _text.text.trim() &&
            (at == null ||
                at.isAfter(since.subtract(const Duration(minutes: 1))))) {
          return t;
        }
      }
    } on Object {
      // still unknown
    }
    return null;
  }

  Future<void> _submit(String category, String? booking) async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    final since = DateTime.now();
    setState(() {
      _sending = true;
      _failed = false;
      _offline = false;
      _error = null;
    });
    try {
      final t = await ref
          .read(supportRepositoryProvider)
          .create(
            categoryId: category,
            description: _text.text,
            bookingId: booking,
            idempotencyKey: _key,
          );
      _done(t);
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _key = const Uuid().v4();
        if (e.code == 'SUPPORT_CATEGORY_INVALID') {
          ref.invalidate(supportCategoriesProvider);
          _category = null;
          _error = l10n.tkNewCategoryGone;
        } else {
          _failed = true;
        }
      });
    } on NotFoundFailure {
      if (mounted) {
        setState(() {
          _key = const Uuid().v4();
          _error = l10n.tkNewBookingGone;
        });
      }
    } on Object catch (e) {
      final lost = await _findLost(category, since);
      if (!mounted) return;
      if (lost != null) {
        _done(lost);
      } else {
        setState(() {
          if (e is NetworkFailure) {
            _offline = true;
          } else {
            _failed = true;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickBooking() async {
    final picked = await showGlassSheet<BookingPick>(
      context,
      builder: (_) => BookingPickerSheet(current: _bookingId()),
    );
    if (picked == null || !mounted) return;
    _edited(() {
      _picked = picked.bookingId;
      _unlinked = picked.bookingId == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cats = ref.watch(supportCategoriesProvider);
    final booking = _bookingId();
    final max = ref.watch(ticketDescriptionMaxProvider);
    final len = _text.text.trim().length;
    final category = cats.hasValue ? _selected(cats.requireValue) : null;
    final tooShort = len > 0 && len < _min;
    final valid = category != null && len >= _min && len <= max;
    final linked = booking != null && (_linkedByRoute || _picked != null);
    final dup = booking == null
        ? null
        : ref.watch(openTicketForBookingProvider(booking)).value;
    final selectedCat = cats.hasValue && category != null
        ? cats.requireValue.firstWhere((c) => c.id == category)
        : null;
    final created = _created;
    return PopScope(
      canPop: !_dirty || _sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: FindGlassPage(
        title: l10n.tkNewTitle,
        backLabel: l10n.back,
        onBack: () => Navigator.of(context).maybePop(),
        overlay: created == null ? null : _createdOverlay(l10n, created),
        bottom: created != null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failed || _error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SupportNotice(
                        key: const Key('ticket_error_card'),
                        icon: Icons.error_outline_rounded,
                        iconColor: supportDanger,
                        title: l10n.tkNewErrTitle,
                        body: _error ?? l10n.tkNewErrBody,
                      ),
                    ),
                  Builder(
                    builder: (ctx) => AuthCta(
                      key: const Key('ticket_submit_btn'),
                      clock: DiscoverClock.of(ctx),
                      label: _failed ? l10n.tkNewTryAgain : l10n.tkNewSubmit,
                      loadingLabel: l10n.tkNewSubmitting,
                      loading: _sending,
                      breathe: true,
                      showArrow: false,
                      radius: 18,
                      height: 58,
                      onPressed: valid && !_sending && !_offline
                          ? () => _submit(category, booking)
                          : null,
                    ),
                  ),
                  if (_offline)
                    TextButton(
                      key: const Key('ticket_offline_retry_btn'),
                      onPressed: valid && !_sending
                          ? () => _submit(category, booking)
                          : null,
                      child: Text(l10n.retry),
                    ),
                ],
              ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_offline)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SupportNotice(
                  key: const Key('ticket_offline_banner'),
                  icon: Icons.wifi_off_rounded,
                  iconColor: AppColors.orange8A4B06,
                  tint: supportWarnTint,
                  title: l10n.tkNewOfflineBanner,
                  body: l10n.tkNewHintOffline,
                ),
              ),
            SupportSection(
              title: l10n.tkNewHeading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SupportLabel(l10n.tkNewCategory),
                  _categoryField(l10n, cats, category, selectedCat),
                  const SizedBox(height: 14),
                  SupportLabel(l10n.tkNewRelatedTo),
                  if (linked)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RelatedChip(
                        bookingId: booking,
                        onRemove: () => _edited(() {
                          _picked = null;
                          _unlinked = true;
                        }),
                      ),
                    )
                  else
                    SelectField(
                      key: const Key('ticket_related_picker'),
                      text: null,
                      placeholder: l10n.tkNewRelatedHint,
                      onTap: _sending ? null : _pickBooking,
                    ),
                  if (selectedCat != null && selectedCat.isSafety)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SupportNotice(
                        key: const Key('ticket_safety_card'),
                        icon: Icons.gpp_maybe_outlined,
                        iconColor: supportDanger,
                        tint: supportDangerTint,
                        title: l10n.tkNewSafetyTitle,
                        body: l10n.tkNewSafetyBody,
                      ),
                    ),
                ],
              ),
            ),
            SupportSection(
              title: l10n.tkNewMore,
              delayMs: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SupportLabel(l10n.tkNewDescLabel),
                  DescriptionBox(
                    controller: _text,
                    enabled: !_sending,
                    max: max,
                    min: _min,
                    hint: tooShort ? l10n.tkNewDescribeShort : null,
                    onChanged: () => _edited(() {}),
                  ),
                ],
              ),
            ),
            if (dup != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SupportNotice(
                  key: const Key('ticket_duplicate_notice'),
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.orange8A4B06,
                  tint: supportWarnTint,
                  title: l10n.tkNewDupTitle,
                  body:
                      '#${dup.reference} · ${ticketStatusLabel(l10n, dup.status)}',
                  trailing: TextButton(
                    key: const Key('ticket_duplicate_open_btn'),
                    onPressed: () => context.push(
                      Routes.path(Routes.supportDetail, {'id': dup.id}),
                    ),
                    child: Text(l10n.tkNewDupOpen),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryField(
    AppLocalizations l10n,
    AsyncValue<List<SupportCategory>> cats,
    String? category,
    SupportCategory? selected,
  ) {
    if (cats.hasValue) {
      return SelectField(
        key: const Key('ticket_category_field'),
        text: selected?.name,
        placeholder: l10n.tkNewCategoryHint,
        onTap: _sending
            ? null
            : () async {
                final id = await pickCategory(
                  context,
                  categories: cats.requireValue,
                  current: category,
                );
                if (id != null && mounted) _edited(() => _category = id);
              },
      );
    }
    if (cats.hasError) {
      return Row(
        key: const Key('ticket_categories_error'),
        children: [
          Expanded(
            child: Text(
              l10n.tkNewCategoriesError,
              style: AppText.body.copyWith(fontSize: 14.5, color: dsText),
            ),
          ),
          TextButton(
            key: const Key('error_retry_btn'),
            onPressed: () => ref.invalidate(supportCategoriesProvider),
            child: Text(l10n.retry),
          ),
        ],
      );
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// "Ticket created": View ticket replaces the form, so Back never returns to it.
  Widget _createdOverlay(AppLocalizations l10n, Ticket t) => KeyedSubtree(
    key: const Key('ticket_created'),
    child: GlassSuccessOverlay(
      title: l10n.tkNewCreatedTitle,
      body: l10n.tkNewCreatedBody,
      rows: [
        (l10n.tkdTitle, '#${t.reference}'),
        (l10n.tkNewCategory, t.category.name),
        (l10n.interviewTkStatus, ticketStatusLabel(l10n, t.status)),
      ],
      ctaKey: const Key('ticket_view_btn'),
      ctaLabel: l10n.tkNewView,
      onPressed: () => context.pushReplacement(
        Routes.path(Routes.supportDetail, {'id': t.id}),
      ),
      secondary: TextButton(
        key: const Key('ticket_back_support_btn'),
        onPressed: () => context.pushReplacement(Routes.support),
        child: Text(l10n.tkNewBack),
      ),
    ),
  );
}
