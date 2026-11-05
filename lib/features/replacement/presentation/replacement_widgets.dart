import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_timeline.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show avatarGradientFor;
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart'
    show experienceLabel, ratingText;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces shared by the replacement screens (design: Find a Worker > Replacement).

const _rose = AppColors.rose700;

/// Teal "what happens" note at the top of the request form.
class ReplacementInfo extends StatelessWidget {
  const ReplacementInfo(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.teal0F766EA10,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.actionDeepTeal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The engagement being replaced: the worker's avatar and name (the category until the backend
/// names them), the engagement line and an optional [tag] ("Current engagement").
class ReplacementWorker extends StatelessWidget {
  const ReplacementWorker({
    required this.booking,
    this.tag,
    this.muted = false,
    super.key,
  });
  final Booking booking;
  final String? tag;

  /// Greyed (the status screen: the worker being replaced).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = booking;
    final name = bookingWorkerName(b);
    final category = b.categoryName ?? b.categoryCode ?? '';
    final line = [
      if (name != null) category,
      if (b.engagement != null) engagementLabels(l10n, b.engagement!).name,
    ].where((p) => p.isNotEmpty).join(' · ');
    Widget avatar = bookingAvatar(b);
    if (muted) {
      avatar = Opacity(
        opacity: 0.7,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: avatar,
        ),
      );
    }
    return Row(
      key: const Key('replacement_booking_card'),
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name ?? category,
                style: authSerif(
                  19,
                  1.2,
                ).copyWith(color: muted ? dsMuted : null),
              ),
              if (tag != null)
                Container(
                  key: const Key('replacement_previous_tag'),
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky1B3354A8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag!,
                    style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: dsMuted,
                    ),
                  ),
                )
              else if (line.isNotEmpty)
                Text(
                  line,
                  style: AppText.body.copyWith(fontSize: 13.5, color: dsMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One reason of the request form (the design's `.rd` radio row).
class ReasonRadio extends StatelessWidget {
  const ReasonRadio({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.teal0F766EA8 : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.sky1B3354A18,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.teal : AppColors.sky1B3354A30,
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
  );
}

/// Date field of "Needed from": a white pill that opens the date picker, with a clear button.
class NeededFromField extends StatelessWidget {
  const NeededFromField({
    required this.text,
    required this.onPick,
    required this.onClear,
    super.key,
  });
  final String text;
  final VoidCallback? onPick;

  /// Null while no date is chosen.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky1B3354A20, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('replacement_needed_from_btn'),
            onTap: onPick,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: dsNavy,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: AppText.body.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: onClear == null ? dsMuted : dsNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (onClear != null)
        IconButton(
          key: const Key('replacement_needed_from_clear'),
          icon: const Icon(Icons.close_rounded, color: dsNavy),
          onPressed: onClear,
        ),
    ],
  );
}

/// Tint of a status banner.
enum ReplacementTone {
  review(AppColors.warnIcon, AppColors.warn),
  good(AppColors.navyDeep, AppColors.actionDeepTeal),
  bad(AppColors.rose800, AppColors.rose600),
  neutral(AppColors.slate, AppColors.slate400);

  const ReplacementTone(this.from, this.to);
  final Color from;
  final Color to;
}

/// Gradient status banner (the design's `.sb`): small caps status, serif headline, one line.
class ReplacementBanner extends StatelessWidget {
  const ReplacementBanner({
    required this.label,
    required this.title,
    required this.tone,
    this.body,
    super.key,
  });
  final String label;
  final String title;
  final String? body;
  final ReplacementTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tone.from, tone.to],
      ),
      boxShadow: [
        BoxShadow(
          color: tone.from.withValues(alpha: 0.3),
          blurRadius: 34,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            title,
            style: authSerif(24, 1.2).copyWith(color: AppColors.surface),
          ),
        ),
        if (body != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              body!,
              style: AppText.body.copyWith(
                fontSize: 15,
                height: 1.45,
                color: AppColors.surface,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Progress list (the design's `.tl`): a node, a bold step and a grey line under it.
class ReplacementProgress extends StatelessWidget {
  const ReplacementProgress({required this.items, super.key});
  final List<SnTimelineItem> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, it) in items.indexed)
        Padding(
          padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Node(it.state),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.title,
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: it.state == SnTimelineState.failed
                            ? _rose
                            : dsNavy,
                      ),
                    ),
                    Text(
                      _sub(it),
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        color: dsMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Grey line under a step: when it happened and a note, else its state ("In progress").
String _sub(SnTimelineItem it) {
  final line = [it.timestamp, it.subtitle].whereType<String>().join(' · ');
  return line.isEmpty ? it.chip ?? '' : line;
}

class _Node extends StatelessWidget {
  const _Node(this.state);
  final SnTimelineState state;

  @override
  Widget build(BuildContext context) {
    final (fill, line) = switch (state) {
      SnTimelineState.done => (AppColors.teal, AppColors.teal),
      SnTimelineState.current => (AppColors.warnBg, AppColors.amber),
      SnTimelineState.failed => (AppColors.rose100, _rose),
      SnTimelineState.upcoming => (AppColors.surface, AppColors.slate300),
    };
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: line, width: 2),
      ),
      child: state == SnTimelineState.done
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.surface)
          : null,
    );
  }
}

/// Outlined glass action under the progress (the design's `.ac`): Contact support, Withdraw.
class ReplacementAction extends StatelessWidget {
  const ReplacementAction({
    required this.label,
    required this.onPressed,
    this.danger = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      color: danger ? Colors.transparent : AppColors.whiteA80xCC,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: danger ? Colors.transparent : AppColors.sky1B3354A22,
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: danger ? _rose : dsNavy,
            ),
          ),
        ),
      ),
    ),
  );
}

/// One alternative worker (the design's `.pick`): avatar, name, "4.6 ★ · 2 yrs · Verified" and a
/// select mark. [onProfile] opens the full profile.
class AlternativePick extends StatelessWidget {
  const AlternativePick({
    required this.worker,
    required this.scale,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onProfile,
    super.key,
  });
  final WorkerSummary worker;
  final int scale;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = worker;
    final line = [
      if (w.hasRating) '${ratingText(w.ratingAverage!, scale)} ★',
      experienceLabel(l10n, w.experienceMonths),
      if (w.verified) l10n.verified,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DiscoverGlass(
        radius: 22,
        borderColor: selected ? AppColors.teal : AppColors.whiteA90xE6,
        borderWidth: selected ? 2 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              InkWell(
                key: Key('replacement_alt_${w.id}'),
                borderRadius: BorderRadius.circular(22),
                onTap: enabled ? onSelect : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      GlassAvatar(
                        title: w.title,
                        initials: w.initials,
                        photoUrl: w.photoUrl,
                        gradient: avatarGradientFor(w.id),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.title, style: authSerif(19, 1.2)),
                            Text(
                              line,
                              style: AppText.body.copyWith(
                                fontSize: 13.5,
                                color: dsMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? AppColors.teal : dsMuted,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: Key('replacement_alt_profile_${w.id}'),
                  onPressed: onProfile,
                  child: Text('${l10n.repViewProfile} ›'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
