import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Renders any [AsyncValue] with consistent loading / empty / error+retry / stale handling (AGENTS §86).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// When true for the loaded data, [empty] is shown instead.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (value.hasValue) {
      final d = value.requireValue;
      if (isEmpty?.call(d) ?? false) {
        return empty ?? SnEmptyState(title: l10n.emptyDefaultTitle);
      }
      final content = data(d);
      // Stale: refresh failed but earlier data exists.
      if (value.hasError && !value.isLoading) {
        return Column(
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(child: Text(l10n.staleBanner)),
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: Text(l10n.retry)),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        );
      }
      return content;
    }

    if (value.hasError) {
      // No connection reads differently from a server problem (global offline state).
      return isOffline(value.error)
          ? SnOfflineState(
              message: failureMessage(l10n, value.error!),
              onRetry: onRetry,
            )
          : SnErrorState(
              message: failureMessage(l10n, value.error!),
              onRetry: onRetry,
            );
    }
    return loading ?? const SnSkeletonList();
  }
}
