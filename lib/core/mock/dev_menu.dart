import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Hidden developer menu: long-press the Home greeting (never in prod). Flips the mock API so every
/// loading / error / offline / empty state is reachable on a device.
Future<void> showDevMenu(BuildContext context, WidgetRef ref) async {
  if (ref.read(appConfigProvider).env == AppEnv.prod) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _DevMenu(),
  );
}

class _DevMenu extends ConsumerWidget {
  const _DevMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(mockApiProvider);
    final notifier = ref.read(mockApiProvider.notifier);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.devMenuTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.devMenuLive),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    key: const Key('dev_live_on'),
                    label: Text(l10n.devMenuLiveOn),
                    selected: s.live,
                    onSelected: (_) => notifier.set(s.copyWith(live: true)),
                  ),
                  ChoiceChip(
                    key: const Key('dev_live_off'),
                    label: Text(l10n.devMenuLiveOff),
                    selected: !s.live,
                    onSelected: (_) => notifier.set(s.copyWith(live: false)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.devMenuApiMode),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final m in MockMode.values)
                    ChoiceChip(
                      key: Key('dev_mode_${m.name}'),
                      label: Text(m.name),
                      selected: s.mode == m,
                      onSelected: (_) => notifier.set(s.copyWith(mode: m)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.devMenuGate),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    key: const Key('dev_gate_update'),
                    label: Text(l10n.devMenuGateUpdate),
                    selected: s.forceUpdate,
                    onSelected: (v) => notifier.set(s.copyWith(forceUpdate: v)),
                  ),
                  FilterChip(
                    key: const Key('dev_gate_maintenance'),
                    label: Text(l10n.devMenuGateMaint),
                    selected: s.maintenance,
                    onSelected: (v) => notifier.set(s.copyWith(maintenance: v)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.devMenuUser),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    key: const Key('dev_user_returning'),
                    label: Text(l10n.devMenuReturning),
                    selected: s.returningUser,
                    onSelected: (_) =>
                        notifier.set(s.copyWith(returningUser: true)),
                  ),
                  ChoiceChip(
                    key: const Key('dev_user_new'),
                    label: Text(l10n.devMenuNew),
                    selected: !s.returningUser,
                    onSelected: (_) =>
                        notifier.set(s.copyWith(returningUser: false)),
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
