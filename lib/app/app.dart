import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/app_router.dart';
import 'package:sevanest_customer/app/theme/app_theme.dart';
import 'package:sevanest_customer/features/app_gate/app_gate_host.dart';
import 'package:sevanest_customer/features/notifications/presentation/push_host.dart';
import 'package:sevanest_customer/features/payment/presentation/payment_recovery.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

class SevaNestApp extends ConsumerWidget {
  const SevaNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppGateHost(
        child: PushHost(child: PaymentRecoveryHost(child: child!)),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
