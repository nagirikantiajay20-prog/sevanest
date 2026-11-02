import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/clock.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/draft_validation.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/discover_navigation.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/schedule_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/review` (module 04, step 7): the requirement in one card, each row editable, then
/// Search opens the results.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _searching = false;
  late final _note = TextEditingController(
    text: ref.read(requirementNoteProvider),
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searching) return; // double tap opens Results once
    setState(() => _searching = true);
    try {
      final draft = ref.read(requirementDraftProvider);
      final gap = firstIncompleteStep(
        draft,
        today: ref.read(nowProvider)(),
        config:
            ref.read(scheduleConfigProvider).value ?? ScheduleConfig.fallback,
        requiresBudget:
            ref.read(selectedCategoryProvider)?.requiresBudget ?? true,
      );
      if (gap != null) {
        await sendToGap(context, gap);
        return;
      }
      if (mounted) await context.push<Object?>(Routes.workers);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Edit pushes the step in edit mode: its Continue pops straight back here, later values kept.
  void _edit(DiscoverStep step) =>
      context.push<Object?>('${routeForStep(step)}?edit=true');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final d = ref.watch(requirementDraftProvider);
    final category = ref.watch(selectedCategoryProvider);

    final address = d.address;
    final budget = d.budget;
    final rows =
        <
          ({
            String field,
            DiscoverStep step,
            String label,
            String value,
            IconData icon,
            String? photo,
          })
        >[
          (
            field: 'service',
            step: DiscoverStep.service,
            label: l10n.reviewRowService,
            value: category?.name ?? d.serviceId ?? '',
            icon: category?.icon ?? Icons.work_outline_rounded,
            photo: category == null
                ? null
                : AppPhotos.forService('${category.id} ${category.name}'),
          ),
          if (d.engagement != null)
            (
              field: 'engagement',
              step: DiscoverStep.engagement,
              label: l10n.reviewRowEngagement,
              value: engagementLabels(l10n, d.engagement!).name,
              icon: Icons.schedule_rounded,
              photo: null,
            ),
          if (address != null)
            (
              field: 'address',
              step: DiscoverStep.location,
              label: l10n.reviewRowAddress,
              value:
                  '${address.fullLine}, ${address.area}, ${address.city} ${address.pincode}',
              icon: Icons.place_outlined,
              photo: null,
            ),
          if (d.engagement != null && d.timing != null)
            (
              field: 'timing',
              step: DiscoverStep.timing,
              label: l10n.reviewRowTiming,
              value: timingSummary(
                l10n,
                variant: timingVariantFor(d.engagement!),
                timing: d.timing,
                // Hourly's date is part of its timing line.
                date: d.skipsStartDateStep ? d.startDate : null,
                locale: locale,
              ),
              icon: Icons.calendar_month_outlined,
              photo: null,
            ),
          if (d.startDate != null && !d.skipsStartDateStep)
            (
              field: 'startDate',
              step: DiscoverStep.startDate,
              label: l10n.reviewRowStartDate,
              value: formatDate(d.startDate!, locale),
              icon: Icons.event_available_outlined,
              photo: null,
            ),
          if (budget != null && (category?.requiresBudget ?? true))
            (
              field: 'budget',
              step: DiscoverStep.budget,
              label: l10n.reviewRowBudget,
              value: budget.flexible || budget.min == null || budget.max == null
                  ? l10n.budgetAny
                  : _range(l10n, budget),
              icon: Icons.account_balance_wallet_outlined,
              photo: null,
            ),
        ];

    return DiscoverScaffold(
      // One past the last step: every node shows its tick.
      step: kDiscoverSteps + 1,
      title: l10n.reviewTitle,
      stepLabel: l10n.reviewAllDone,
      nextKey: const Key('discover_search_btn'),
      summary: l10n.reviewSearchHint,
      inlineSummary: true,
      ctaWidth: 176,
      ctaIcon: Icons.search_rounded,
      continueLabel: l10n.reviewSearch,
      searching: _searching,
      searchingLabel: l10n.reviewSearching,
      onContinue: _search,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 20, bottom: 28),
        children: [
          DiscoverRise(
            delayMs: 0,
            child: StepHeading(
              heading: l10n.reviewHeading,
              sub: l10n.reviewSub,
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 100,
            child: DiscoverGlass(
              radius: 28,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (final (i, r) in rows.indexed) ...[
                      if (i > 0) const _Dashed(),
                      DiscoverRise(
                        delayMs: 120.0 + i * 70,
                        child: _Row(
                          key: Key('discover_review_row_${r.field}'),
                          editKey: Key('discover_review_edit_${r.field}'),
                          label: r.label,
                          value: r.value,
                          icon: r.icon,
                          photo: r.photo,
                          onEdit: () => _edit(r.step),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 550,
            child: DiscoverGlass(
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: l10n.reviewNoteLabel.toUpperCase(),
                        children: [
                          TextSpan(
                            text: ' ${l10n.reviewNoteOptional}',
                            style: const TextStyle(
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: _labelStyle,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('discover_review_note'),
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 300,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (v) => ref
                          .read(requirementNoteProvider.notifier)
                          .set(v.trim()),
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        height: 1.4,
                        color: dsNavy,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.reviewNoteHint,
                        hintStyle: AppText.body.copyWith(
                          fontSize: 15,
                          color: dsMuted.withValues(alpha: 0.8),
                        ),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: dsNavy.withValues(alpha: 0.18),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: dsNavy, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 600,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.reviewReassure,
                      style: AppText.body.copyWith(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.actionDeepTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _range(AppLocalizations l10n, Budget b) {
    final r = '${formatRupees(b.min!)} – ${formatRupees(b.max!)}';
    return b.period == BudgetPeriod.hourly
        ? l10n.budgetRangePerHour(r)
        : l10n.budgetRangePerMonth(r);
  }
}

final _labelStyle = AppText.body.copyWith(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
  color: dsMuted,
);

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DashedLine()),
  );
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = dsNavy.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 4, 0.5), p);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => false;
}

class _Row extends StatelessWidget {
  const _Row({
    required this.editKey,
    required this.label,
    required this.value,
    required this.icon,
    required this.onEdit,
    this.photo,
    super.key,
  });
  final Key editKey;
  final String label;
  final String value;
  final IconData icon;
  final String? photo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2EEEC),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: dsNavy.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: photo == null
                ? Icon(icon, size: 20, color: AppColors.teal)
                : Image.asset(
                    photo!,
                    fit: BoxFit.cover,
                    cacheWidth: 140,
                    errorBuilder: (_, _, _) =>
                        Icon(icon, size: 20, color: AppColors.teal),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: _labelStyle),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: dsNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: l10n.reviewEditSemantics(label),
            button: true,
            excludeSemantics: true,
            child: OutlinedButton.icon(
              key: editKey,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: Text(l10n.reviewEdit),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: AppColors.teal,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                side: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                shape: const StadiumBorder(),
                textStyle: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
