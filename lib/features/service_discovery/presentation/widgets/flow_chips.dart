import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Change" service: edit mode on step 1. A different service drops the engagement, so it is
/// picked again straight away (steps after it validate the whole draft anyway).
Future<void> changeService(BuildContext context, WidgetRef ref) async {
  await context.push<Object?>('${Routes.discoverCategory}?edit=true');
  if (!context.mounted) return;
  if (ref.read(requirementDraftProvider).engagement == null) {
    await context.push<Object?>('${Routes.discoverEngagement}?edit=true');
  }
}

/// The "Cook  Change  Part-time  Change  Madhapur  Change" row under the progress bar
/// (steps 4-6). It scrolls sideways; the design clips the last chip at the screen edge.
class FlowChips extends ConsumerWidget {
  const FlowChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final category = ref.watch(selectedCategoryProvider);
    final draft = ref.watch(requirementDraftProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (category != null)
            SelectionChip(
              label: category.name,
              changeKey: const Key('discover_change_service'),
              onChange: () => changeService(context, ref),
            ),
          if (draft.engagement != null)
            SelectionChip(
              label: engagementLabels(l10n, draft.engagement!).name,
              changeKey: const Key('discover_change_engagement'),
              onChange: () => context.push<Object?>(
                '${Routes.discoverEngagement}?edit=true',
              ),
            ),
          if (draft.address != null)
            SelectionChip(
              label: draft.address!.area.isEmpty
                  ? draft.address!.city
                  : draft.address!.area,
              changeKey: const Key('discover_change_address'),
              onChange: () =>
                  context.push<Object?>('${Routes.discoverLocation}?edit=true'),
            ),
        ],
      ),
    );
  }
}
