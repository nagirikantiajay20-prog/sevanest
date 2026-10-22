import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/providers/interview_providers.dart';
import 'package:sevanest_customer/features/payment/presentation/providers/payment_providers.dart';
import 'package:sevanest_customer/features/replacement/presentation/providers/replacement_providers.dart';
import 'package:sevanest_customer/features/support/presentation/providers/support_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Reads the entity a link points at, fresh (the payload is only a hint). Throws the repository's
/// failure: 404 / 403 mean "not available".
final linkProbeProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  to,
) async {
  ref.watch(mockApiProvider);
  final seg = Uri.parse(to).pathSegments;
  if (seg.length < 2) return;
  final id = seg[1];
  switch (seg[0]) {
    case 'bookings':
      await ref.read(bookingRepositoryProvider).get(id);
    case 'interviews':
      await ref.read(interviewRepositoryProvider).get(id);
    case 'payments':
      await ref.read(paymentRepositoryProvider).get(id);
    case 'replacements':
      await ref.read(replacementRepositoryProvider).get(id);
    case 'support':
      await ref.read(supportRepositoryProvider).get(id);
  }
});

/// `/open?to=<entity route>` (docs/modules/13, NOT-09 / NOT-10): the entity is read first. If it
/// exists the real screen replaces this one (and reads it again); a 404 or 403 shows "This item
/// isn't available" with a way home.
class DeepLinkScreen extends ConsumerWidget {
  const DeepLinkScreen({required this.to, super.key});
  final String to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ok = to.startsWith('/') && !to.startsWith('//');
    final probe = ok ? ref.watch(linkProbeProvider(to)) : null;
    if (probe != null && probe.hasValue && !probe.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement(to);
      });
    }
    final err = probe?.error;
    final gone = !ok || err is NotFoundFailure || err is ForbiddenFailure;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('app_back_btn'),
          tooltip: l10n.back,
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: gone
              ? Column(
                  key: const Key('link_unavailable'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.slateBg,
                      child: Icon(Icons.search_off, size: 36),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.linkUnavailableTitle,
                      style: text.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.linkUnavailableBody,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SnButton(
                      key: const Key('link_home_btn'),
                      label: l10n.linkGoHome,
                      onPressed: () => context.go(Routes.home),
                    ),
                  ],
                )
              : err != null
              ? Column(
                  key: const Key('link_error'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plainFailureMessage(l10n, err),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SnButton(
                      key: const Key('error_retry_btn'),
                      label: l10n.retry,
                      onPressed: () => ref.invalidate(linkProbeProvider(to)),
                    ),
                  ],
                )
              : const CircularProgressIndicator(key: Key('link_loading')),
        ),
      ),
    );
  }
}
