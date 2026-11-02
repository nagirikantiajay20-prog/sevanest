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
    this.showLabel = false,
    super.key,
  });

  final String workerId;

  /// Text button ("Shortlist") for the profile's sticky bar instead of the bare heart.
  final bool showLabel;

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

    if (showLabel) {
      // Frosted pill of the profile's bottom bar; turns rose once shortlisted.
      return OutlinedButton.icon(
        key: Key(keyName),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: isFav
              ? const Color(0xFFFFE4EA)
              : const Color(0xCCFFFFFF),
          foregroundColor: isFav ? const Color(0xFF9F1239) : AppColors.navyDeep,
          side: BorderSide(
            color: isFav
                ? const Color(0x80E11D48)
                : AppColors.navyDeep.withValues(alpha: 0.22),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: s == null || busy ? null : tap,
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? const Color(0xFFE11D48) : null,
        ),
        label: Text(isFav ? l10n.workerShortlisted : l10n.workerShortlist),
      );
    }

    // Frosted round heart of the glass cards; rose and filled once saved.
    return IconButton(
      key: Key(keyName),
      tooltip: isFav ? l10n.favouriteRemove : l10n.favouriteAdd,
      isSelected: isFav,
      onPressed: s == null || busy ? null : tap,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: const Color(0xD9FFFFFF),
        side: const BorderSide(color: Color(0xF2FFFFFF)),
      ),
      icon: const Icon(Icons.favorite_border, color: AppColors.navyDeep),
      selectedIcon: const Icon(Icons.favorite, color: Color(0xFFE11D48)),
    );
  }
}
