import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/features/app_gate/app_gate.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Runs the force-update / maintenance check on launch and on every resume, for signed-in and
/// signed-out users alike, and covers the whole app while blocked. Sits above the router.
class AppGateHost extends ConsumerStatefulWidget {
  const AppGateHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppGateHost> createState() => _State();
}

class _State extends ConsumerState<AppGateHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  // Registered before the router mounts, so it sees Back first: while blocked there is no way around.
  @override
  Future<bool> didPopRoute() async =>
      ref.read(appGateProvider).kind != AppGateKind.none;

  void _check() => unawaited(ref.read(appGateProvider.notifier).check());

  @override
  Widget build(BuildContext context) {
    // Dev menu flags apply at once while on mocks.
    ref.listen(
      mockApiProvider.select((s) => (s.forceUpdate, s.maintenance)),
      (_, _) => _check(),
    );
    final gate = ref.watch(appGateProvider);
    final blocked = gate.kind != AppGateKind.none;
    return Stack(
      children: [
        // Kept mounted so a cleared gate returns to where the customer was.
        Offstage(offstage: blocked, child: widget.child),
        if (blocked)
          if (gate.kind == AppGateKind.forceUpdate)
            _UpdateScreen(storeUrl: gate.storeUrl)
          else
            const _MaintenanceScreen(),
      ],
    );
  }
}

class _GateScaffold extends ConsumerWidget {
  const _GateScaffold({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dev =
        ref.watch(appConfigProvider).env != AppEnv.prod &&
        !ref.watch(mockApiProvider.select((s) => s.live));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: AppColors.teal),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.slate),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...actions,
                if (dev)
                  TextButton(
                    key: const Key('gate_dev_off_btn'),
                    onPressed: () => ref
                        .read(mockApiProvider.notifier)
                        .set(
                          ref
                              .read(mockApiProvider)
                              .copyWith(forceUpdate: false, maintenance: false),
                        ),
                    child: Text(l10n.gateDevOff),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateScreen extends ConsumerWidget {
  const _UpdateScreen({this.storeUrl});
  final String? storeUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _GateScaffold(
      icon: Icons.system_update_outlined,
      title: l10n.gateUpdateTitle,
      body: l10n.gateUpdateBody,
      actions: [
        if (storeUrl != null)
          FilledButton(
            key: const Key('gate_update_btn'),
            onPressed: () => ref.read(openStoreProvider)(storeUrl!),
            child: Text(l10n.gateUpdateBtn),
          ),
      ],
    );
  }
}

class _MaintenanceScreen extends ConsumerStatefulWidget {
  const _MaintenanceScreen();

  @override
  ConsumerState<_MaintenanceScreen> createState() => _MaintState();
}

class _MaintState extends ConsumerState<_MaintenanceScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _retry() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await ref.read(appGateProvider.notifier).check();
    if (mounted) {
      setState(() {
        _busy = false;
        _failed = !ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GateScaffold(
      icon: Icons.construction_outlined,
      title: l10n.gateMaintTitle,
      body: l10n.gateMaintBody,
      actions: [
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.gateRetryFailed,
              key: const Key('gate_retry_failed'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        FilledButton(
          key: const Key('gate_retry_btn'),
          onPressed: _busy ? null : _retry,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.retry),
        ),
      ],
    );
  }
}
