import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/core/network/guarded.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// What the consent step needs: the versions to send and the documents to show.
class LegalState {
  const LegalState({
    required this.needsAcceptance,
    this.termsVersion,
    this.privacyVersion,
    this.termsUrl,
    this.privacyUrl,
  });

  final bool needsAcceptance;
  final String? termsVersion;
  final String? privacyVersion;
  final String? termsUrl;
  final String? privacyUrl;

  /// Null versions mean a document is not published, so there is nothing to accept yet.
  bool get publishable => termsVersion != null && privacyVersion != null;
}

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// `GET /app-config` (`legal.*.version/url`, `legal.acceptanceRequired`) + `GET /legal/status`
/// (`accepted`). Mock mode never asks.
final legalStateProvider = FutureProvider.autoDispose<LegalState>((ref) async {
  if (!ref.watch(mockApiProvider.select((s) => s.live))) {
    return const LegalState(needsAcceptance: false);
  }
  final dio = ref.read(dioProvider);
  final cfg = (await guarded(() => dio.get<dynamic>('/app-config'))).data;
  final legal = cfg is Map ? cfg['legal'] : null;
  final required = legal is Map && legal['acceptanceRequired'] == true;
  if (!required) return const LegalState(needsAcceptance: false);
  final status = (await guarded(() => dio.get<dynamic>('/legal/status'))).data;
  final accepted = status is Map && status['accepted'] == true;
  String? field(String k, String f) {
    final d = legal[k];
    return d is Map ? _str(d[f]) : null;
  }

  return LegalState(
    needsAcceptance: !accepted,
    termsVersion: field('terms', 'version'),
    privacyVersion: field('privacy', 'version'),
    termsUrl: field('terms', 'url'),
    privacyUrl: field('privacy', 'url'),
  );
});

Future<void> _accept(Ref ref, LegalState s) => guarded(
  () => ref
      .read(dioProvider)
      .post<dynamic>(
        '/legal/accept',
        data: {
          'termsVersion': s.termsVersion,
          'privacyVersion': s.privacyVersion,
        },
      ),
);

/// Resolves true once the current terms are accepted, showing the consent dialog when needed.
/// A failed status read lets the caller through; the server still enforces consent.
final legalConsentProvider = Provider<Future<bool> Function(BuildContext)>((
  ref,
) {
  return (context) async {
    final LegalState s;
    try {
      s = await ref.read(legalStateProvider.future);
    } on Object {
      return true;
    }
    if (!s.needsAcceptance) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConsentDialog(state: s, accept: () => _accept(ref, s)),
    );
    if (ok == true) ref.invalidate(legalStateProvider);
    return ok ?? false;
  };
});

class _ConsentDialog extends ConsumerStatefulWidget {
  const _ConsentDialog({required this.state, required this.accept});
  final LegalState state;
  final Future<void> Function() accept;

  @override
  ConsumerState<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends ConsumerState<_ConsentDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.accept();
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  Widget _link(String label, String? url) => TextButton(
    onPressed: url == null
        ? null
        : () => ref.read(openInAppBrowserProvider)(url),
    child: Text(label),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.state;
    return AlertDialog(
      key: const Key('legal_consent_dialog'),
      title: Text(l10n.legalConsentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.publishable
                ? l10n.legalConsentBody
                : l10n.legalConsentUnavailable,
          ),
          if (s.publishable) ...[
            _link(l10n.accountTerms, s.termsUrl),
            _link(l10n.accountPrivacy, s.privacyUrl),
          ],
          if (_failed)
            Text(
              l10n.legalConsentFailed,
              key: const Key('legal_consent_error'),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('legal_consent_cancel_btn'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        SnButton(
          key: const Key('legal_consent_accept_btn'),
          label: l10n.legalConsentAccept,
          isLoading: _busy,
          onPressed: s.publishable ? _submit : null,
        ),
      ],
    );
  }
}
