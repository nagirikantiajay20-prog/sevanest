import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/home/presentation/providers/home_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/engagement_labels.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
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
  bool _permissionOff = false;
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
    final saved = await context.push<Object?>(
      Routes.addressNew,
      extra: prefill,
    );
    if (saved is Address && mounted) {
      ref.read(requirementDraftProvider.notifier).setAddress(saved);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_finding) return;
    setState(() {
      _finding = true;
      _permissionOff = false;
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
      case LocationOutcome.denied || LocationOutcome.deniedForever:
        setState(() => _permissionOff = true);
      case LocationOutcome.unavailable:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).locationFailed),
            ),
          );
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
    final canContinue = selected != null && draft.engagement != null;

    Widget body;
    if (addresses.hasError && list == null) {
      body = StepErrorCard(
        title: l10n.locationLoadFailedTitle,
        body: l10n.discoverLoadFailedBody,
        onRetry: () => ref.read(addressesProvider.notifier).refresh(),
      );
    } else if (list == null) {
      body = const _AddressSkeleton();
    } else if (list.isEmpty) {
      body = _NoAddressCard(onAdd: _add);
    } else {
      body = _SavedList(
        addresses: list,
        selectedId: selected?.id,
        onSelect: (a) =>
            ref.read(requirementDraftProvider.notifier).setAddress(a),
        onMakeDefault: (a) =>
            ref.read(addressesProvider.notifier).setDefault(a.id),
      );
    }

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
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (category != null)
                SelectionChip(
                  label: category.name,
                  changeKey: const Key('discover_change_service'),
                  onChange: () async {
                    await context.push<Object?>(
                      '${Routes.discoverCategory}?edit=true',
                    );
                    if (!mounted) return;
                    // A different service drops the engagement: pick it again before continuing.
                    if (ref.read(requirementDraftProvider).engagement == null &&
                        context.mounted) {
                      await context.push<Object?>(
                        '${Routes.discoverEngagement}?edit=true',
                      );
                    }
                  },
                ),
              if (draft.engagement != null)
                SelectionChip(
                  label: engagementLabels(l10n, draft.engagement!).name,
                  changeKey: const Key('discover_change_engagement'),
                  onChange: () => context.push<Object?>(
                    '${Routes.discoverEngagement}?edit=true',
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StepHeading(heading: l10n.locationHeading, sub: l10n.locationSub),
          const SizedBox(height: AppSpacing.md),
          _CurrentLocationButton(finding: _finding, onTap: _useCurrentLocation),
          const SizedBox(height: AppSpacing.md),
          if (_permissionOff) ...[
            _PermissionOffCard(
              onOpenSettings: () =>
                  ref.read(locationServiceProvider).openSettings(),
              onChooseSaved: () => setState(() => _permissionOff = false),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          body,
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({required this.finding, required this.onTap});
  final bool finding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: finding ? AppColors.teal : AppColors.slate,
          width: finding ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        key: const Key('discover_use_location_btn'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: finding ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F5),
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: finding
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: AppColors.teal),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finding
                            ? l10n.locationFinding
                            : l10n.locationUseCurrent,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        finding
                            ? l10n.locationFindingSub
                            : l10n.locationUseCurrentSub,
                        style: text.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                if (!finding) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionOffCard extends StatelessWidget {
  const _PermissionOffCard({
    required this.onOpenSettings,
    required this.onChooseSaved,
  });
  final VoidCallback onOpenSettings;
  final VoidCallback onChooseSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.location_off_outlined, color: AppColors.danger),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.locationOffTitle,
                    key: const Key('discover_location_off'),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.locationOffBody,
                    style: text.bodyMedium?.copyWith(color: AppColors.slate),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: 180,
                    child: SnButton(
                      key: const Key('discover_open_settings_btn'),
                      label: l10n.locationOpenSettings,
                      variant: SnButtonVariant.secondary,
                      onPressed: onOpenSettings,
                    ),
                  ),
                  TextButton(
                    key: const Key('discover_choose_saved_btn'),
                    onPressed: onChooseSaved,
                    child: Text(
                      l10n.locationChooseSaved,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
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

class _NoAddressCard extends StatelessWidget {
  const _NoAddressCard({required this.onAdd});
  final Future<void> Function([AddressInput?]) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.add_home_outlined,
              size: 56,
              color: AppColors.navy,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.locationNoAddressTitle,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              l10n.locationNoAddressBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.md),
            SnButton(
              key: const Key('discover_empty_add_address_btn'),
              label: l10n.addAddress,
              onPressed: () => onAdd(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onMakeDefault,
  });

  final List<Address> addresses;
  final String? selectedId;
  final ValueChanged<Address> onSelect;
  final ValueChanged<Address> onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.locationSaved,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              l10n.locationSavedCount(addresses.length),
              style: text.bodySmall?.copyWith(color: AppColors.slate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final a in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _AddressRow(
              address: a,
              selected: a.id == selectedId,
              onTap: () => onSelect(a),
              onEdit: () => context.push<Object?>(
                Routes.path(Routes.addressEdit, {'id': a.id}),
              ),
              onMakeDefault: () => onMakeDefault(a),
            ),
          ),
        TextButton.icon(
          key: const Key('discover_add_address_btn'),
          onPressed: () => context.push<Object?>(Routes.addressNew),
          icon: const Icon(Icons.add),
          label: Text(l10n.addAddress),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onMakeDefault,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = address.title;
    final detail = [
      address.fullLine,
      '${address.city} ${address.pincode}'.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? const Color(0xFFEAF8F5) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.slate,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: InkWell(
          key: Key('discover_address_${address.id}'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4,
              AppSpacing.xs,
              AppSpacing.sm + 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            title,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              key: Key('discover_default_tag_${address.id}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Text(
                                l10n.defaultTag,
                                style: text.bodySmall,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: l10n.addressMenu,
                      key: Key('discover_address_menu_${address.id}'),
                      onSelected: (v) =>
                          v == 'edit' ? onEdit() : onMakeDefault(),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        if (!address.isDefault)
                          PopupMenuItem(
                            value: 'default',
                            child: Text(l10n.locationMakeDefault),
                          ),
                      ],
                    ),
                    selected
                        ? const CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.teal,
                            child: Icon(
                              Icons.check,
                              size: 17,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.slate,
                                width: 1.5,
                              ),
                            ),
                          ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressSkeleton extends StatelessWidget {
  const _AddressSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.hairline),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        width: 90,
                        color: AppColors.hairline,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 10, color: AppColors.hairline),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
