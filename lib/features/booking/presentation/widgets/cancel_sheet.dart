import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

const _rose = Color(0xFFBE123C);

/// Opens the cancel sheet. [onConfirm] gets the reason text and runs the API call; the sheet
/// closes with `true` only after it succeeds, and shows the failure inline (and stays) otherwise.
Future<bool?> showCancelSheet(
  BuildContext context, {
  required Future<void> Function(String reason) onConfirm,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x611B3354),
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: _CancelSheet(onConfirm),
  ),
);

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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF7FFFFFF), Color(0xF7FAF8F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, -16),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dsNavy.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(l10n.cancelSheetTitle, style: authSerif(24, 1.15)),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.cancelSheetReason,
              style: AppText.body.copyWith(
                fontSize: 15,
                height: 1.5,
                color: dsText,
              ),
            ),
            for (var i = 0; i < reasons.length; i++)
              _Reason(
                key: Key('cancel_reason_$i'),
                label: reasons[i],
                selected: _reason == i,
                onTap: _busy ? null : () => setState(() => _reason = i),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('cancel_note_field'),
              controller: _note,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.cancelNoteHint,
                filled: true,
                fillColor: const Color(0xCCFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: dsNavy.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error != null)
              FormErrorBanner(_error!, key: const Key('cancel_error')),
            const SizedBox(height: 10),
            SizedBox(
              height: 58,
              child: FilledButton(
                key: const Key('cancel_confirm_btn'),
                onPressed: _reason == null || _busy
                    ? null
                    : () => _confirm(reasons),
                style: FilledButton.styleFrom(
                  backgroundColor: _rose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: AppText.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.cancelConfirm),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextButton(
                key: const Key('cancel_dismiss_btn'),
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: dsMuted,
                  textStyle: AppText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.cancelDismiss),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One reason: a bordered row whose ring fills rose when chosen.
class _Reason extends StatelessWidget {
  const _Reason({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? _rose.withValues(alpha: 0.08)
              : const Color(0xCCFFFFFF),
          border: Border.all(
            color: selected ? _rose : dsNavy.withValues(alpha: 0.16),
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? _rose : const Color(0xFF94A3B8),
                        width: selected ? 6 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dsNavy,
                      ),
                    ),
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
