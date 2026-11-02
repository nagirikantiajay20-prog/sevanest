import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/schedule_format.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/flow_chips.dart'
    show changeService;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// "Morning · Mon to Fri": the short timing line of the ticket (full detail is on Review).
String ticketTiming(
  AppLocalizations l10n,
  TimingVariant variant,
  Timing? t,
  String locale,
) {
  if (t == null) return '';
  final parts = <String>[
    if (variant == TimingVariant.fullTime)
      if (t.startMinutes != null && t.endMinutes != null)
        formatTimeSpan(t.startMinutes!, t.endMinutes!)
      else
        ''
    else if (t.window != null)
      windowName(l10n, t.window!),
    if (variantUsesDays(variant) && t.days.isNotEmpty)
      formatDays(l10n, t.days, locale),
  ]..removeWhere((e) => e.isEmpty);
  return parts.join(' · ');
}

/// The cells of the "your choices" ticket from the draft: Service, Type, Area and, once chosen,
/// Timing (step 5+) and Start date (step 6). Each pencil reopens its step in edit mode.
List<TicketCell> flowTicketCells(
  BuildContext context,
  WidgetRef ref, {
  bool timing = false,
  bool startDate = false,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final category = ref.watch(selectedCategoryProvider);
  final draft = ref.watch(requirementDraftProvider);
  final engagement = draft.engagement == null
      ? null
      : engagementLabels(l10n, draft.engagement!);
  final address = draft.address;
  final timingText = timing && draft.variant != null
      ? ticketTiming(l10n, draft.variant!, draft.timing, locale)
      : '';
  void edit(String route) => context.push<Object?>('$route?edit=true');

  return [
    if (category != null)
      TicketCell(
        caption: l10n.reviewRowService,
        name: category.name,
        photo: AppPhotos.forService('${category.id} ${category.name}'),
        icon: category.icon,
        semanticLabel: '${l10n.discoverChange}: ${category.name}',
        changeKey: const Key('discover_change_service'),
        onChange: () => changeService(context, ref),
      ),
    if (engagement != null)
      TicketCell(
        caption: l10n.discoverTypeCaption,
        name: engagement.name,
        icon: engagement.icon,
        semanticLabel: '${l10n.discoverChange}: ${engagement.name}',
        changeKey: const Key('discover_change_engagement'),
        onChange: () => edit(Routes.discoverEngagement),
      ),
    if (address != null)
      TicketCell(
        caption: l10n.locationAreaCaption,
        name: address.area.isEmpty ? address.city : address.area,
        icon: Icons.place_outlined,
        semanticLabel:
            '${l10n.discoverChange}: ${address.area.isEmpty ? address.city : address.area}',
        changeKey: const Key('discover_change_address'),
        onChange: () => edit(Routes.discoverLocation),
      ),
    if (timingText.isNotEmpty)
      TicketCell(
        caption: l10n.reviewRowTiming,
        name: timingText,
        icon: Icons.calendar_month_outlined,
        semanticLabel: '${l10n.discoverChange}: $timingText',
        changeKey: const Key('discover_change_timing'),
        onChange: () => edit(Routes.discoverTiming),
      ),
    if (startDate && draft.startDate != null)
      TicketCell(
        caption: l10n.reviewRowStartDate,
        name: formatDate(draft.startDate!, locale),
        icon: Icons.event_available_outlined,
        semanticLabel:
            '${l10n.discoverChange}: ${formatDate(draft.startDate!, locale)}',
        changeKey: const Key('discover_change_start_date'),
        onChange: () => edit(Routes.discoverStartDate),
      ),
  ];
}
