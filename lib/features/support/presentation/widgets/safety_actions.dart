import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/features/support/domain/support.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/features/support/presentation/support_labels.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// A blocked worker leaves search, the shortlist and matching on the server; read them again so
/// nothing stale stays on screen. Nothing is hidden locally.
void refreshAfterBlock(WidgetRef ref) => ref
  ..invalidate(workerSearchProvider)
  ..invalidate(favouritesListProvider)
  ..invalidate(bookingListProvider);

/// "Report this worker" / "Block this worker" menu (module doc 12 "Report / Block worker").
/// A customer names the worker by `workerId` or by a booking they are a party to.
class SafetyMenuButton extends ConsumerWidget {
  const SafetyMenuButton({
    this.workerId,
    this.bookingId,
    this.onBlocked,
    this.color,
    super.key,
  });
  final String? workerId;
  final String? bookingId;

  /// Runs after the server accepted the block (e.g. leave the worker's profile).
  final VoidCallback? onBlocked;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      key: const Key('safety_menu_btn'),
      tooltip: l10n.safetyMenu,
      icon: Icon(Icons.more_vert, color: color),
      onSelected: (v) {
        if (v == 'report') {
          showReportSheet(context, workerId: workerId, bookingId: bookingId);
        } else {
          blockWorker(
            context,
            ref,
            workerId: workerId,
            bookingId: bookingId,
            onBlocked: onBlocked,
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          key: const Key('report_open_btn'),
          value: 'report',
          child: Text(l10n.safetyReport),
        ),
        PopupMenuItem(
          key: const Key('block_open_btn'),
          value: 'block',
          child: Text(l10n.safetyBlock),
        ),
      ],
    );
  }
}

String _safetyError(AppLocalizations l10n, Object e) => switch (e) {
  NotFoundFailure() => l10n.safetyNotFound,
  ConflictFailure(code: 'IDEMPOTENCY_IN_PROGRESS') => l10n.safetyInProgress,
  _ => plainFailureMessage(l10n, e),
};

/// Confirm, then `POST /safety/blocks`. The outcome is known only from the server's answer.
Future<bool> blockWorker(
  BuildContext context,
  WidgetRef ref, {
  String? workerId,
  String? bookingId,
  VoidCallback? onBlocked,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final yes = await confirmDialog(
    context,
    title: l10n.safetyBlockTitle,
    body: l10n.safetyBlockBody,
    confirmLabel: l10n.safetyBlockYes,
    cancelLabel: l10n.cancel,
    confirmKey: const Key('block_confirm_btn'),
    destructive: true,
  );
  if (!yes) return false;
  try {
    await ref
        .read(safetyRepositoryProvider)
        .block(
          workerId: workerId,
          bookingId: bookingId,
          idempotencyKey: const Uuid().v4(),
        );
  } on Object catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_safetyError(l10n, e))));
    return false;
  }
  refreshAfterBlock(ref);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.safetyBlocked)));
  onBlocked?.call();
  return true;
}

/// The report sheet (design screen 22 "Report sheet open"): reason, details, Submit.
/// Returns true once the server accepted the report.
Future<bool> showReportSheet(
  BuildContext context, {
  String? workerId,
  String? bookingId,
  VoidCallback? onBlocked,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final done = await showSnBottomSheet<bool>(
    context,
    builder: (_) => _ReportSheet(workerId: workerId, bookingId: bookingId),
  );
  if (done != true) return false;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.safetyThanks)));
  return true;
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({this.workerId, this.bookingId});
  final String? workerId;
  final String? bookingId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportState();
}

class _ReportState extends ConsumerState<_ReportSheet> {
  final _note = TextEditingController();
  ReportReason? _reason;
  var _alsoBlock = false;
  var _sending = false;
  String? _error;

  /// A retry of the same content reuses the key (cannot report twice); the server answers 422 to a
  /// key reused with a different body, so changed content gets a new one.
  var _key = const Uuid().v4();
  String? _keyBody;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final l10n = AppLocalizations.of(context);
    final body = '${reason.code}|${_note.text.trim()}|$_alsoBlock';
    if (_keyBody != null && _keyBody != body) _key = const Uuid().v4();
    _keyBody = body;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(
            workerId: widget.workerId,
            bookingId: widget.bookingId,
            reason: reason,
            note: _note.text,
            alsoBlock: _alsoBlock,
            idempotencyKey: _key,
          );
      if (_alsoBlock) refreshAfterBlock(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      // The sheet stays open with what was entered.
      if (mounted) {
        setState(() {
          _sending = false;
          _error = _safetyError(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final max = ref.watch(reportNoteMaxProvider);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.safetyReportTitle,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const Key('report_close_btn'),
                icon: const Icon(Icons.close),
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.safetyReportWhat, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final r in ReportReason.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: _reason == r ? AppColors.tealMist : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(
                    color: _reason == r ? AppColors.teal : AppColors.slate,
                    width: _reason == r ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  key: Key('report_reason_${r.code}'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: _sending ? null : () => setState(() => _reason = r),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: kMinTapTarget),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _reason == r
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _reason == r
                                ? AppColors.teal
                                : AppColors.slate,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              reportReasonLabel(l10n, r),
                              style: text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_reason == ReportReason.safetyConcern)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                l10n.safetyEmergency,
                key: const Key('report_emergency_note'),
                style: text.bodyMedium?.copyWith(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.safetyNote, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('report_note_field'),
            controller: _note,
            enabled: !_sending,
            maxLength: max,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(helperText: l10n.safetyNoteHint),
          ),
          SwitchListTile(
            key: const Key('report_also_block_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.safetyAlsoBlock),
            value: _alsoBlock,
            onChanged: _sending ? null : (v) => setState(() => _alsoBlock = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _error!,
                key: const Key('report_error'),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          SnButton(
            key: const Key('report_submit_btn'),
            label: l10n.safetySubmit,
            isLoading: _sending,
            loadingLabel: l10n.safetySubmitting,
            onPressed: _reason == null || _sending ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          SnButton(
            key: const Key('report_cancel_btn'),
            label: l10n.cancel,
            variant: SnButtonVariant.secondary,
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
