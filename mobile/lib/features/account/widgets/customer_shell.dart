import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/portal_widgets.dart';

/// Five real destinations, each its own branch — no drawer-opening special
/// case. "More" is a full screen (see `CustomerMoreScreen`), not a
/// slide-out drawer, so everything the web keeps in its sidebar (Wallet,
/// Addresses, Resell, Support, FAQs, About) has a direct tab rather than
/// living behind the avatar.
const shellDestinations = <ShellDestination>[
  ShellDestination(icon: LucideIcons.layoutGrid, label: 'Account'),
  ShellDestination(icon: LucideIcons.shoppingBag, label: 'Orders'),
  ShellDestination(icon: LucideIcons.frame, label: 'Collection'),
  ShellDestination(icon: LucideIcons.heart, label: 'Saved'),
  ShellDestination(icon: LucideIcons.menu, label: 'More'),
];

/// The customer's root shell. Branch state (scroll position, selected tab)
/// survives resize because `StatefulShellRoute.indexedStack` keeps each
/// branch's navigator alive — the navigation *surface* swaps by width, the
/// content does not rebuild from scratch.
///
/// - compact (<600): bottom `NavigationBar`
/// - medium (600-839): `NavigationRail`, icons + labels
/// - expanded (>=840): extended `NavigationRail`
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab returns to that branch's first route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);

    if (size.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final destination in shellDestinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            extended: size.isExpanded,
            labelType: size.isExpanded ? null : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                size.isExpanded ? 'GALLERYZONE' : 'GZ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: 2,
                    ),
              ),
            ),
            destinations: [
              for (final destination in shellDestinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
