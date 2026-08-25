import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock/seed/aggregator_seed.dart' show currentAggregatorName;
import '../../data/mock/seed/artist_seed.dart' show currentArtistName;
import '../../data/models/auth.dart';
import '../account/providers/account_providers.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/role_options.dart';
import '../auth/screens/login_screen.dart';
import '../legal/screens/faq_screen.dart';
import '../marketing/screens/about_screen.dart';
import 'portal_widgets.dart';

/// One row of a portal's menu. Same four fields the three dashboards each
/// carried privately as a "Manage" list — they live here now because the
/// list is a navigation surface, not page content, and a page you have to
/// scroll to the bottom of is not a menu.
class PortalMenuItem {
  const PortalMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
}

/// A titled block of rows. The title is what tells someone which of four
/// plausible places a setting lives in before they have opened any of them —
/// an eleven-row list separated only by hairlines does not.
class PortalMenuSection {
  const PortalMenuSection({required this.title, required this.items});

  final String title;
  final List<PortalMenuItem> items;
}

typedef PortalMenuGroups = List<PortalMenuSection>;

/// The rows every portal ends with. Support, the FAQs and the About/legal hub
/// are the same three destinations for a collector, an artist and an
/// aggregator, so they are written once — only Support's route differs.
List<PortalMenuItem> _helpSection(String supportRoute) => [
      PortalMenuItem(
        icon: LucideIcons.lifeBuoy,
        label: 'Support',
        subtitle: 'Raise a ticket, or read your open ones',
        route: supportRoute,
      ),
      const PortalMenuItem(
        icon: LucideIcons.circleHelp,
        label: 'FAQs',
        subtitle: 'Buying, selling, authenticity and delivery',
        route: FaqScreen.path,
      ),
      const PortalMenuItem(
        icon: LucideIcons.info,
        label: 'About & legal',
        subtitle: 'The company, terms, privacy and cookies',
        route: AboutScreen.path,
      ),
    ];

