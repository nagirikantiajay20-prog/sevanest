import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/address_list_parts.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/addresses` (modules/02, screen 2.3; design: Find a Worker > My addresses). With [selectMode]
/// a tap returns the address to the caller (service discovery) instead of opening the editor.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({this.selectMode = false, super.key});
  final bool selectMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(addressesProvider.notifier);

    Future<void> add() => context.push<Object?>(Routes.addressNew);
    Future<void> edit(Address a) =>
        context.push<Object?>(Routes.path(Routes.addressEdit, {'id': a.id}));

    Future<void> run(Future<AppFailure?> Function() action, String ok) async {
      final messenger = ScaffoldMessenger.of(context);
      final failure = await action();
      if (!context.mounted) return;
      if (failure is ConflictFailure) {
        await infoDialog(
          context,
          body: l10n.addressInUse,
          okLabel: MaterialLocalizations.of(context).okButtonLabel,
        );
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(failure == null ? ok : failureMessage(l10n, failure)),
          ),
        );
    }

    Future<void> menu(Address a) async {
      final action = await showAddressActions(context, a);
      if (!context.mounted) return;
      switch (action) {
        case AddressAction.setDefault:
          await run(() => notifier.setDefault(a.id), l10n.defaultUpdated);
        case AddressAction.edit:
          await edit(a);
        case AddressAction.delete:
          final yes = await showGlassConfirm(
            context,
            title: l10n.deleteConfirmTitle,
            body: l10n.addressDeleteBody,
            confirmLabel: l10n.addressDeleteYes,
            keepLabel: l10n.addressKeep,
            confirmKey: const Key('address_delete_confirm_btn'),
            destructive: true,
          );
          if (yes && context.mounted) {
            await run(() => notifier.delete(a.id), l10n.addressDeleted);
          }
        case null:
      }
    }

    final value = ref.watch(addressesProvider);
    final hasList = value.value?.isNotEmpty ?? false;

    return FindGlassPage(
      title: l10n.myAddressesTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.account),
      body: Stack(
        children: [
          AsyncValueView<List<Address>>(
            value: value,
            onRetry: notifier.refresh,
            isEmpty: (list) => list.isEmpty,
            empty: GlassEmpty(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFF0F766E),
              discColors: const [Color(0xFFE2EEEC), Colors.white],
              title: l10n.addFirstAddress,
              body: l10n.addressesEmptyBody,
              actionLabel: l10n.addAddress,
              actionKey: const Key('addresses_empty_add_btn'),
              onAction: add,
            ),
            data: (list) => RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => DiscoverRise(
                  delayMs: 60.0 + 40 * i.clamp(0, 6),
                  child: AddressCard(
                    address: list[i],
                    index: i,
                    onTap: () =>
                        selectMode ? context.pop(list[i]) : edit(list[i]),
                    onMenu: () => menu(list[i]),
                  ),
                ),
              ),
            ),
          ),
          if (hasList)
            Positioned(
              left: 0,
              right: 0,
              bottom: 22 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: Builder(
                    builder: (ctx) => AuthCta(
                      key: const Key('addresses_add_btn'),
                      clock: DiscoverClock.of(ctx),
                      label: l10n.addAddress,
                      loadingLabel: l10n.addAddress,
                      loading: false,
                      breathe: true,
                      icon: Icons.add_rounded,
                      radius: 18,
                      height: 56,
                      onPressed: add,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
