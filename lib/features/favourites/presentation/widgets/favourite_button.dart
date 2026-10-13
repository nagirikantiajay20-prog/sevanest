import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/favourites/presentation/providers/favourites_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// The heart. Flips at once, is disabled while its request runs, and rolls back with a snackbar
/// when the server says no (AGENTS §28). [onChanged] gets the new state after a successful change.
class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({
    required this.workerId,
    required this.keyName,
    this.onChanged,
    super.key,
  });

  final String workerId;

  /// e.g. `worker_card_fav_btn_<id>` or `worker_detail_fav_btn`.
  final String keyName;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(favouriteProvider).value;
    final isFav = s?.ids.contains(workerId) ?? false;
    final busy = s?.pending.contains(workerId) ?? false;

    Future<void> tap() async {
      // Taken before the await: the card may be gone by the time the server answers (a removed
      // shortlist row), but the message and the parent's callback still apply.
      final messenger = ScaffoldMessenger.of(context);
      final ok = await ref.read(favouriteProvider.notifier).toggle(workerId);
      if (ok) {
        onChanged?.call(!isFav);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.favouriteFailed)));
      }
    }

    return IconButton(
      key: Key(keyName),
      tooltip: isFav ? l10n.favouriteRemove : l10n.favouriteAdd,
      isSelected: isFav,
      onPressed: s == null || busy ? null : tap,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: const Icon(Icons.favorite, color: AppColors.danger),
    );
  }
}
