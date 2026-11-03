import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/interview_trial/presentation/widgets/interview_detail_parts.dart'
    show DashedRule;
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart'
    show showGlassSheet;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Accent of a card (design: teal Home, blue Parents' home, amber Office), cycled by position.
typedef _Accent = ({Color bar, Color icon, Color tile, IconData glyph});

const List<_Accent> _accents = [
  (
    bar: Color(0xFF0F766E),
    icon: Color(0xFF0F766E),
    tile: Color(0xFFE2EEEC),
    glyph: Icons.home_outlined,
  ),
  (
    bar: Color(0xFF2563EB),
    icon: Color(0xFF1E40AF),
    tile: Color(0xFFDBEAFE),
    glyph: Icons.home_outlined,
  ),
  (
    bar: Color(0xFFF59E0B),
    icon: Color(0xFF8A4B06),
    tile: Color(0xFFFEF3C7),
    glyph: Icons.apartment_outlined,
  ),
];

const _danger = Color(0xFFBE123C);

/// Frosted address card: coloured edge, icon tile, serif label with the Default pill, full
/// address, and a kebab that opens [onMenu].
class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.index,
    required this.onTap,
    required this.onMenu,
    super.key,
  });

  final Address address;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = address.id;
    final a = _accents[index % _accents.length];
    final detail = [
      address.fullLine,
      address.area,
      '${address.city} ${address.pincode}'.trim(),
    ].where((s) => s.isNotEmpty && s != address.title).join(', ');
    return DiscoverGlass(
      radius: 24,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('address_card_$id'),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: a.bar,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: a.tile,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(a.glyph, size: 22, color: a.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(address.title, style: authSerif(19, 1.25)),
                              if (address.isDefault)
                                Container(
                                  key: Key('address_default_tag_$id'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6EFEA),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    l10n.defaultTag,
                                    style: AppText.body.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B5A53),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            detail,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 14,
                              height: 1.45,
                              color: dsText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('address_menu_$id'),
                      tooltip: l10n.addressMenu,
                      onPressed: onMenu,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 22,
                        color: dsMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AddressAction { setDefault, edit, delete }

/// The card's options sheet: Set as default (hidden for the default), Edit, Delete.
Future<AddressAction?> showAddressActions(
  BuildContext context,
  Address address,
) {
  final l10n = AppLocalizations.of(context);
  final id = address.id;
  Widget option(AddressAction a, Key key, IconData icon, String label) {
    final danger = a == AddressAction.delete;
    return InkWell(
      key: key,
      onTap: () => Navigator.of(context).pop(a),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 6),
            Icon(icon, size: 20, color: danger ? _danger : AppColors.teal),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: danger ? _danger : dsNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showGlassSheet<AddressAction>(
    context,
    builder: (_) => Semantics(
      label: l10n.addressMenu,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!address.isDefault) ...[
            option(
              AddressAction.setDefault,
              Key('address_set_default_$id'),
              Icons.check_rounded,
              l10n.setAsDefault,
            ),
            const DashedRule(),
          ],
          option(
            AddressAction.edit,
            Key('address_edit_$id'),
            Icons.edit_outlined,
            l10n.edit,
          ),
          const DashedRule(),
          option(
            AddressAction.delete,
            Key('address_menu_delete_$id'),
            Icons.delete_outline_rounded,
            l10n.delete,
          ),
        ],
      ),
    ),
  );
}
