import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

class _Promo {
  const _Promo(
    this.serviceId,
    this.photo,
    this.eyebrow,
    this.title,
    this.body,
    this.cta,
  );
  final String? serviceId;
  final String photo;
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
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
        'assets/images/promo-cleaner.jpg',
        l10n.homePromoCleanEyebrow,
        l10n.homePromoCleanTitle,
        l10n.homePromoCleanBody,
        l10n.homePromoCleanCta,
      ),
      _Promo(
        'maid',
        'assets/images/service-maid-bed.jpg',
        l10n.homePromoMaidEyebrow,
        l10n.homePromoMaidTitle,
        l10n.homePromoMaidBody,
        l10n.homePromoMaidCta,
      ),
      _Promo(
        null,
        AppPhotos.room,
        l10n.homePromoPartEyebrow,
        l10n.homePromoPartTitle,
        l10n.homePromoPartBody,
        l10n.homePromoPartCta,
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 210 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
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
        color: AppColors.tealMist,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.tealLine),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 150,
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.2, 0.7],
                  ).createShader(r),
                  child: Image.asset(
                    promo.photo,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    cacheWidth: 600,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.micro.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: 190,
                    child: Semantics(
                      header: true,
                      child: Text(
                        promo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: SizedBox(
                      width: 180,
                      child: Text(
                        promo.body,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: AppText.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
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
          ],
        ),
      ),
    );
  }
}
