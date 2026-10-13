import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Opens the cancel sheet. [onConfirm] gets the reason text and runs the API call; the sheet
/// closes with `true` only after it succeeds, and shows the failure inline (and stays) otherwise.
Future<bool?> showCancelSheet(
  BuildContext context, {
  required Future<void> Function(String reason) onConfirm,
}) => showSnBottomSheet<bool>(context, builder: (_) => _CancelSheet(onConfirm));

class _CancelSheet extends StatefulWidget {
  const _CancelSheet(this.onConfirm);
  final Future<void> Function(String reason) onConfirm;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  int? _reason;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm(List<String> reasons) async {
    if (_busy || _reason == null) return;
    final l10n = AppLocalizations.of(context);
    final note = _note.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm(
        note.isEmpty ? reasons[_reason!] : '${reasons[_reason!]}: $note',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failureMessage(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = [
      l10n.cancelReasonFound,
      l10n.cancelReasonPlans,
      l10n.cancelReasonMistake,
      l10n.cancelReasonOther,
    ];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cancelSheetTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.cancelSheetReason),
          RadioGroup<int>(
            groupValue: _reason,
            onChanged: (v) {
              if (!_busy) setState(() => _reason = v);
            },
            child: Column(
              children: [
                for (var i = 0; i < reasons.length; i++)
                  RadioListTile<int>(
                    key: Key('cancel_reason_$i'),
                    contentPadding: EdgeInsets.zero,
                    value: i,
                    title: Text(reasons[i]),
                  ),
              ],
            ),
          ),
          TextField(
            key: const Key('cancel_note_field'),
            controller: _note,
            enabled: !_busy,
            maxLength: 300,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.cancelNoteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            FormErrorBanner(_error!, key: const Key('cancel_error')),
          const SizedBox(height: AppSpacing.md),
          SnButton(
            key: const Key('cancel_confirm_btn'),
            label: l10n.cancelConfirm,
            isLoading: _busy,
            onPressed: _reason == null ? null : () => _confirm(reasons),
          ),
          const SizedBox(height: AppSpacing.sm),
          SnButton(
            key: const Key('cancel_dismiss_btn'),
            label: l10n.cancelDismiss,
            variant: SnButtonVariant.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
