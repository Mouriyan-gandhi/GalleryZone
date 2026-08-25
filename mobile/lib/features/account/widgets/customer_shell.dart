import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth.dart';
import '../../shell/portal_menu.dart';
import '../../shell/portal_widgets.dart';

const shellDestinations = <ShellDestination>[
  ShellDestination(icon: LucideIcons.layoutGrid, label: 'Account'),
  ShellDestination(icon: LucideIcons.shoppingBag, label: 'Orders'),
  ShellDestination(icon: LucideIcons.frame, label: 'Collection'),
  ShellDestination(icon: LucideIcons.heart, label: 'Saved'),
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
    final menu = portalMenuFor(Role.customer);
    final drawer = PortalMenuDrawer(
      name: ref.watch(portalDisplayNameProvider),
      roleLabel: menu.roleLabel,
      groups: menu.groups,
    );

    if (size.isCompact) {
      return Scaffold(
        endDrawer: drawer,
        body: navigationShell,
        // The Builder is what puts `Scaffold.of` below this Scaffold, so the
        // Profile destination can open the drawer this one owns.
        bottomNavigationBar: Builder(
          builder: (context) => NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => index == shellDestinations.length
                ? Scaffold.of(context).openEndDrawer()
                : _goBranch(index),
            destinations: [
              for (final destination in [...shellDestinations, profileDestination])
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      endDrawer: drawer,
      body: Builder(
        builder: (context) => Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => index == shellDestinations.length
                ? Scaffold.of(context).openEndDrawer()
                : _goBranch(index),
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
              for (final destination in [...shellDestinations, profileDestination])
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
      ),
    );
  }
}
