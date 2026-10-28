import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/favourites/presentation/widgets/favourite_button.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Your shortlist": swipeable worker cards from `GET /customers/me/home` (`shortlistPreview`).
/// The heart removes a worker through `DELETE /shortlist/{id}`; Home then re-reads the aggregate.
/// The backend sends no price, so none is shown.
class ShortlistPreviewCard extends ConsumerWidget {
  const ShortlistPreviewCard({required this.workers, super.key});
  final List<ShortlistPreview> workers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.homeShortlistTitle, style: AppText.title),
              ),
            ),
            TextButton(
              key: const Key('home_view_favs_btn'),
              onPressed: () => context.go(Routes.favourites),
              child: Text(l10n.homeViewShortlist),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 244 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: workers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (_, i) => SizedBox(
              width: 168,
              child: _WorkerTile(
                w: workers[i],
                onRemoved: () => ref.invalidate(homeProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({required this.w, required this.onRemoved});
  final ShortlistPreview w;
  final VoidCallback onRemoved;

  Widget _fallbackPhoto() {
    final asset = AppPhotos.forService(w.category ?? w.name);
    return asset == null
        ? const ColoredBox(
            color: AppColors.tileWell,
            child: Icon(Icons.person_outline, color: AppColors.teal, size: 40),
          )
        : Image.asset(asset, fit: BoxFit.cover, cacheWidth: 500);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final years = (w.experienceMonths ?? 0) ~/ 12;
    final meta = [
      if (w.category != null && w.category != w.name) w.category!,
      if (w.service.isNotEmpty) w.service,
      if (years > 0) l10n.homeShortlistExperience(years),
    ].join(' · ');
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('home_fav_worker_${w.workerId}'),
        onTap: () =>
            context.push(Routes.path(Routes.workerDetail, {'id': w.workerId})),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: w.photoUrl == null
                        ? _fallbackPhoto()
                        : Image.network(
                            w.photoUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 500,
                            errorBuilder: (_, _, _) => _fallbackPhoto(),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: FavouriteButton(
                        workerId: w.workerId,
                        keyName: 'home_fav_btn_${w.workerId}',
                        onChanged: (fav) {
                          if (!fav) onRemoved();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.card,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (w.ratingAverage != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          w.ratingAverage!.toStringAsFixed(1),
                          style: AppText.label,
                        ),
                      ],
                      const Spacer(),
                      if (w.verified)
                        const Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: AppColors.teal,
                        ),
                    ],
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
