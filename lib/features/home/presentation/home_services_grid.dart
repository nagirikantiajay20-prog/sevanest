import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "What kind of help do you need?": two-column photo mosaic, tall and short tiles alternating
/// (design: Home - Previous). Each tile is placed in the shorter column.
class HomeServicesGrid extends StatelessWidget {
  const HomeServicesGrid({
    required this.categories,
    required this.onTile,
    required this.onSeeAll,
    super.key,
  });

  final List<ServiceCategory> categories;
  final ValueChanged<String> onTile;
  final VoidCallback onSeeAll;

  static const _row = 108.0;
  static const _gap = 10.0;
  static const _spans = [2, 1, 1, 1, 2, 1];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cols = [<Widget>[], <Widget>[]];
    final used = [0, 0];
    for (var i = 0; i < categories.length; i++) {
      final span = _spans[i % _spans.length];
      final c = used[0] <= used[1] ? 0 : 1;
      used[c] += span;
      if (cols[c].isNotEmpty) cols[c].add(const SizedBox(height: _gap));
      cols[c].add(
        SizedBox(
          height: _row * span + _gap * (span - 1),
          child: _Tile(category: categories[i], onTap: onTile),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.homeHelpTitle,
                    style: AppText.title.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
            TextButton(
              key: const Key('home_see_all_btn'),
              onPressed: onSeeAll,
              child: Text(l10n.homeSeeAll),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < 2; c++) ...[
              if (c == 1) const SizedBox(width: _gap),
              Expanded(child: Column(children: cols[c])),
            ],
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.category, required this.onTap});
  final ServiceCategory category;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final photo = AppPhotos.forService('${category.id} ${category.name}');
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF12263F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.85),
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('home_category_tile_${category.id}'),
          onTap: () => onTap(category.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo == null)
                Center(child: Icon(category.icon, color: Colors.white))
              else
                Image.asset(
                  photo,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  errorBuilder: (_, _, _) =>
                      Center(child: Icon(category.icon, color: Colors.white)),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0, -0.1),
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0008182B), Color(0x9908182B)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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
