import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Request succeeded but there is nothing to show (AGENTS §25). Never fake data here.
class SnEmptyState extends StatelessWidget {
  const SnEmptyState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.inbox_outlined,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : SnButton(
              key: actionKey,
              label: actionLabel!,
              onPressed: onAction,
              variant: SnButtonVariant.secondary,
            ),
    );
  }
}

class SnErrorState extends StatelessWidget {
  const SnErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredMessage(
      icon: Icons.error_outline,
      title: l10n.errorTitle,
      message: message,
      action: onRetry == null
          ? null
          : SnButton(
              key: const Key('error_retry_btn'),
              label: l10n.retry,
              onPressed: onRetry,
              variant: SnButtonVariant.secondary,
            ),
    );
  }
}

/// Static placeholder rows shown while loading.
class SnSkeletonList extends StatelessWidget {
  const SnSkeletonList({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const SizedBox(height: 88),
        ),
      ),
    );
  }
}
