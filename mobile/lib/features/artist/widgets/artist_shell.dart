import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../shell/portal_widgets.dart';

/// Four primary destinations, shared by both navigation surfaces. The web's
/// fifteen-item grouped sidebar collapses here: everything else (analytics,
/// COA/NFC, gallery spaces, portfolio, profile, settings, settlements,
/// support, verification) is reached from the dashboard's "Manage" list.
const artistDestinations = <ShellDestination>[
  ShellDestination(icon: LucideIcons.layoutGrid, label: 'Dashboard'),
  ShellDestination(icon: LucideIcons.frame, label: 'Artworks'),
  ShellDestination(icon: LucideIcons.shoppingBag, label: 'Orders'),
  ShellDestination(icon: LucideIcons.wallet, label: 'Wallet'),
];

/// Same adaptive structure as `CustomerShell` — bottom bar under 600, rail
/// from 600, extended rail from 840 — deliberately duplicated rather than
/// abstracted: the two shells share no state, no destinations and no
/// behavior beyond "Material's navigation pattern", and a `RoleShell<T>`
/// parameterised over both would be a wrapper with one real decision in it.
class ArtistShell extends StatelessWidget {
  const ArtistShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);

    if (size.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final destination in artistDestinations)
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
              for (final destination in artistDestinations)
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