final customerMenu = <PortalMenuSection>[
  const PortalMenuSection(
    title: 'Account',
    items: [
      PortalMenuItem(
        icon: LucideIcons.circleUserRound,
        label: 'Profile',
        subtitle: 'Name, email and phone',
        route: '/account/settings',
      ),
      PortalMenuItem(
        icon: LucideIcons.mapPin,
        label: 'Addresses',
        subtitle: 'Delivery address book',
        route: '/account/addresses',
      ),
      PortalMenuItem(
        icon: LucideIcons.wallet,
        label: 'Wallet',
        subtitle: 'Store credit and refunds',
        route: '/account/wallet',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Selling',
    items: [
      PortalMenuItem(
        icon: LucideIcons.repeat2,
        label: 'Resell artwork',
        subtitle: 'List a piece from your collection',
        route: '/account/resale',
      ),
    ],
  ),
  PortalMenuSection(title: 'Help & legal', items: _helpSection('/account/support')),
];

final artistMenu = <PortalMenuSection>[
  const PortalMenuSection(
    title: 'Account',
    items: [
      PortalMenuItem(
        icon: LucideIcons.circleUserRound,
        label: 'Profile & KYC',
        subtitle: 'Identity, bio and bank details',
        route: '/dashboard/profile',
      ),
      PortalMenuItem(
        icon: LucideIcons.badgeCheck,
        label: 'Verification',
        subtitle: 'Progress to Gold Verified',
        route: '/dashboard/verification',
      ),
      PortalMenuItem(
        icon: LucideIcons.mail,
        label: 'Messages',
        subtitle: 'Notices from GalleryZone',
        route: '/dashboard/messages',
      ),
      PortalMenuItem(
        icon: LucideIcons.settings,
        label: 'Settings',
        subtitle: 'Notification preferences',
        route: '/dashboard/settings',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'My work',
    items: [
      PortalMenuItem(
        icon: LucideIcons.images,
        label: 'Portfolio',
        subtitle: 'What buyers see of your work',
        route: '/dashboard/portfolio',
      ),
      PortalMenuItem(
        icon: LucideIcons.frame,
        label: 'Aggregator Display',
        subtitle: 'Pieces placed with aggregators',
        route: '/dashboard/gallery-spaces',
      ),
      PortalMenuItem(
        icon: LucideIcons.fingerprint,
        label: 'COA & NFC',
        subtitle: 'Certificates and physical tags',
        route: '/dashboard/coa-nfc',
      ),
      PortalMenuItem(
        icon: LucideIcons.users,
        label: 'Connections',
        subtitle: 'Other artists, and joint work',
        route: '/dashboard/network',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Money',
    items: [
      PortalMenuItem(
        icon: LucideIcons.receipt,
        label: 'Settlements',
        subtitle: 'Payout records per sale',
        route: '/dashboard/settlements',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Agreements',
    items: [
      PortalMenuItem(
        icon: LucideIcons.fileText,
        label: 'Artist MOU',
        subtitle: 'Your signed agreement with GalleryZone',
        route: '/dashboard/mou',
      ),
      PortalMenuItem(
        icon: LucideIcons.scale,
        label: 'Artist Terms & Conditions',
        subtitle: 'Listing, verification, pricing and settlement',
        route: '/legal/artist-terms',
      ),
    ],
  ),
  PortalMenuSection(title: 'Help & legal', items: _helpSection('/dashboard/support')),
];

final aggregatorMenu = <PortalMenuSection>[
  const PortalMenuSection(
    title: 'Account',
    items: [
      PortalMenuItem(
        icon: LucideIcons.circleUserRound,
        label: 'Company profile',
        subtitle: 'GST, contact and bank details',
        route: '/aggregator/dashboard/profile',
      ),
      PortalMenuItem(
        icon: LucideIcons.fileSignature,
        label: 'Aggregator MOU',
        subtitle: 'Sign before reserving artwork',
        route: '/aggregator/dashboard/mou',
      ),
      PortalMenuItem(
        icon: LucideIcons.mail,
        label: 'Messages',
        subtitle: 'Notices from GalleryZone',
        route: '/aggregator/dashboard/messages',
      ),
      PortalMenuItem(
        icon: LucideIcons.settings,
        label: 'Settings',
        subtitle: 'Notification preferences',
        route: '/aggregator/dashboard/settings',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Operations',
    items: [
      PortalMenuItem(
        icon: LucideIcons.shoppingBag,
        label: 'Orders & sales',
        subtitle: 'What you have sold, and to whom',
        route: '/aggregator/dashboard/orders',
      ),
      PortalMenuItem(
        icon: LucideIcons.users,
        label: 'Customers',
        subtitle: 'Buyers from your recorded sales',
        route: '/aggregator/dashboard/customers',
      ),
      PortalMenuItem(
        icon: LucideIcons.truck,
        label: 'Shipping & logistics',
        subtitle: 'Inbound pieces and outbound deliveries',
        route: '/aggregator/dashboard/shipping',
      ),
      PortalMenuItem(
        icon: LucideIcons.building2,
        label: 'Display Spaces',
        subtitle: 'Your premises and their occupancy',
        route: '/aggregator/dashboard/gallery-spaces',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Money',
    items: [
      PortalMenuItem(
        icon: LucideIcons.landmark,
        label: 'Settlements',
        subtitle: 'Commission records per sale',
        route: '/aggregator/dashboard/settlements',
      ),
    ],
  ),
  const PortalMenuSection(
    title: 'Agreements',
    items: [
      PortalMenuItem(
        icon: LucideIcons.scale,
        label: 'Aggregator Terms & Conditions',
        subtitle: 'Display, custody, commission and returns',
        route: '/legal/aggregator-terms',
      ),
    ],
  ),
  PortalMenuSection(
    title: 'Help & legal',
    items: _helpSection('/aggregator/dashboard/support'),
  ),
];

/// Which menu a role gets, and what the drawer header calls it. Held here so
/// the shells and the dashboards cannot disagree about it.
({String roleLabel, PortalMenuGroups groups, String homeRoute}) portalMenuFor(Role role) =>
    switch (role) {
      Role.customer => (
          roleLabel: 'Collector',
          groups: customerMenu,
          homeRoute: Role.customer.home,
        ),
      Role.artist => (
          roleLabel: 'Artist',
          groups: artistMenu,
          homeRoute: Role.artist.home,
        ),
      Role.aggregator => (
          roleLabel: 'Aggregator',
          groups: aggregatorMenu,
          homeRoute: Role.aggregator.home,
        ),
    };

/// The name shown on the avatar and at the top of the menu.
///
/// Artist and aggregator are fixtures — there is no real session, so there is
/// nothing else to read. The collector's name is the one field of the three a
/// user can actually edit, so it comes from the profile they saved rather
/// than from the seed it started as.
final portalDisplayNameProvider = Provider<String>((ref) {
  return switch (ref.watch(sessionProvider)) {
    Role.artist => currentArtistName,
    Role.aggregator => currentAggregatorName,
    Role.customer => ref.watch(customerProfileProvider).value?.name ?? 'Collector',
    null => 'GalleryZone',
  };
});

/// The last item in every portal's bottom bar and rail. It is not a branch:
/// selecting it opens the menu over whatever screen you were on, which is why
/// each shell handles it separately from `goBranch`.
const profileDestination = ShellDestination(
  icon: LucideIcons.circleUserRound,
  label: 'Profile',
);

/// Initials for the avatar. Two words give two letters, one gives one — no
/// third letter, which is what turns a monogram back into a word.
String portalInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  final letters = words.length == 1 ? [words.first] : [words.first, words.last];
  return letters.map((word) => word[0].toUpperCase()).join();
}

/// The top-right avatar. Opens the portal menu as an end drawer, so the host
/// screen's `Scaffold` is the one that has to carry [PortalMenuDrawer].
class PortalAvatarButton extends StatelessWidget {
  const PortalAvatarButton({super.key, required this.name, this.badgeCount = 0});

  final String name;

  /// Unread notices. The count used to sit on the dashboard's own Messages
  /// row; that row moved into the drawer, so the number moves onto the thing
  /// that opens the drawer — otherwise it is only visible once you already
  /// went looking.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Text(
        portalInitials(name),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: 'Menu',
        onPressed: () => Scaffold.of(context).openEndDrawer(),
        icon: badgeCount > 0
            ? Badge(label: Text('$badgeCount'), child: avatar)
            : avatar,
      ),
    );
  }
}

/// Everything a portal holds that is not one of its four bottom-bar tabs,
/// behind the avatar rather than at the bottom of the dashboard.
class PortalMenuDrawer extends ConsumerWidget {
  const PortalMenuDrawer({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.groups,
    this.homeRoute,
  });

  final String name;
  final String roleLabel;
  final PortalMenuGroups groups;

  /// Drawn as the first row when given — the portal's own home, matching the
  /// "Home" entry at the top of the reference menus. It only closes the
  /// drawer, because the drawer opens from that screen.
  final String? homeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(name: name, roleLabel: roleLabel),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (homeRoute != null)
                    _MenuRow(
                      item: PortalMenuItem(
                        icon: LucideIcons.house,
                        label: 'Home',
                        subtitle: 'Your $roleLabel dashboard',
                        route: homeRoute!,
                      ),
                      closeOnly: true,
                    ),
                  for (final (index, section) in groups.indexed) ...[
                    if (index > 0 || homeRoute != null)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        section.title.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    for (final item in section.items) _MenuRow(item: item),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(LucideIcons.logOut, size: 20, color: theme.colorScheme.error),
              title: Text(
                'Sign out',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
              onTap: () async {
                final router = GoRouter.of(context);
                await ref.read(sessionProvider.notifier).signOut();
                router.go(LoginScreen.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.roleLabel});

  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              portalInitials(name),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, this.closeOnly = false});

  final PortalMenuItem item;
  final bool closeOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(item.icon, size: 20, color: theme.colorScheme.tertiary),
      title: Text(item.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(item.subtitle, style: theme.textTheme.labelSmall),
      trailing: closeOnly ? null : const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        // Close first: the drawer belongs to the screen being left, and
        // popping it after the push animates the wrong route out.
        Navigator.of(context).pop();
        if (!closeOnly) context.push(item.route);
      },
    );
  }
}
