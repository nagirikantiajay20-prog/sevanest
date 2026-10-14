import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/active_service/presentation/providers/service_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// "Report a missing day": `POST /attendance/bookings/{id}/exceptions`. Pops `true` once recorded.
/// The server enforces the rules (own ACTIVE booking, no entry for that day: 409); the form only
/// limits the date to [first]..[today] and the note to 1-500 characters.
class RaiseExceptionSheet extends ConsumerStatefulWidget {
  const RaiseExceptionSheet({
    required this.bookingId,
    required this.first,
    required this.today,
    super.key,
  });
  final String bookingId;
  final DateTime first;
  final DateTime today;

  @override
  ConsumerState<RaiseExceptionSheet> createState() => _State();
}

class _State extends ConsumerState<RaiseExceptionSheet> {
  final _note = TextEditingController();
  final _key = const Uuid().v4();
  DateTime? _date;
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: widget.today,
      firstDate: widget.first.isAfter(widget.today)
          ? widget.today
          : widget.first,
      lastDate: widget.today,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _send() async {
    final date = _date;
    final note = _note.text.trim();
    if (date == null || note.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .raiseException(
            widget.bookingId,
            date: _iso(date),
            note: note,
            idempotencyKey: _key,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ConflictFailure
              ? l10n.exceptionExists
              : failureMessage(l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.exceptionTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.exceptionHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('exception_date_btn'),
              icon: const Icon(Icons.event),
              label: Text(
                _date == null ? l10n.exceptionDate : formatDate(_date!, locale),
              ),
              onPressed: _sending ? null : _pick,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('exception_note_field'),
              controller: _note,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.exceptionNote),
            ),
            if (_error != null)
              Text(
                _error!,
                key: const Key('exception_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: AppSpacing.sm),
            SnButton(
              key: const Key('exception_submit_btn'),
              label: l10n.exceptionSubmit,
              isLoading: _sending,
              onPressed: _date == null || _note.text.trim().isEmpty
                  ? null
                  : _send,
            ),
          ],
        ),
      ),
    );
  }
}
