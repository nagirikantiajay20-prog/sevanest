import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Steps in the requirement builder (design: "Step n of 6"); Review is the end, not a step.
const kDiscoverSteps = 6;

/// Shared chrome for every requirement-builder step: back, title, close (X), progress,
/// scrollable body and the sticky Continue button (modules/04 "Shared chrome").
class DiscoverScaffold extends ConsumerWidget {
  const DiscoverScaffold({
    required this.step,
    required this.title,
    required this.body,
    required this.onContinue,
    this.continueLabel,
    this.confirmBack = false,
    this.padBody = true,
    this.summary,
    this.onSummaryTap,
    super.key,
  });

  final int step;
  final String title;
  final Widget body;

  /// Null disables Continue (nothing valid chosen yet).
  final VoidCallback? onContinue;
  final String? continueLabel;

  /// Step 1: back leaves the flow, so ask first when the draft has values.
  final bool confirmBack;
  final bool padBody;

  /// One line above Continue ("Mornings · 8 AM – 12 PM · Mon to Sat"); tap to edit it.
  final String? summary;
  final VoidCallback? onSummaryTap;

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discoverDiscardTitle),
        content: Text(l10n.discoverDiscardBody),
        actions: [
          TextButton(
            key: const Key('discover_discard_cancel_btn'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.discoverKeepEditing),
          ),
          TextButton(
            key: const Key('discover_discard_confirm_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.discoverDiscard),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;

    Future<void> back() async {
      if (confirmBack && !ref.read(requirementDraftProvider).isEmpty) {
        if (!await _confirmDiscard(context) || !context.mounted) return;
        ref.read(requirementDraftProvider.notifier).reset();
      }
      if (context.mounted) _leave(context);
    }

    Future<void> close() async {
      if (!ref.read(requirementDraftProvider).isEmpty &&
          !await _confirmDiscard(context)) {
        return;
      }
      if (!context.mounted) return;
      ref.read(requirementDraftProvider.notifier).reset();
      context.go(Routes.home);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.only(top: top),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.sm),
                      Material(
                        color: AppColors.surface,
                        elevation: 1,
                        shadowColor: AppColors.navy.withValues(alpha: 0.2),
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.hairline),
                        ),
                        child: IconButton(
                          key: const Key('app_back_btn'),
                          tooltip: l10n.back,
                          onPressed: back,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.brandInk,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppText.card,
                            ),
                            Text(
                              l10n.discoverStep(step, kDiscoverSteps),
                              key: const Key('discover_progress_label'),
                              style: AppText.body.copyWith(
                                fontSize: 12,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('discover_close_btn'),
                        tooltip: l10n.discoverClose,
                        onPressed: close,
                        icon: const Icon(
                          Icons.close,
                          size: 26,
                          color: AppColors.brandInk,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SnStepBar(step: step, total: kDiscoverSteps),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.hairline),
              ],
            ),
          ),
          Expanded(
            child: padBody
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: body,
                  )
                : body,
          ),
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (summary != null && summary!.isNotEmpty)
                  InkWell(
                    key: const Key('discover_summary'),
                    onTap: onSummaryTap,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        summary!,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ),
                  ),
                SnButton(
                  key: const Key('discover_next_btn'),
                  label: continueLabel ?? l10n.discoverContinue,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Cook  Change" chips under the progress bar (steps 2+).
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    required this.label,
    required this.onChange,
    this.icon,
    this.changeKey,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onChange;
  final Key? changeKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.teal),
                const SizedBox(width: 6),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        TextButton(
          key: changeKey,
          onPressed: onChange,
          style: TextButton.styleFrom(
            minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            foregroundColor: AppColors.teal,
          ),
          child: Text(
            l10n.discoverChange,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}

/// Heading + sub-copy block used by every step.
class StepHeading extends StatelessWidget {
  const StepHeading({required this.heading, this.sub, super.key});
  final String heading;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(heading, style: AppText.title.copyWith(fontSize: 26)),
        ),
        if (sub != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(sub!, style: AppText.bodyLarge),
        ],
      ],
    );
  }
}

/// Error card used by every step ("We couldn't load ..." + Try again).
class StepErrorCard extends StatelessWidget {
  const StepErrorCard({
    required this.title,
    required this.body,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.dangerBg,
              child: Icon(Icons.wifi_off, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.lg),
            SnButton(
              key: const Key('error_retry_btn'),
              label: l10n.tryAgain,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// A Continue that either moves forward or, when a step was opened from Review (`edit=true`),
/// returns straight there (modules/04 DISC-14).
void discoverContinue(
  BuildContext context, {
  required bool edit,
  required String next,
}) {
  if (edit && context.canPop()) {
    context.pop();
  } else {
    context.push(next);
  }
}
