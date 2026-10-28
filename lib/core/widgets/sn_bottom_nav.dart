import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

class SnNavItem {
  const SnNavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final Key key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom navigation in the design style (teal selected, soft pill, hairline top edge). Takes any
/// number of items: the design shows five (adds Services) while the app has four today.
class SnBottomNav extends StatelessWidget {
  const SnBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<SnNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: const Border(top: BorderSide(color: AppColors.hairline)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        height: 68,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final i in items)
            NavigationDestination(
              key: i.key,
              icon: Icon(i.icon),
              selectedIcon: Icon(i.selectedIcon),
              label: i.label,
            ),
        ],
      ),
    );
  }
}
