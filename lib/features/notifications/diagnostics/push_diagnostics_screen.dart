import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/features/notifications/diagnostics/push_diagnostics.dart';
import 'package:sevanest_customer/features/notifications/presentation/providers/push_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

final pushDiagEnvProvider = Provider<PushDiagEnv>((ref) => RealPushDiagEnv());

class PushDiagState {
  const PushDiagState({this.running = false, this.steps = const []});
  final bool running;
  final List<DiagStep> steps;

  DiagStep? get failed =>
      steps.where((s) => s.status == DiagStatus.fail).firstOrNull;
}

class PushDiagController extends Notifier<PushDiagState> {
  @override
  PushDiagState build() => const PushDiagState();

  Future<void> run() async {
    if (state.running) return;
    state = const PushDiagState(running: true);
    final runner = PushDiagnosticsRunner(
      env: ref.read(pushDiagEnvProvider),
      push: ref.read(pushServiceProvider),
      dio: ref.read(dioProvider),
      onStep: (s) {
        if (ref.mounted) {
          state = PushDiagState(running: true, steps: [...state.steps, s]);
        }
      },
    );
    await runner.run();
    if (ref.mounted) state = PushDiagState(steps: state.steps);
  }
}

final pushDiagProvider = NotifierProvider<PushDiagController, PushDiagState>(
  PushDiagController.new,
);

String _stepName(AppLocalizations l, DiagStepId id) => switch (id) {
  DiagStepId.firebase => l.pushDiagStepFirebase,
  DiagStepId.permission => l.pushDiagStepPermission,
  DiagStepId.channel => l.pushDiagStepChannel,
  DiagStepId.token => l.pushDiagStepToken,
  DiagStepId.register => l.pushDiagStepRegister,
  DiagStepId.trigger => l.pushDiagStepTrigger,
  DiagStepId.delivery => l.pushDiagStepDelivery,
  DiagStepId.ack => l.pushDiagStepAck,
};

String _sourceName(AppLocalizations l, DiagSource s) => switch (s) {
  DiagSource.flutter => l.pushDiagSrcFlutter,
  DiagSource.network => l.pushDiagSrcNetwork,
  DiagSource.backend => l.pushDiagSrcBackend,
  DiagSource.fcm => l.pushDiagSrcFcm,
};

String _statusName(AppLocalizations l, DiagStatus s) => switch (s) {
  DiagStatus.pass => l.pushDiagPass,
  DiagStatus.fail => l.pushDiagFail,
  DiagStatus.skipped => l.pushDiagSkipped,
};

String _verdict(AppLocalizations l, PushDiagState s) {
  final f = s.failed;
  if (f == null) return l.pushDiagOk;
  return l.pushDiagFailedAt(
    _stepName(l, f.id),
    _sourceName(l, f.source ?? DiagSource.flutter),
  );
}

/// Plain-text report. Tokens are masked in the steps already; nothing else secret is collected.
String buildReport(
  AppLocalizations l,
  PushDiagState s, {
  required String flavor,
  required String appVersion,
  required String model,
  required String android,
}) {
  final b = StringBuffer()
    ..writeln('SevaNest push diagnostics')
    ..writeln('Verdict: ${_verdict(l, s)}')
    ..writeln('Flavor: $flavor')
    ..writeln('App version: $appVersion')
    ..writeln('Device: $model')
    ..writeln('Android: $android')
    ..writeln();
  for (final st in s.steps) {
    b
      ..writeln(
        '[${_statusName(l, st.status)}] ${_stepName(l, st.id)} '
        '@ ${st.at.toIso8601String()}',
      )
      ..writeln(st.detail);
    if (st.raw != null) b.writeln('raw: ${st.raw}');
    b.writeln();
  }
  return b.toString();
}

class PushDiagnosticsScreen extends ConsumerWidget {
  const PushDiagnosticsScreen({super.key});

  Color _color(DiagStatus s) => switch (s) {
    DiagStatus.pass => AppColors.green15803D,
    DiagStatus.fail => AppColors.rose700,
    DiagStatus.skipped => AppColors.slate400,
  };

  IconData _icon(DiagStatus s) => switch (s) {
    DiagStatus.pass => Icons.check_circle_rounded,
    DiagStatus.fail => Icons.cancel_rounded,
    DiagStatus.skipped => Icons.remove_circle_outline_rounded,
  };

  Future<void> _copy(BuildContext context, String text) async {
    final l = AppLocalizations.of(context);
    final m = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.pushDiagCopied)));
  }

  Future<void> _copyReport(
    BuildContext context,
    WidgetRef ref,
    PushDiagState s,
  ) async {
    final l = AppLocalizations.of(context);
    final dev = await ref.read(pushDiagEnvProvider).device();
    final version = await ref.read(appVersionProvider.future);
    if (!context.mounted) return;
    await _copy(
      context,
      buildReport(
        l,
        s,
        flavor: ref.read(appConfigProvider).env.name,
        appVersion: version,
        model: dev.model,
        android: dev.android,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(pushDiagProvider);
    final done = !s.running && s.steps.isNotEmpty;
    final ok = done && s.failed == null;
    final denied = s.steps.any(
      (x) => x.id == DiagStepId.permission && x.status == DiagStatus.fail,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.pushDiagTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (done)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _verdict(l, s),
                key: const Key('push_diag_verdict'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _color(ok ? DiagStatus.pass : DiagStatus.fail),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (s.steps.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(l.pushDiagIdle),
            ),
          SnButton(
            label: done ? l.pushDiagRunAgain : l.pushDiagSend,
            loadingLabel: l.pushDiagRunning,
            isLoading: s.running,
            onPressed: () => ref.read(pushDiagProvider.notifier).run(),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final st in s.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SnCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(st.status), color: _color(st.status)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_stepName(l, st.id)} · '
                            '${_statusName(l, st.status)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: _color(st.status)),
                          ),
                          Text(
                            st.at.toIso8601String(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(st.detail),
                          if (st.id == DiagStepId.permission && denied)
                            TextButton(
                              onPressed: () =>
                                  ref.read(pushServiceProvider).openSettings(),
                              child: Text(l.pushDiagOpenSettings),
                            ),
                          if (st.id == DiagStepId.token &&
                              st.status == DiagStatus.pass)
                            TextButton(
                              key: const Key('push_diag_copy_token'),
                              onPressed: () async {
                                final t = await ref
                                    .read(pushDiagEnvProvider)
                                    .fcmToken();
                                if (t != null && context.mounted) {
                                  await _copy(context, t);
                                }
                              },
                              child: Text(l.pushDiagCopyToken),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (done)
            SnButton(
              label: l.pushDiagCopyReport,
              variant: SnButtonVariant.secondary,
              onPressed: () => _copyReport(context, ref, s),
            ),
        ],
      ),
    );
  }
}
