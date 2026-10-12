import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Bottom sheet with hour / minute / AM-PM wheels in 15-minute steps (design "Time picker sheet").
/// Returns minutes since midnight, or null when cancelled.
Future<int?> showTimePickerSheet(
  BuildContext context, {
  required String title,
  required int initialMinutes,
}) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _TimeSheet(title: title, initialMinutes: initialMinutes),
);

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.title, required this.initialMinutes});
  final String title;
  final int initialMinutes;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  static const _itemExtent = 44.0;
  late final int _snapped = ((widget.initialMinutes / 15).round() * 15) % 1440;
  late int _hour = (_snapped ~/ 60) % 12 == 0 ? 11 : (_snapped ~/ 60) % 12 - 1;
  late int _minute = (_snapped % 60) ~/ 15;
  late int _period = _snapped ~/ 60 >= 12 ? 1 : 0;

  late final _hourCtrl = FixedExtentScrollController(initialItem: _hour);
  late final _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  late final _periodCtrl = FixedExtentScrollController(initialItem: _period);

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  int get _minutes => ((_hour + 1) % 12 + _period * 12) * 60 + _minute * 15;

  Widget _wheel({
    required Key key,
    required String label,
    required FixedExtentScrollController controller,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) => Expanded(
    child: Semantics(
      label: label,
      child: CupertinoPicker(
        key: key,
        scrollController: controller,
        itemExtent: _itemExtent,
        selectionOverlay: null,
        onSelectedItemChanged: onChanged,
        children: [
          for (final i in items)
            Center(
              child: Text(
                i,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              key: const Key('time_sheet_title'),
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              l10n.timeSheetSub,
              style: text.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: _itemExtent,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F5),
                      border: Border.all(color: AppColors.teal, width: 1.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  Row(
                    children: [
                      _wheel(
                        key: const Key('time_picker_hour'),
                        label: l10n.timeSheetHour,
                        controller: _hourCtrl,
                        items: [for (var h = 1; h <= 12; h++) '$h'],
                        onChanged: (i) => _hour = i,
                      ),
                      _wheel(
                        key: const Key('time_picker_minute'),
                        label: l10n.timeSheetMinute,
                        controller: _minuteCtrl,
                        items: const ['00', '15', '30', '45'],
                        onChanged: (i) => _minute = i,
                      ),
                      _wheel(
                        key: const Key('time_picker_period'),
                        label: l10n.timeSheetPeriod,
                        controller: _periodCtrl,
                        items: const ['AM', 'PM'],
                        onChanged: (i) => _period = i,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SnButton(
                    key: const Key('time_picker_cancel_btn'),
                    label: l10n.cancel,
                    variant: SnButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SnButton(
                    key: const Key('time_picker_set_btn'),
                    label: l10n.timeSheetSet,
                    onPressed: () => Navigator.of(context).pop(_minutes),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
