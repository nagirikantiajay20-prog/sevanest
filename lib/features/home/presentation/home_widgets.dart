import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_format.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Frosted white card shell used by the home sections (design `.g`).
class HomeCard extends StatelessWidget {
  const HomeCard({
    required this.child,
    this.radius = 26,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  // Material (not DecoratedBox) so ListTile ink inside the card stays visible.
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDeep.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.white.withValues(alpha: 0.74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  Widget _bar(double h, {double? w, double r = 12}) => Container(
    height: h,
    width: w,
    decoration: BoxDecoration(
      color: AppColors.hairline,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      children: [
        HomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(24, w: 110, r: 14),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.hairline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(12, w: 120),
                        const SizedBox(height: AppSpacing.sm),
                        _bar(12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _bar(36),
              const SizedBox(height: AppSpacing.md),
              _bar(48),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HomeCard(child: _bar(72)),
      ],
    ),
  );
}

class HomeErrorCard extends StatelessWidget {
  const HomeErrorCard({required this.onRetry, super.key});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return HomeCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.dangerBg,
            child: Icon(Icons.error_outline, color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.homeLoadFailedTitle,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeLoadFailedBody,
            style: text.bodyMedium?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.lg),
          SnButton(
            key: const Key('home_retry_btn'),
            label: l10n.tryAgain,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.onRetry, super.key});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.amber.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.warn),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.homeOffline)),
          TextButton(
            key: const Key('home_offline_retry'),
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class AddAddressBanner extends StatelessWidget {
  const AddAddressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.warnBg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: const Key('home_add_address_btn'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push(Routes.addressNew),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.add_location_alt_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l10n.homeAddressBanner)),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// New user: nothing to show but the three-step onboarding (design "05 Home - New user").
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({required this.onFind, super.key});
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final steps = [l10n.homeStep1, l10n.homeStep2, l10n.homeStep3];
    return HomeCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 96,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.homeNoBookingsTitle,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeNoBookingsBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.tealSoftAlt,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(steps[i])),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SnButton(
            key: const Key('home_onboarding_cta'),
            label: l10n.homeFindWorker,
            variant: SnButtonVariant.secondary,
            onPressed: onFind,
          ),
        ],
      ),
    );
  }
}

/// "Your activity": active booking and upcoming interview in one frosted card.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.booking,
    required this.interview,
    required this.now,
    super.key,
  });

  final ActiveBookingSummary? booking;
  final UpcomingInterview? interview;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeActivity,
                  style: AppText.title.copyWith(fontSize: 15),
                ),
              ),
              TextButton(
                key: const Key('home_view_bookings_btn'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                ),
                onPressed: () => context.go(Routes.bookings),
                child: Text(l10n.homeViewAll),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (booking != null) _BookingTile(booking: booking!),
          if (booking != null && interview != null)
            const SizedBox(height: AppSpacing.md),
          if (interview != null) _InterviewTile(iv: interview!, now: now),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final ActiveBookingSummary booking;

  /// An in-progress service opens the active-service screen; earlier stages open the booking.
  void _open(BuildContext context) => context.push(
    booking.stage == BookingStage.active
        ? '${Routes.serviceCurrent}?bookingId=${Uri.encodeComponent(booking.id)}'
        : Routes.path(Routes.bookingDetail, {'id': booking.id}),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final stages = [
      (BookingStage.matched, l10n.homeStageMatched),
      (BookingStage.trial, l10n.homeStageTrial),
      (BookingStage.active, l10n.homeStageActive),
    ];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: const Key('home_active_booking_card'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.homeStageInProgress,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.homeBookingRef(booking.reference),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.warnBg,
                    foregroundImage: booking.photoUrl == null
                        ? null
                        : NetworkImage(booking.photoUrl!),
                    onForegroundImageError: booking.photoUrl == null
                        ? null
                        : (_, _) {},
                    child: Text(
                      booking.initials,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              booking.workerName,
                              style: text.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (booking.verified)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 16,
                                    color: AppColors.teal,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.verified,
                                    style: const TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Text(
                          [
                            booking.service,
                            booking.engagement,
                            booking.startLabel,
                          ].where((e) => e.trim().isNotEmpty).join(' · '),
                          style: text.bodyMedium?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (var i = 0; i < stages.length; i++)
                    Expanded(
                      child: _StageNode(
                        label: stages[i].$2,
                        index: i,
                        count: stages.length,
                        current: booking.stage.index,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('home_view_booking_btn'),
                onPressed: () => _open(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.homeViewBooking),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.label,
    required this.index,
    required this.count,
    required this.current,
  });

  final String label;
  final int index;
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final isCurrent = index == current;
    final ink = done
        ? const Color(0xFF166534)
        : isCurrent
        ? AppColors.actionDeepTeal
        : const Color(0xFF475569);
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? const Color(0xFF16A34A)
                : isCurrent
                ? AppColors.teal
                : const Color(0xFFE2E8F0),
            border: isCurrent
                ? Border.all(color: const Color(0xFFCCEFE9), width: 4)
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ink,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InterviewTile extends StatelessWidget {
  const _InterviewTile({required this.iv, required this.now});
  final UpcomingInterview iv;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final mode = iv.isTrialVisit ? l10n.homeTrialVisit : l10n.homeVideoCall;
    return Material(
      color: AppColors.tealWash,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: const Key('home_interview_card'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () =>
            context.push(Routes.path(Routes.interviewDetail, {'id': iv.id})),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        DateFormat('EEE').format(iv.startsAt).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${iv.startsAt.day}',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iv.isTrialVisit
                          ? l10n.homeTrialVisitWith(iv.workerName)
                          : l10n.homeInterviewWith(iv.workerName),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${relativeWhen(l10n, iv.startsAt, now)} · $mode',
                      style: text.bodyMedium?.copyWith(color: AppColors.slate),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.teal),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              startsIn(l10n, iv.startsAt, now),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportShortcut extends StatelessWidget {
  const SupportShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HomeCard(
      child: ListTile(
        key: const Key('home_support_btn'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.support_agent, color: AppColors.teal),
        title: Text(l10n.homeSupportShortcut, style: AppText.card),
        subtitle: Text(l10n.homeSupportShortcutBody, style: AppText.body),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.support),
      ),
    );
  }
}

/// An unfinished requirement (persisted draft): pick up where it was left, or start over.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    required this.what,
    required this.step,
    required this.onContinue,
    required this.onDiscard,
    super.key,
  });

  final String what;
  final int step;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  static const _steps = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyedSubtree(
      key: const Key('home_resume_card'),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resumeTitle, style: AppText.title.copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              l10n.resumeBody(what, step, _steps),
              style: AppText.body.copyWith(
                fontSize: 12,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(end: step / _steps),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  color: AppColors.teal,
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('home_resume_btn'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionDeepTeal,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.resumeContinue,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('home_resume_discard_btn'),
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                  ),
                  child: Text(l10n.resumeDiscard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
