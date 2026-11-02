import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/engagement_card.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/engagement` (screen 07, step 2 of 6). Options come from the chosen service only;
/// an option the service can't offer is shown disabled with its reason (Driver + Live-in).
class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen> {
  bool _checked = false;

  /// "Change" service: the draft may lose its engagement, which is then re-picked on this screen.
  Future<void> _changeService() async {
    await context.push<Object?>('${Routes.discoverCategory}?edit=true');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final category = ref.watch(selectedCategoryProvider);
    final draft = ref.watch(requirementDraftProvider);

    // Catalogue loaded but no service chosen (resumed draft / deep link): go pick one.
    // Decided once, when the catalogue first answers: later changes (e.g. a discarded draft)
    // must not bounce an already-open screen.
    if (!_checked && (categories.hasValue || categories.hasError)) {
      _checked = true;
      if (categories.hasValue && category == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement(Routes.discoverCategory);
        });
      }
    }

    final available = category?.engagements.where((e) => e.available).toList();
    // An engagement the service doesn't offer (stale draft) is dropped, never kept as a combo.
    if (available != null &&
        draft.engagement != null &&
        !available.any((o) => o.type == draft.engagement)) {
      Future.microtask(
        () => ref.read(requirementDraftProvider.notifier).clearEngagement(),
      );
    }
    // A single supported option is preselected (DISC-05).
    if (available != null &&
        available.length == 1 &&
        draft.engagement == null) {
      Future.microtask(
        () => ref
            .read(requirementDraftProvider.notifier)
            .setEngagement(available.single.type),
      );
    }

    final picked = draft.engagement == null
        ? null
        : engagementLabels(l10n, draft.engagement!).name;

    Widget content;
    if (categories.hasError && category == null) {
      content = StepErrorCard(
        title: l10n.engagementLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.invalidate(categoriesProvider),
      );
    } else if (category == null) {
      content = const EngagementSkeleton();
    } else {
      content = Column(
        children: [
          for (final (i, o) in category.engagements.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            EngagementCard(
              index: i,
              option: o,
              selected: draft.engagement == o.type,
              onTap: () => ref
                  .read(requirementDraftProvider.notifier)
                  .setEngagement(o.type),
            ),
          ],
        ],
      );
    }

    return DiscoverScaffold(
      step: 2,
      title: l10n.engagementTitle,
      continueLabel: picked == null ? null : l10n.discoverContinueWith(picked),
      onContinue: picked == null
          ? null
          : () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverLocation,
            ),
      body: ListView(
        padding: const EdgeInsets.only(top: 18, bottom: 20),
        children: [
          if (category != null)
            DiscoverRise(
              delayMs: 0,
              child: ServiceTicket(
                caption: l10n.reviewRowService,
                name: category.name,
                photo: AppPhotos.forService('${category.id} ${category.name}'),
                icon: category.icon,
                semanticLabel: '${l10n.discoverChange}: ${category.name}',
                changeKey: const Key('discover_change_service'),
                onChange: _changeService,
              ),
            ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 80,
            child: StepHeading(
              heading: l10n.engagementHeading,
              sub: l10n.engagementSub,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
