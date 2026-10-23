import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Ships hidden: retention rules are not confirmed yet (BACKEND_REQUESTS "Account deletion").
/// Enable with `--dart-define=ACCOUNT_DELETION=true`; tests override this provider.
final accountDeletionEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('ACCOUNT_DELETION'),
);

enum DeletionStatus { none, requested, completed }

class DeletionRequest {
  const DeletionRequest(this.status, [this.requestedAt]);
  final DeletionStatus status;
  final DateTime? requestedAt;

  /// `DeletionRequestView`; `GET` returns an empty body or a CANCELLED row when nothing is open.
  factory DeletionRequest.parse(Object? body) {
    if (body is! Map) return const DeletionRequest(DeletionStatus.none);
    final at = DateTime.tryParse('${body['requestedAt']}')?.toLocal();
    return switch (body['status']) {
      'REQUESTED' => DeletionRequest(DeletionStatus.requested, at),
      'COMPLETED' => DeletionRequest(DeletionStatus.completed, at),
      _ => const DeletionRequest(DeletionStatus.none),
    };
  }
}

final deletionRequestProvider = FutureProvider.autoDispose<DeletionRequest>((
  ref,
) async {
  final res = await guarded(
    () => ref.read(dioProvider).get<dynamic>('/me/deletion-request'),
  );
  return DeletionRequest.parse(res.data);
});

Future<void> requestAccountDeletion(WidgetRef ref) async {
  await guarded(
    () => ref.read(dioProvider).post<dynamic>('/me/deletion-request', data: {}),
  );
  ref.invalidate(deletionRequestProvider);
}

Future<void> cancelAccountDeletion(WidgetRef ref) async {
  await guarded(
    () => ref.read(dioProvider).delete<dynamic>('/me/deletion-request'),
  );
  ref.invalidate(deletionRequestProvider);
}

/// Status of the customer's deletion request, with Cancel while it is still open.
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _State();
}

class _State extends ConsumerState<AccountDeletionScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _cancel() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await cancelAccountDeletion(ref);
    } on Object {
      _failed = true;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(deletionRequestProvider);
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.deleteStatusTitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: req.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    key: const Key('deletion_retry_btn'),
                    onPressed: () => ref.invalidate(deletionRequestProvider),
                    child: Text(l10n.deleteFailed),
                  ),
                ),
                data: (r) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key: const Key('deletion_status_text'),
                      switch (r.status) {
                        DeletionStatus.none => l10n.deleteStatusNone,
                        DeletionStatus.completed => l10n.deleteStatusCompleted,
                        DeletionStatus.requested => l10n.deleteStatusRequested(
                          r.requestedAt == null
                              ? ''
                              : DateFormat.yMMMd().format(r.requestedAt!),
                        ),
                      },
                    ),
                    if (_failed) Text(l10n.deleteFailed),
                    if (r.status == DeletionStatus.requested) ...[
                      const SizedBox(height: 16),
                      SnButton(
                        key: const Key('deletion_cancel_btn'),
                        label: l10n.deleteCancelRequest,
                        isLoading: _busy,
                        onPressed: _cancel,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
