import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Frosted bottom sheet with hour / minute / AM-PM wheels in 15-minute steps (design: Find a
/// Worker 4, time sheet). Returns minutes since midnight, or null when closed.
Future<int?> showTimePickerSheet(
  BuildContext context, {
  required String title,
  required int initialMinutes,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x730F2340),
  elevation: 0,
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
        diameterRatio: 2.4,
        useMagnifier: true,
        magnification: 1.12,
        selectionOverlay: null,
        onSelectedItemChanged: onChanged,
        children: [
          for (final i in items)
            Center(
              child: Text(
                i,
                style: AppText.body.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: dsNavy,
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
    return DiscoverGlass(
      corners: const BorderRadius.vertical(top: Radius.circular(32)),
      gradient: const LinearGradient(
        begin: Alignment(-0.5, -1),
        end: Alignment(0.5, 1),
        colors: [Color(0xF2FFFFFF), Color(0xD6FFFFFF)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            22 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dsNavy.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        key: const Key('time_sheet_title'),
                        style: authSerif(24, 1.2),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('time_picker_cancel_btn'),
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: dsNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: _itemExtent,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                        const SizedBox(width: 6),
                        _wheel(
                          key: const Key('time_picker_minute'),
                          label: l10n.timeSheetMinute,
                          controller: _minuteCtrl,
                          items: const ['00', '15', '30', '45'],
                          onChanged: (i) => _minute = i,
                        ),
                        const SizedBox(width: 6),
                        _wheel(
                          key: const Key('time_picker_period'),
                          label: l10n.timeSheetPeriod,
                          controller: _periodCtrl,
                          items: const ['AM', 'PM'],
                          onChanged: (i) => _period = i,
                        ),
                      ],
                    ),
                    // Fades the wheels toward the edges, like the design's dimmed rows.
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xE6FFFFFF),
                                Color(0x00FFFFFF),
                                Color(0x00FFFFFF),
                                Color(0xE6FFFFFF),
                              ],
                              stops: [0, 0.32, 0.68, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  key: const Key('time_picker_set_btn'),
                  onPressed: () => Navigator.of(context).pop(_minutes),
                  style: FilledButton.styleFrom(
                    backgroundColor: dsNavy,
                    elevation: 8,
                    shadowColor: dsNavy.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.timeSheetSet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
