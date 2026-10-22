import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_nav.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Bottom navigation shell (modules/03). Tab set is final pending design (OPEN_QUESTIONS #21).
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Back on a non-Home tab goes to Home; back on Home exits (HOME-09).
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: SnBottomNav(
          selectedIndex: navigationShell.currentIndex,
          onSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          items: [
            SnNavItem(
              key: const Key('nav_home'),
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n.navHome,
            ),
            SnNavItem(
              key: const Key('nav_bookings'),
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: l10n.navBookings,
            ),
            SnNavItem(
              key: const Key('nav_favourites'),
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
              label: l10n.navFavourites,
            ),
            SnNavItem(
              key: const Key('nav_account'),
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: l10n.navAccount,
            ),
          ],
        ),
      ),
    );
  }
}
