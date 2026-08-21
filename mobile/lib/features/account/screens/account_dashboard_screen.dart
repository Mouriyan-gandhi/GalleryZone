import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/login_screen.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../../marketing/screens/about_screen.dart';
import '../providers/account_providers.dart';
import '../widgets/order_widgets.dart';

/// Port of `features/account/collector-dashboard.tsx`, plus the entry points
/// the web keeps in its sidebar (wallet, resale, addresses, profile,
/// support) — on mobile those live here rather than in a nine-item tab bar.
class AccountDashboardScreen extends ConsumerWidget {
  const AccountDashboardScreen({super.key});

  static const path = '/account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(customerProfileProvider).value;
    final orders = ref.watch(ordersProvider).value;
    final collection = ref.watch(collectionProvider).value;
    final wallet = ref.watch(walletProvider).value;
    final wishlistCount = ref.watch(wishlistProvider).length;
    final artworks = ref.watch(artworksByIdProvider).value ?? const {};

    final stats = <({String label, String value, IconData icon})>[
      (label: 'Orders placed', value: '${orders?.length ?? 0}', icon: LucideIcons.shoppingBag),
      (label: 'Artworks owned', value: '${collection?.length ?? 0}', icon: LucideIcons.frame),
      (label: 'Wishlist', value: '$wishlistCount', icon: LucideIcons.heart),
      (
        label: 'Store credit',
        value: formatInr(wallet?.balance ?? 0),
        icon: LucideIcons.wallet,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).signOut();
              if (context.mounted) context.go(LoginScreen.path);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          ref.invalidate(collectionProvider);
          ref.invalidate(walletProvider);
          await ref.read(ordersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back, ${(profile?.name ?? 'there').split(' ').first}',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's a snapshot of your GalleryZone activity.",
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  // Two stat cards per row on a phone, four across once
                  // there's room — the grid reflows, it isn't duplicated.
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: WindowSize.of(context).isCompact ? 2 : 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      for (final stat in stats)
                        _StatCard(label: stat.label, value: stat.value, icon: stat.icon),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _DiscoverBanner(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent orders', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/account/orders'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (orders == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (orders.isEmpty)
                    Text(
                      'No orders yet — your purchases will show up here.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final order in orders.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderRow(order: order, artwork: artworks[order.artworkId]),
                      ),
                  const SizedBox(height: 20),
                  Text('Manage', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const _ManageTile(
                    icon: LucideIcons.wallet,
                    label: 'Wallet',
                    subtitle: 'Store credit and refunds',
                    route: '/account/wallet',
                  ),
                  const _ManageTile(
                    icon: LucideIcons.repeat2,
                    label: 'Resell artwork',
                    subtitle: 'List a piece from your collection',
                    route: '/account/resale',
                  ),
                  const _ManageTile(
                    icon: LucideIcons.mapPin,
                    label: 'Addresses',
                    subtitle: 'Delivery address book',
                    route: '/account/addresses',
                  ),
                  const _ManageTile(
                    icon: LucideIcons.circleUserRound,
                    label: 'Profile',
                    subtitle: 'Name, email and phone',
                    route: '/account/settings',
                  ),
                  const _ManageTile(
                    icon: LucideIcons.lifeBuoy,
                    label: 'Support',
                    subtitle: 'FAQs and tickets',
                    route: '/account/support',
                  ),
                  const _ManageTile(
                    icon: LucideIcons.info,
                    label: 'About & legal',
                    subtitle: 'The company, terms and privacy',
                    route: AboutScreen.path,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Icon(icon, size: 15, color: theme.colorScheme.tertiary),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverBanner extends StatelessWidget {
  const _DiscoverBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/marketplace'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.compass, size: 20, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover more artworks',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Browse original work from independent artists across India.',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.arrowRight, size: 16, color: theme.colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: theme.colorScheme.tertiary),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.push(route),
    );
  }
}
