import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

/// "Change" service: edit mode on step 1. A different service drops the engagement, so it is
/// picked again straight away (steps after it validate the whole draft anyway).
Future<void> changeService(BuildContext context, WidgetRef ref) async {
  await context.push<Object?>('${Routes.discoverCategory}?edit=true');
  if (!context.mounted) return;
  if (ref.read(requirementDraftProvider).engagement == null) {
    await context.push<Object?>('${Routes.discoverEngagement}?edit=true');
  }
}
