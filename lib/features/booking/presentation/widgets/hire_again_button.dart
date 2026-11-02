import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Hire again" (`POST /bookings/rebook`): a new booking for the same worker, opened on success.
/// Callers show it only when the booking's `allowedActions` contains `rebook`.
class HireAgainButton extends ConsumerStatefulWidget {
  const HireAgainButton({
    required this.bookingId,
    this.variant = SnButtonVariant.secondary,
    this.compact = false,
    super.key,
  });
  final String bookingId;
  final SnButtonVariant variant;

  /// Small deep-teal pill for the Home "Book again" cards.
  final bool compact;

  @override
  ConsumerState<HireAgainButton> createState() => _State();
}

class _State extends ConsumerState<HireAgainButton> {
  var _busy = false;

  Future<void> _go() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final made = await ref
          .read(bookingRepositoryProvider)
          .rebook(widget.bookingId);
      ref.invalidate(bookingListProvider);
      unawaited(
        router.push(Routes.path(Routes.bookingDetail, {'id': made.id})),
      );
    } on Object catch (e) {
      final code = switch (e) {
        ConflictFailure(:final code) => code,
        ValidationFailure(:final code) => code,
        _ => null,
      };
      final text = switch (code) {
        'REBOOK_NOT_ALLOWED' => l10n.rebookNotAllowed,
        'WORKER_UNAVAILABLE' => l10n.rebookWorkerUnavailable,
        'WORKER_NOT_ELIGIBLE' => l10n.rebookWorkerNotEligible,
        'DUPLICATE_BOOKING' => l10n.rebookDuplicate,
        _ => l10n.rebookFailed,
      };
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).bookingHireAgain;
    if (widget.compact) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          key: Key('hire_again_btn_${widget.bookingId}'),
          onPressed: _busy ? null : _go,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.actionDeepTeal,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(label),
        ),
      );
    }
    return SnButton(
      key: Key('hire_again_btn_${widget.bookingId}'),
      label: label,
      variant: widget.variant,
      isLoading: _busy,
      onPressed: _go,
    );
  }
}
