import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_badge.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
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
    final discard = await confirmDialog(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      confirmKey: const Key('ticket_discard_confirm_btn'),
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
    final picked = await showSnBottomSheet<_Pick>(
      context,
      builder: (_) => _BookingPicker(current: _bookingId()),
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
    final created = _created;
    return PopScope(
      canPop: !_dirty || _sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasCool,
        body: Column(
          children: [
            SnHeader(
              title: l10n.tkNewTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: created != null ? _Created(ticket: created) : _form(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final text = Theme.of(context).textTheme;
    final cats = ref.watch(supportCategoriesProvider);
    final booking = _bookingId();
    final max = ref.watch(ticketDescriptionMaxProvider);
    final len = _text.text.trim().length;
    final category = cats.hasValue ? _selected(cats.requireValue) : null;
    final tooShort = len > 0 && len < _min;
    final valid = category != null && len >= _min && len <= max;
    final dup = booking == null
        ? null
        : ref.watch(openTicketForBookingProvider(booking)).value;
    final selectedCat = cats.hasValue && category != null
        ? cats.requireValue.firstWhere((c) => c.id == category)
        : null;
    final hint = _offline
        ? l10n.tkNewHintOffline
        : category == null
        ? l10n.tkNewHintCategory
        : len == 0
        ? l10n.tkNewHintDescribe
        : tooShort
        ? l10n.tkNewHintMore
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
                  child: _Notice(
                    key: const Key('ticket_offline_banner'),
                    icon: Icons.wifi_off,
                    color: AppColors.warnBg,
                    iconColor: AppColors.warn,
                    title: l10n.tkNewOfflineBanner,
                  ),
                ),
              if (booking != null && (_linkedByRoute || _picked != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AttachedChip(
                    bookingId: booking,
                    onRemove: () => _edited(() {
                      _picked = null;
                      _unlinked = true;
                    }),
                  ),
                ),
              Text.rich(
                TextSpan(
                  text: l10n.tkNewAbout,
                  style: text.titleMedium,
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (cats.hasValue)
                for (final c in cats.requireValue)
                  _CategoryTile(
                    category: c,
                    selected: c.id == category,
                    enabled: !_sending,
                    onTap: () => _edited(() => _category = c.id),
                  )
              else if (cats.hasError)
                Row(
                  key: const Key('ticket_categories_error'),
                  children: [
                    Expanded(child: Text(l10n.tkNewCategoriesError)),
                    TextButton(
                      key: const Key('error_retry_btn'),
                      onPressed: () =>
                          ref.invalidate(supportCategoriesProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!(booking != null &&
                  (_linkedByRoute || _picked != null))) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.tkNewRelated, style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  key: const Key('ticket_related_picker'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: _sending ? null : _pickBooking,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.keyboard_arrow_down),
                      helperText: l10n.tkNewRelatedHelp,
                    ),
                    child: Text(
                      l10n.tkNewRelatedHint,
                      style: text.bodyLarge?.copyWith(color: AppColors.slate),
                    ),
                  ),
                ),
              ],
              if (selectedCat != null && selectedCat.isSafety)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _Notice(
                    key: const Key('ticket_safety_card'),
                    icon: Icons.gpp_maybe_outlined,
                    color: AppColors.dangerBg,
                    iconColor: AppColors.danger,
                    title: l10n.tkNewSafetyTitle,
                    body: l10n.tkNewSafetyBody,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: l10n.tkNewDescribe,
                  style: text.titleMedium,
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('ticket_description_field'),
                controller: _text,
                enabled: !_sending,
                maxLength: max,
                minLines: 5,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _edited(() {}),
                decoration: InputDecoration(
                  hintText: l10n.tkNewDescribeHint,
                  errorText: tooShort ? l10n.tkNewDescribeShort : null,
                  helperText: l10n.tkNewPrivacy,
                  prefixIcon: null,
                ),
              ),
              if (dup != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _Notice(
                    key: const Key('ticket_duplicate_notice'),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warnBg,
                    iconColor: AppColors.warn,
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20, color: AppColors.teal),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l10n.tkNewNotified, style: text.bodyMedium),
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
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failed || _error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _Notice(
                        key: const Key('ticket_error_card'),
                        icon: Icons.error_outline,
                        color: AppColors.surface,
                        iconColor: AppColors.danger,
                        title: l10n.tkNewErrTitle,
                        body: _error ?? l10n.tkNewErrBody,
                      ),
                    ),
                  if (hint != null && !_failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        hint,
                        key: const Key('ticket_submit_hint'),
                        style: text.bodyMedium,
                      ),
                    ),
                  SnButton(
                    key: const Key('ticket_submit_btn'),
                    label: _failed ? l10n.tkNewTryAgain : l10n.tkNewSubmit,
                    isLoading: _sending,
                    loadingLabel: l10n.tkNewSubmitting,
                    onPressed: valid && !_sending && !_offline
                        ? () => _submit(category, booking)
                        : null,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _Pick {
  const _Pick(this.bookingId);
  final String? bookingId;
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.title,
    this.body,
    this.trailing,
    super.key,
  });
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String? body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  if (body != null) Text(body!, style: text.bodyMedium),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachedChip extends ConsumerWidget {
  const _AttachedChip({required this.bookingId, required this.onRemove});
  final String bookingId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final b = ref.watch(bookingProvider(bookingId)).value;
    final ref6 = b?.reference ?? _shortRef(bookingId);
    return DecoratedBox(
      key: const Key('ticket_related_chip'),
      decoration: BoxDecoration(
        color: AppColors.tealMist,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.tealLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: AppColors.teal),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.tkNewAttached(ref6))),
            TextButton(
              key: const Key('ticket_related_remove_btn'),
              onPressed: onRemove,
              child: Text(l10n.tkNewRemove),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortRef(String id) =>
    (id.length > 6 ? id.substring(id.length - 6) : id).toUpperCase();

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final SupportCategory category;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AppColors.tealMist : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: selected ? AppColors.teal : AppColors.slate,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            key: Key('ticket_category_${category.id}'),
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
                      backgroundColor: category.isSafety
                          ? AppColors.dangerBg
                          : AppColors.tealSoft,
                      child: Icon(
                        supportCategoryIcon(category),
                        size: 22,
                        color: category.isSafety
                            ? AppColors.danger
                            : AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        category.name,
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

/// The booking picker sheet (design "Booking picker sheet"): recent bookings and "None".
class _BookingPicker extends ConsumerWidget {
  const _BookingPicker({required this.current});
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final list = ref.watch(bookingListProvider);
    final items = list.value?.items ?? const <Booking>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.tkNewPickerTitle, style: text.titleLarge),
            ),
            IconButton(
              key: const Key('ticket_picker_close_btn'),
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Text(l10n.tkNewPickerSub, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (list.isLoading && items.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    plainOrEmpty(l10n, list.error, l10n.tkNewPickerEmpty),
                    key: const Key('ticket_picker_empty'),
                  ),
                ),
              for (final b in items)
                _PickRow(
                  key: Key('ticket_booking_option_${b.id}'),
                  title:
                      '#${b.reference} · ${b.categoryName ?? b.categoryCode ?? ''}',
                  subtitle: bookingStatusLabel(l10n, b.status),
                  selected: current == b.id,
                  onTap: () => Navigator.of(context).pop(_Pick(b.id)),
                ),
              _PickRow(
                key: const Key('ticket_booking_none'),
                title: l10n.tkNewPickerNone,
                selected: current == null,
                onTap: () => Navigator.of(context).pop(const _Pick(null)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The error text when the list failed, else [empty].
String plainOrEmpty(AppLocalizations l10n, Object? error, String empty) =>
    error == null ? empty : plainFailureMessage(l10n, error);

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.tealMist : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.slate,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? AppColors.teal : AppColors.slate,
          ),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
        ),
      ),
    );
  }
}

/// "Ticket created" (design 28): View ticket replaces the form, so Back never returns to it.
class _Created extends StatelessWidget {
  const _Created({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      key: const Key('ticket_created'),
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
                      backgroundColor: AppColors.successBg,
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.tkNewCreatedTitle,
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.tkNewCreatedBody,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
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
                                    l10n.tkNewRef(ticket.reference),
                                    key: const Key('ticket_created_ref'),
                                    style: text.bodySmall,
                                  ),
                                ),
                                SnBadge(
                                  key: const Key('ticket_created_status'),
                                  label: ticketStatusLabel(l10n, ticket.status),
                                  tone: ticketStatusTone(ticket.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              ticket.title(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Chip(label: Text(ticket.category.name)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SnButton(
              key: const Key('ticket_view_btn'),
              label: l10n.tkNewView,
              onPressed: () => context.pushReplacement(
                Routes.path(Routes.supportDetail, {'id': ticket.id}),
              ),
            ),
            TextButton(
              key: const Key('ticket_back_support_btn'),
              onPressed: () => context.pushReplacement(Routes.support),
              child: Text(l10n.tkNewBack),
            ),
          ],
        ),
      ),
    );
  }
}
