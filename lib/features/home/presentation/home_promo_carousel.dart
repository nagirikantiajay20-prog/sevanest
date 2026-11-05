import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

class _Promo {
  _Promo(
    this.serviceId,
    this.photo,
    this.eyebrow,
    this.title,
    this.body,
    this.cta,
    this.focus,
  );
  final String? serviceId;
  final String photo;
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final Alignment focus;
}

/// Swipeable promo banners under the search CTA (design 09: "Professional cleaning" + dots).
/// [onCta] gets the service id to preset, or null for the full find flow.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({required this.onCta, super.key});
  final ValueChanged<String?> onCta;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      _Promo(
        'clean',
        'assets/home/cleaning.jpg',
        l10n.homePromoCleanEyebrow,
        l10n.homePromoCleanTitle,
        l10n.homePromoCleanBody,
        l10n.homePromoCleanCta,
        const Alignment(0.3, -0.1),
      ),
      _Promo(
        'maid',
        'assets/home/daily_care.jpg',
        l10n.homePromoMaidEyebrow,
        l10n.homePromoMaidTitle,
        l10n.homePromoMaidBody,
        l10n.homePromoMaidCta,
        const Alignment(0.0, 0.2),
      ),
      _Promo(
        'cook',
        'assets/home/cook.jpg',
        l10n.homePromoCookEyebrow,
        l10n.homePromoCookTitle,
        l10n.homePromoCookBody,
        l10n.homePromoCookCta,
        const Alignment(0.0, -0.2),
      ),
      _Promo(
        'driver',
        'assets/home/driver.jpg',
        l10n.homePromoDriverEyebrow,
        l10n.homePromoDriverTitle,
        l10n.homePromoDriverBody,
        l10n.homePromoDriverCta,
        const Alignment(0.0, -0.1),
      ),
      _Promo(
        'nanny',
        'assets/home/babysitter.jpg',
        l10n.homePromoBabyEyebrow,
        l10n.homePromoBabyTitle,
        l10n.homePromoBabyBody,
        l10n.homePromoBabyCta,
        const Alignment(0.0, -0.2),
      ),
      _Promo(
        'elder',
        'assets/home/elder.jpg',
        l10n.homePromoElderEyebrow,
        l10n.homePromoElderTitle,
        l10n.homePromoElderBody,
        l10n.homePromoElderCta,
        const Alignment(0.0, -0.1),
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 200 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
          child: PageView.builder(
            key: const Key('home_promo_carousel'),
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                right: i == slides.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: _PromoCard(
                promo: slides[i],
                onCta: () => widget.onCta(slides[i].serviceId),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.teal : AppColors.slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onCta});
  final _Promo promo;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.blackA35x59,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Image.asset(
                promo.photo,
                fit: BoxFit.cover,
                alignment: promo.focus,
                cacheWidth: 800,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.sky08182BA90,
                    AppColors.sky08182BA50,
                    AppColors.sky08182BA5,
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 196,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              promo.eyebrow.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            promo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(
                              fontSize: 18,
                              height: 1.2,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.whiteA90xE6,
                          ),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: onCta,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.actionDeepTeal,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              promo.cta,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
