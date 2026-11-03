import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta, authSerif;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces of the Rating screen (design: Find a Worker > Rating).

const _starOn = AppColors.amber;
const _starOff = Color(0xFF94A3B8);

/// "Poor" .. "Excellent" under the stars; other scales read "3 out of 7".
String ratingWord(AppLocalizations l10n, int score, int scale) => scale != 5
    ? l10n.ratingStarLabel(score, scale)
    : switch (score) {
        1 => l10n.ratingWord1,
        2 => l10n.ratingWord2,
        3 => l10n.ratingWord3,
        4 => l10n.ratingWord4,
        _ => l10n.ratingWord5,
      };

/// Frosted hero card: worker avatar, "How was Sunita K.?", the service line and the stars.
class RatingHero extends StatelessWidget {
  const RatingHero({
    required this.booking,
    required this.score,
    required this.scale,
    required this.enabled,
    required this.onScore,
    super.key,
  });
  final Booking booking;
  final int? score;
  final int scale;
  final bool enabled;
  final ValueChanged<int> onScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final b = booking;
    final name = bookingWorkerName(b);
    final line = [
      b.categoryName ?? b.categoryCode,
      if (b.startDate != null) formatDayMonth(b.startDate!, locale),
    ].whereType<String>().join(' · ');
    final s = score;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DiscoverRise(
        delayMs: 0,
        child: DiscoverGlass(
          radius: 26,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              key: const Key('rating_worker_card'),
              children: [
                bookingAvatar(b, size: 72, fontSize: 24),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    name == null ? l10n.ratingQuestion : l10n.ratingHow(name),
                    textAlign: TextAlign.center,
                    style: authSerif(24, 1.2),
                  ),
                ),
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        color: dsMuted,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    for (var n = 1; n <= scale; n++)
                      _Star(
                        n: n,
                        scale: scale,
                        on: n <= (s ?? 0),
                        selected: n == s,
                        onTap: enabled ? () => onScore(n) : null,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 24,
                  child: Text(
                    s == null ? l10n.ratingTapHint : ratingWord(l10n, s, scale),
                    key: Key(
                      s == null ? 'rating_choose_hint' : 'rating_score_label',
                    ),
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dsNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.n,
    required this.scale,
    required this.on,
    required this.selected,
    required this.onTap,
  });
  final int n;
  final int scale;
  final bool on;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.ratingStarLabel(n, scale),
      excludeSemantics: true,
      child: InkResponse(
        key: Key('rating_star_$n'),
        onTap: onTap,
        radius: 30,
        child: SizedBox(
          width: 52,
          height: 52,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(on),
            tween: Tween(begin: on ? 0.6 : 1, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, k, child) =>
                Transform.scale(scale: k, child: child),
            child: Icon(
              on ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 44,
              color: on ? _starOn : _starOff,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thank-you, already-rated and not-eligible states: no form, one way back to the booking.
class RatingMessage extends StatelessWidget {
  const RatingMessage({
    required this.icon,
    required this.title,
    required this.onDone,
    this.body,
    this.score,
    this.scale = 5,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? body;
  final int? score;
  final int scale;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SupportSection(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, dsSky],
                    ),
                  ),
                  child: Icon(icon, size: 42, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: authSerif(24, 1.2),
                ),
                if (score != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.ratingStarLabel(score!, scale),
                    key: const Key('rating_existing_score'),
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dsNavy,
                    ),
                  ),
                ],
                if (body != null && body!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body!,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 15.5,
                      height: 1.5,
                      color: dsText,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                AuthCta(
                  key: const Key('rating_done_btn'),
                  clock: DiscoverClock.of(context),
                  label: l10n.ratingDone,
                  loadingLabel: l10n.ratingDone,
                  loading: false,
                  breathe: true,
                  showArrow: false,
                  radius: 18,
                  height: 58,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill toggle of the design's `.ch` (a "What went well?" tag).
class RatingChip extends StatelessWidget {
  const RatingChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? const Color(0x1F0F766E) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.teal : const Color(0x331B3354),
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF0B5A53) : dsNavy,
            ),
          ),
        ),
      ),
    ),
  );
}
