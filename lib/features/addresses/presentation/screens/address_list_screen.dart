import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/addresses` (modules/02, screen 2.3). With [selectMode] a tap returns the address to the caller
/// (service discovery) instead of opening the editor.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({this.selectMode = false, super.key});
  final bool selectMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(addressesProvider.notifier);

    Future<void> add() => context.push<Object?>(Routes.addressNew);

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

    Future<void> delete(Address a) async {
      final yes = await confirmDialog(
        context,
        title: l10n.deleteConfirmTitle,
        body: l10n.deleteConfirmBody,
        confirmLabel: l10n.delete,
        cancelLabel: l10n.cancel,
        confirmKey: const Key('address_delete_confirm_btn'),
        destructive: true,
      );
      if (yes && context.mounted) {
        await run(() => notifier.delete(a.id), l10n.addressDeleted);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addressesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addresses_add_btn'),
        onPressed: add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addAddress),
      ),
      body: AsyncValueView<List<Address>>(
        value: ref.watch(addressesProvider),
        onRetry: notifier.refresh,
        isEmpty: (list) => list.isEmpty,
        empty: SnEmptyState(
          title: l10n.addFirstAddress,
          message: l10n.addFirstAddressHelp,
          actionLabel: l10n.addAddress,
          actionKey: const Key('addresses_empty_add_btn'),
          onAction: add,
        ),
        data: (list) => RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _AddressCard(
              address: list[i],
              onTap: () => selectMode
                  ? context.pop(list[i])
                  : context.push<Object?>(
                      Routes.path(Routes.addressEdit, {'id': list[i].id}),
                    ),
              onEdit: () => context.push<Object?>(
                Routes.path(Routes.addressEdit, {'id': list[i].id}),
              ),
              onSetDefault: () => run(
                () => notifier.setDefault(list[i].id),
                l10n.defaultUpdated,
              ),
              onDelete: () => delete(list[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = address.id;
    final title = address.area.isEmpty ? address.city : address.area;
    final detail = [
      address.line,
      '${address.city} ${address.pincode}'.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: Key('address_card_$id'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: address.isDefault ? AppColors.teal : AppColors.hairline,
              width: address.isDefault ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDFA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  address.isDefault
                      ? Icons.home_outlined
                      : Icons.location_on_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            key: Key('address_default_tag_$id'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fieldBg,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(
                              l10n.defaultTag,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                key: Key('address_menu_$id'),
                tooltip: l10n.addressMenu,
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: Key('address_edit_$id'),
                    value: onEdit,
                    child: Text(l10n.edit),
                  ),
                  if (!address.isDefault)
                    PopupMenuItem(
                      key: Key('address_set_default_$id'),
                      value: onSetDefault,
                      child: Text(l10n.setAsDefault),
                    ),
                  PopupMenuItem(
                    key: Key('address_menu_delete_$id'),
                    value: onDelete,
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
