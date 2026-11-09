import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/home/presentation/home_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Top rated near you": `topRated[]` from Home. The rating count sits beside the score because
/// the backend sets no minimum count. Hidden when the list is empty.
class HomeTopRated extends StatelessWidget {
  const HomeTopRated({required this.workers, super.key});
  final List<TopRatedWorker> workers;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Semantics(
              header: true,
              child: Text(
                l10n.homeTopRated,
                style: AppText.title.copyWith(fontSize: 18),
              ),
            ),
          ),
          SizedBox(
            height:
                140 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
            child: ListView.separated(
              key: const Key('home_top_rated'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: workers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) =>
                  SizedBox(width: 270, child: _Card(w: workers[i])),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.w});
  final TopRatedWorker w;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = [
      ?w.roleName,
      if (w.completedJobs > 0) l10n.homeTopRatedJobs(w.completedJobs),
    ].join(' · ');
    return HomeCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('home_top_rated_${w.workerId}'),
        borderRadius: BorderRadius.circular(22),
        onTap: () =>
            context.push(Routes.path(Routes.workerDetail, {'id': w.workerId})),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.tealWash,
                    foregroundImage: w.photoUrl == null
                        ? null
                        : ResizeImage(NetworkImage(w.photoUrl!), width: 160),
                    onForegroundImageError: w.photoUrl == null
                        ? null
                        : (_, _) {},
                    child: Text(
                      w.name.isEmpty ? '' : w.name[0].toUpperCase(),
                      style: AppText.heading.copyWith(color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.card.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (w.verified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_outlined,
                                size: 16,
                                color: AppColors.teal,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              w.ratingAverage.toStringAsFixed(1),
                              style: AppText.label,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.homeTopRatedCount(w.ratingCount),
                              style: AppText.meta,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (w.reviewSnippet != null) ...[
                const SizedBox(height: 8),
                Text(
                  '“${w.reviewSnippet}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
