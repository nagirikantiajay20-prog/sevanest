import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Steps in the requirement builder (design: "Step n of 6"); Review is the end, not a step.
const kDiscoverSteps = 6;

/// Shared chrome for every requirement-builder step: back, title, close (X), progress nodes,
/// scrollable body and the sticky Continue button (modules/04 "Shared chrome").
class DiscoverScaffold extends ConsumerStatefulWidget {
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
    this.stepLabel,
    this.nextKey,
    this.inlineSummary = false,
    this.ctaWidth = 196,
    this.searching = false,
    this.searchingLabel,
    this.ctaIcon = Icons.arrow_forward_rounded,
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

  /// Replaces "Step n of 6" (Review: "All steps done").
  final String? stepLabel;

  /// Key of the sticky button when a screen needs its own (Review: search).
  final Key? nextKey;

  /// Budget / Review: the summary sits left of a [ctaWidth]-wide button instead of above it.
  final bool inlineSummary;
  final double ctaWidth;

  /// Review: the button shows a spinner and [searchingLabel] while the search starts.
  final bool searching;
  final String? searchingLabel;
  final IconData ctaIcon;

  @override
  ConsumerState<DiscoverScaffold> createState() => _DiscoverScaffoldState();
}

class _DiscoverScaffoldState extends ConsumerState<DiscoverScaffold>
    with SingleTickerProviderStateMixin {
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDiscoverDiscard(
      context,
      title: l10n.discoverDiscardTitle,
      body: l10n.discoverDiscardBody,
      keep: l10n.discoverKeepEditing,
      discard: l10n.discoverDiscard,
    );
  }

  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = widget;

    Future<void> back() async {
      if (w.confirmBack && !ref.read(requirementDraftProvider).isEmpty) {
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

    return DiscoverClock(
      clock: _clock,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        body: Stack(
          children: [
            Positioned.fill(
              child: RoomBackdrop(clock: _clock, style: discoverBackdrop),
            ),
            Column(
              children: [
                DiscoverHeader(
                  clock: _clock,
                  title: w.title,
                  stepLabel:
                      w.stepLabel ?? l10n.discoverStep(w.step, kDiscoverSteps),
                  step: w.step,
                  total: kDiscoverSteps,
                  backLabel: l10n.back,
                  closeLabel: l10n.discoverClose,
                  onBack: back,
                  onClose: close,
                ),
                Expanded(
                  child: w.padBody
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: w.body,
                        )
                      : w.body,
                ),
                _Footer(
                  clock: _clock,
                  summary: w.summary,
                  onSummaryTap: w.onSummaryTap,
                  nextKey: w.nextKey ?? const Key('discover_next_btn'),
                  label: w.continueLabel ?? l10n.discoverContinue,
                  onContinue: w.onContinue,
                  inline: w.inlineSummary,
                  ctaWidth: w.ctaWidth,
                  loading: w.searching,
                  loadingLabel: w.searchingLabel,
                  icon: w.ctaIcon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted bottom bar holding the (optional) summary line and the Continue button.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.clock,
    required this.summary,
    required this.onSummaryTap,
    required this.nextKey,
    required this.label,
    required this.onContinue,
    required this.inline,
    required this.ctaWidth,
    required this.loading,
    required this.loadingLabel,
    required this.icon,
  });

  final bool inline;
  final double ctaWidth;
  final bool loading;
  final String? loadingLabel;
  final IconData icon;
  final ValueListenable<double> clock;
  final String? summary;
  final VoidCallback? onSummaryTap;
  final Key nextKey;
  final String label;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return AuthGlass(
      radius: BorderRadius.zero,
      blur: 26,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xD1FFFFFF), Color(0x94FFFFFF)],
      ),
      border: const Border(top: BorderSide(color: Color(0xE6FFFFFF))),
      shadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, -8),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: inline
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        summary ?? '',
                        key: summary == null || summary!.isEmpty
                            ? null
                            : const Key('discover_summary'),
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: dsText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: ctaWidth, child: _cta()),
                ],
              )
            : Column(
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
                          style: AppText.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: dsText,
                          ),
                        ),
                      ),
                    ),
                  _cta(),
                ],
              ),
      ),
    );
  }

  Widget _cta() => AuthCta(
    key: nextKey,
    clock: clock,
    label: label,
    loadingLabel: loadingLabel ?? label,
    loading: loading,
    breathe: true,
    icon: icon,
    radius: 18,
    height: 58,
    onPressed: onContinue,
  );
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
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.teal),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.card.copyWith(fontSize: 14),
            ),
          ),
          const Text('·', style: AppText.body),
          TextButton(
            key: changeKey,
            onPressed: onChange,
            style: TextButton.styleFrom(
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              foregroundColor: AppColors.teal,
            ),
            child: Text(
              l10n.discoverChange,
              style: AppText.label.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
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
          child: Text(heading, style: authSerif(30, 1.15)),
        ),
        if (sub != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            sub!,
            style: AppText.body.copyWith(
              fontSize: 15,
              height: 1.45,
              color: dsText,
            ),
          ),
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
    return DiscoverRise(
      delayMs: 0,
      child: DiscoverGlass(
        radius: 26,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerBg,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 26,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: authSerif(20, 1.25),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 14, color: dsText),
              ),
              const SizedBox(height: 18),
              SnButton(
                key: const Key('error_retry_btn'),
                label: l10n.tryAgain,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
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
