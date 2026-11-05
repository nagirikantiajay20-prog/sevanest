import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/home/presentation/home_hero.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

Widget _heading(String text) => Padding(
  padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
  child: Semantics(
    header: true,
    child: Text(text, style: AppText.title.copyWith(fontSize: 18)),
  ),
);

/// "Featured for your home" heading above the promo carousel.
class HomeFeaturedHeading extends StatelessWidget {
  const HomeFeaturedHeading({super.key});

  @override
  Widget build(BuildContext context) =>
      _heading(AppLocalizations.of(context).homeFeatured);
}

/// Photo banner with the three reasons families choose SevaNest.
class WhyFamiliesBanner extends StatelessWidget {
  const WhyFamiliesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = [l10n.homeWhy1, l10n.homeWhy2, l10n.homeWhy3];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppColors.blackA35x59,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  'assets/home/cook.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.3),
                  cacheWidth: 900,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.sky08182BA10, AppColors.sky08182BA85],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: NavyGlass(
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeWhyTitle,
                          style: AppText.title.copyWith(
                            fontSize: 17,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final p in points)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.surface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "How SevaNest works": four numbered steps.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (l10n.homeHow1Title, l10n.homeHow1Body),
      (l10n.homeHow2Title, l10n.homeHow2Body),
      (l10n.homeHow3Title, l10n.homeHow3Body),
      (l10n.homeHow4Title, l10n.homeHow4Body),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(l10n.homeHowTitle),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: HomeCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.actionDeepTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$1,
                          style: AppText.card.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].$2,
                          style: AppText.body.copyWith(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
