import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_calendar.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Select date" bottom sheet used by Hourly (design "Hourly date sheet"). Returns the chosen day,
/// or null when dismissed.
Future<DateTime?> showDateSheet(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTime today,
  DateTime? selected,
}) => showModalBottomSheet<DateTime>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _DateSheet(
    firstDate: firstDate,
    lastDate: lastDate,
    today: today,
    selected: selected,
  ),
);

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.firstDate,
    required this.lastDate,
    required this.today,
    this.selected,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final DateTime? selected;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime? _picked = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dateSheetTitle,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('date_sheet_close'),
                  tooltip: l10n.discoverClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SnCalendar(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              today: widget.today,
              selected: _picked,
              onSelect: (d) => setState(() => _picked = d),
            ),
            const SizedBox(height: AppSpacing.md),
            SnButton(
              key: const Key('date_sheet_set_btn'),
              label: _picked == null
                  ? l10n.dateSheetPick
                  : l10n.dateSheetSet(formatDate(_picked!, locale)),
              onPressed: _picked == null
                  ? null
                  : () => Navigator.of(context).pop(_picked),
            ),
          ],
        ),
      ),
    );
  }
}
