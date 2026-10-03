import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth.dart';
import '../../shell/portal_menu.dart';
import '../../shell/portal_widgets.dart';

/// Four primary destinations. The web's fifteen-item grouped sidebar
/// collapses here: orders, customers, shipping, gallery spaces, settlements,
/// analytics, messages, profile, settings and support are reached from the
/// dashboard's "Manage" list.
///
/// "Browse" and "Inventory" are the web's "Browse GalleryZone" and "My
/// Inventory" — what's available to reserve, and what's currently held.
const aggregatorDestinations = <ShellDestination>[
  ShellDestination(icon: LucideIcons.layoutGrid, label: 'Dashboard'),
  ShellDestination(icon: LucideIcons.packageSearch, label: 'Browse'),
  ShellDestination(icon: LucideIcons.galleryVerticalEnd, label: 'Inventory'),
  ShellDestination(icon: LucideIcons.wallet, label: 'Wallet'),
];

/// Same adaptive structure as `CustomerShell` and `ArtistShell` — bottom bar
/// under 600, rail from 600, extended rail from 840. Deliberately a third
/// file rather than a shared `RoleShell<T>`: the three shells have no common
/// state, destinations or behavior beyond Material's navigation pattern, and
/// a type parameterised over all three would be a wrapper with one real
/// decision inside it.
class AggregatorShell extends ConsumerWidget {
  const AggregatorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);
    final menu = portalMenuFor(Role.aggregator);
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
            onDestinationSelected: (index) => index == aggregatorDestinations.length
                ? Scaffold.of(context).openEndDrawer()
                : _goBranch(index),
            destinations: [
              for (final destination in [...aggregatorDestinations, profileDestination])
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
            onDestinationSelected: (index) => index == aggregatorDestinations.length
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
              for (final destination in [...aggregatorDestinations, profileDestination])
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
