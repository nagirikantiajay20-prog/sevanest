import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show authSerif;
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/location_widgets.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/location` (screen 08, step 3 of 6): pick the address workers must serve.
/// States: loading, error, no saved addresses, list (Home / Office selected), finding GPS,
/// permission denied. "Add address" reuses the shared address form.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({this.edit = false, super.key});
  final bool edit;

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _finding = false;
  LocationOutcome? _problem;
  bool _seeded = false;

  /// Default selection: the draft's address, else the Home chip choice, else the default address.
  void _seed(List<Address> list) {
    if (_seeded || list.isEmpty) return;
    _seeded = true;
    final notifier = ref.read(requirementDraftProvider.notifier);
    final current = ref.read(requirementDraftProvider).address;
    final stillThere = list.where((a) => a.id == current?.id).firstOrNull;
    if (stillThere != null) {
      // Refresh the snapshot (the address may have been edited), outside the build phase.
      Future.microtask(() => notifier.setAddress(stillThere));
      return;
    }
    final chip = ref.read(selectedAddressProvider);
    final pick =
        list.where((a) => a.id == chip?.id).firstOrNull ??
        list.where((a) => a.isDefault).firstOrNull ??
        list.first;
    Future.microtask(() => notifier.setAddress(pick));
  }

  Future<void> _add([AddressInput? prefill]) async {
    final saved = await showAddAddressSheet(context, prefill: prefill);
    if (saved != null && mounted) {
      ref.read(requirementDraftProvider.notifier).setAddress(saved);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_finding) return;
    setState(() {
      _finding = true;
      _problem = null;
    });
    final res = await ref.read(locationServiceProvider).currentAddress();
    if (!mounted) return;
    setState(() => _finding = false);
    switch (res.outcome) {
      case LocationOutcome.found:
        final found = res.input;
        final area = found == null ? null : await resolveFoundArea(ref, found);
        await _add(
          found == null || area == null
              ? found
              : AddressInput(
                  line: found.line,
                  area: area.name,
                  city: area.city ?? found.city,
                  pincode: found.pincode,
                  latitude: found.latitude,
                  longitude: found.longitude,
                ),
        );
      case _:
        setState(() => _problem = res.outcome);
    }
  }

  /// An area outside `GET /service-areas` is not served; no list (call failed or empty) = no block.
  bool _served(Address a, List<ServiceArea>? areas) =>
      a.isServiceable ??
      isServiceableCity(a.city) &&
          (areas == null ||
              areas.isEmpty ||
              areas.any((s) => s.name.toLowerCase() == a.area.toLowerCase()));

  Future<void> _changeService() async {
    await context.push<Object?>('${Routes.discoverCategory}?edit=true');
    if (!mounted) return;
    // A different service drops the engagement: pick it again before continuing.
    if (ref.read(requirementDraftProvider).engagement == null) {
      await context.push<Object?>('${Routes.discoverEngagement}?edit=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final category = ref.watch(selectedCategoryProvider);
    final draft = ref.watch(requirementDraftProvider);
    final addresses = ref.watch(addressesProvider);
    final list = addresses.value;
    if (list != null) _seed(list);

    final selected = list?.where((a) => a.id == draft.address?.id).firstOrNull;
    // Module 04: an area outside `GET /service-areas` blocks Continue.
    final areas = ref.watch(serviceAreasProvider).value;
    final served = selected == null || _served(selected, areas);
    final canContinue = selected != null && served && draft.engagement != null;

    Widget body;
    if (addresses.hasError && list == null) {
      body = StepErrorCard(
        title: l10n.locationLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.read(addressesProvider.notifier).refresh(),
      );
    } else if (list == null) {
      body = const AddressSkeleton();
    } else if (list.isEmpty) {
      body = NoAddressCard(onAdd: _add);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.locationSaved, style: authSerif(20, 1.25)),
                ),
              ),
              Text(
                l10n.locationSavedCount(list.length),
                style: AppText.body.copyWith(fontSize: 14, color: dsMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (i, a) in list.indexed) ...[
            AddressCard(
              address: a,
              index: i,
              selected: a.id == selected?.id,
              served: _served(a, areas),
              onTap: () =>
                  ref.read(requirementDraftProvider.notifier).setAddress(a),
              onEdit: () => context.push<Object?>(
                Routes.path(Routes.addressEdit, {'id': a.id}),
              ),
              onMakeDefault: () =>
                  ref.read(addressesProvider.notifier).setDefault(a.id),
            ),
            const SizedBox(height: 12),
          ],
          AddAddressButton(onTap: _add),
        ],
      );
    }

    final engagement = draft.engagement == null
        ? null
        : engagementLabels(l10n, draft.engagement!);

    return DiscoverScaffold(
      step: 3,
      title: l10n.locationTitle,
      continueLabel: selected == null
          ? null
          : l10n.locationContinueTo(
              selected.area.isEmpty ? selected.city : selected.area,
            ),
      onContinue: canContinue
          ? () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverTiming,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          if (category != null || engagement != null)
            DiscoverRise(
              delayMs: 0,
              child: ChoicesTicket(
                cells: [
                  if (category != null)
                    TicketCell(
                      caption: l10n.reviewRowService,
                      name: category.name,
                      photo: AppPhotos.forService(
                        '${category.id} ${category.name}',
                      ),
                      icon: category.icon,
                      semanticLabel: '${l10n.discoverChange}: ${category.name}',
                      changeKey: const Key('discover_change_service'),
                      onChange: _changeService,
                    ),
                  if (engagement != null)
                    TicketCell(
                      caption: l10n.discoverTypeCaption,
                      name: engagement.name,
                      icon: engagement.icon,
                      semanticLabel:
                          '${l10n.discoverChange}: ${engagement.name}',
                      changeKey: const Key('discover_change_engagement'),
                      onChange: () => context.push<Object?>(
                        '${Routes.discoverEngagement}?edit=true',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          DiscoverRise(
            delayMs: 80,
            child: StepHeading(
              heading: l10n.locationHeading,
              sub: l10n.locationSub,
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRise(
            delayMs: 200,
            child: CurrentLocationButton(
              finding: _finding,
              onTap: _useCurrentLocation,
            ),
          ),
          const SizedBox(height: 12),
          if (_problem case final problem?) ...[
            PermissionOffCard(
              outcome: problem,
              onAction: () => runLocationProblemAction(
                ref.read(locationServiceProvider),
                problem,
                _useCurrentLocation,
              ),
              onChooseSaved: () => setState(() => _problem = null),
            ),
            const SizedBox(height: 12),
          ],
          if (!served) ...[const NotServedNote(), const SizedBox(height: 12)],
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}
