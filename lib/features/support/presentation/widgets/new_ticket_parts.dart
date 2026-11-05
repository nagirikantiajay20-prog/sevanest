import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/booking_labels.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces of the New ticket screen.

const _fieldLine = AppColors.sky1B3354A20;

/// White 52 px field that looks like the design's `select` and opens a sheet when tapped.
class SelectField extends StatelessWidget {
  const SelectField({
    required this.text,
    required this.placeholder,
    required this.onTap,
    super.key,
  });

  /// The chosen value; null shows [placeholder] in grey.
  final String? text;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _fieldLine, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text ?? placeholder,
                  style: AppText.body.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: text == null ? dsMuted : dsNavy,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: dsNavy),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Multiline description box with the counter row under it.
class DescriptionBox extends StatelessWidget {
  const DescriptionBox({
    required this.controller,
    required this.enabled,
    required this.max,
    required this.min,
    required this.hint,
    required this.onChanged,
    super.key,
  });
  final TextEditingController controller;
  final bool enabled;
  final int max;
  final int min;

  /// Shown on the left of the counter (the "add more detail" nudge).
  final String? hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    OutlineInputBorder line(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('ticket_description_field'),
          controller: controller,
          enabled: enabled,
          maxLength: max,
          minLines: 5,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
          style: AppText.body.copyWith(
            fontSize: 15,
            height: 1.45,
            color: dsNavy,
          ),
          decoration: InputDecoration(
            hintText: l10n.tkNewDescPlaceholder(min),
            hintStyle: AppText.body.copyWith(fontSize: 15, color: dsMuted),
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(12),
            border: line(_fieldLine, 1.5),
            enabledBorder: line(_fieldLine, 1.5),
            disabledBorder: line(_fieldLine, 1.5),
            focusedBorder: line(dsNavy, 2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hint ?? '',
                  key: const Key('ticket_submit_hint'),
                  style: AppText.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rose700,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, _) => Text(
                  '${v.text.length}/$max',
                  style: AppText.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: dsMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Related to" teal chip with a remove (x) button.
class RelatedChip extends ConsumerWidget {
  const RelatedChip({
    required this.bookingId,
    required this.onRemove,
    super.key,
  });
  final String bookingId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final b = ref.watch(bookingProvider(bookingId)).value;
    final short =
        (bookingId.length > 6
                ? bookingId.substring(bookingId.length - 6)
                : bookingId)
            .toUpperCase();
    return Container(
      key: const Key('ticket_related_chip'),
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              l10n.tkdBooking(b?.reference ?? short),
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.teal0B5A53,
              ),
            ),
          ),
          IconButton(
            key: const Key('ticket_related_remove_btn'),
            tooltip: l10n.tkNewRemove,
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.teal0B5A53,
            ),
          ),
        ],
      ),
    );
  }
}

/// A category row in the picker sheet.
Future<String?> pickCategory(
  BuildContext context, {
  required List<SupportCategory> categories,
  required String? current,
}) => showGlassSheet<String>(
  context,
  builder: (ctx) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(AppLocalizations.of(ctx).tkNewCategory, style: authSerif(22, 1.2)),
      const SizedBox(height: 12),
      Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in categories)
              _SheetRow(
                key: Key('ticket_category_${c.id}'),
                title: c.name,
                icon: supportCategoryIcon(c),
                safety: c.isSafety,
                selected: c.id == current,
                onTap: () => Navigator.of(ctx).pop(c.id),
              ),
          ],
        ),
      ),
    ],
  ),
);

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.safety = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool safety;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.tealD6EFEA : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.teal : _fieldLine,
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: safety ? AppColors.rose100 : AppColors.tealD6EFEA,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: safety ? AppColors.rose700 : AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: dsNavy,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: dsMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.teal : dsMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Outcome of the booking picker: a booking, or "None" (bookingId null).
class BookingPick {
  const BookingPick(this.bookingId);
  final String? bookingId;
}

/// The booking picker sheet: recent bookings and "None".
class BookingPickerSheet extends ConsumerWidget {
  const BookingPickerSheet({required this.current, super.key});
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(bookingListProvider);
    final items = list.value?.items ?? const <Booking>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.tkNewPickerTitle, style: authSerif(22, 1.2)),
            ),
            IconButton(
              key: const Key('ticket_picker_close_btn'),
              icon: const Icon(Icons.close_rounded, color: dsNavy),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Text(
          l10n.tkNewPickerSub,
          style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (list.isLoading && items.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    plainOrEmpty(l10n, list.error, l10n.tkNewPickerEmpty),
                    key: const Key('ticket_picker_empty'),
                  ),
                ),
              for (final b in items)
                _SheetRow(
                  key: Key('ticket_booking_option_${b.id}'),
                  title:
                      '#${b.reference} · ${b.categoryName ?? b.categoryCode ?? ''}',
                  subtitle: bookingStatusLabel(l10n, b.status),
                  selected: current == b.id,
                  onTap: () => Navigator.of(context).pop(BookingPick(b.id)),
                ),
              _SheetRow(
                key: const Key('ticket_booking_none'),
                title: l10n.tkNewPickerNone,
                selected: current == null,
                onTap: () => Navigator.of(context).pop(const BookingPick(null)),
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
