import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// True while the device has any network. Unreadable (no plugin, as in tests) counts as online,
/// so a failure here can never show a false banner.
final onlineProvider = StreamProvider<bool>((ref) async* {
  bool up(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);
  try {
    final c = Connectivity();
    yield up(await c.checkConnectivity());
    yield* c.onConnectivityChanged.map(up);
  } on Object {
    yield true;
  }
});

/// Slim "You're offline" strip above the whole app, shown only while there is no connection.
class OfflineBannerHost extends ConsumerWidget {
  const OfflineBannerHost({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(onlineProvider).value == false;
    if (!offline) return child;
    return Column(
      children: [
        Material(
          color: AppColors.warnBg,
          child: SafeArea(
            bottom: false,
            child: Padding(
              key: const Key('offline_banner'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: AppColors.warnIcon,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).offlineBanner,
                      style: AppText.label.copyWith(color: AppColors.warnText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The strip already covers the status bar, so the page below must not pad for it again.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
