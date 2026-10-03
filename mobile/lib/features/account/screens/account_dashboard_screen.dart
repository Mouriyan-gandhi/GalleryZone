import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../providers/account_providers.dart';
import '../widgets/order_widgets.dart';

/// Port of `features/account/collector-dashboard.tsx`, plus the entry points
/// the web keeps in its sidebar (wallet, resale, addresses, profile,
/// support) — on mobile those live in the More tab rather than in a nine-item
/// tab bar.
class AccountDashboardScreen extends ConsumerWidget {
  const AccountDashboardScreen({super.key});

  static const path = '/account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(customerProfileProvider).value;
    final ordersState = ref.watch(ordersProvider);
    final orders = ordersState.value;
    final collection = ref.watch(collectionProvider).value;
    final listings = ref.watch(resaleListingsProvider).value;
    final wishlistCount = ref.watch(wishlistProvider).length;
    final recent = [...?orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          ref.invalidate(collectionProvider);
          ref.invalidate(customerProfileProvider);
          ref.invalidate(resaleListingsProvider);
          await ref.read(ordersProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  CollectorProfileCard(
                    profile: profile,
                    stats: orders == null || collection == null
                        ? null
                        : CollectorStats.of(
                            orders: orders,
                            collection: collection,
                            wishlisted: wishlistCount,
                            listedForResale: listings
                                    ?.where((l) => l.status == ResaleListingStatus.active)
                                    .length ??
                                0,
                          ),
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
                  if (ordersState.hasError && orders == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Couldn't load your orders.", style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: () => ref.invalidate(ordersProvider),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  else if (orders == null)
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
                    for (final order in recent.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderRow(order: order),
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

/// Who this collector is, in figures - derived on read from the orders and the
/// collection, so a number cannot disagree with the page it links to.
class CollectorStats {
  const CollectorStats({
    required this.worksOwned,
    required this.ordersPlaced,
    required this.inProgress,
    required this.totalSpent,
    required this.wishlisted,
    required this.listedForResale,
    required this.artistsCollected,
  });

  factory CollectorStats.of({
    required List<Order> orders,
    required List<CollectionItem> collection,
    required int wishlisted,
    required int listedForResale,
  }) {
    // An order that never got past "pending" was abandoned at payment.
    final placed = orders.where((o) => o.status != OrderStatus.pending);
    final counts = <String, int>{};
    for (final item in collection) {
      counts[item.artwork.artistName] = (counts[item.artwork.artistName] ?? 0) + 1;
    }
    final repeat = counts.entries.where((e) => e.value > 1).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return CollectorStats(
      worksOwned: collection.length,
      ordersPlaced: placed.length,
      inProgress: placed
          .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
          .length,
      totalSpent: placed.where((o) => o.status != OrderStatus.cancelled).fold(0.0, (sum, o) => sum + o.total),
      wishlisted: wishlisted,
      listedForResale: listedForResale,
      artistsCollected: [for (final e in repeat) e.key],
    );
  }

  final int worksOwned;
  final int ordersPlaced;
  final int inProgress;
  final double totalSpent;
  final int wishlisted;
  final int listedForResale;

  /// Artists the collector has bought more than once, most-collected first.
  final List<String> artistsCollected;
}

/// Port of `collector-profile-card.tsx`: the first thing a collector sees is
/// what they own, not a list of settings.
class CollectorProfileCard extends StatelessWidget {
  const CollectorProfileCard({super.key, required this.profile, required this.stats});

  final CustomerProfile? profile;
  final CollectorStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = stats;
    final since = DateTime.tryParse(profile?.joinedAt ?? '');

    if (data == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      );
    }

    final cells = [
      (LucideIcons.frame, 'Works owned', '${data.worksOwned}'),
      (LucideIcons.shoppingBag, 'Orders placed', '${data.ordersPlaced}'),
      (LucideIcons.truck, 'On the way', '${data.inProgress}'),
      (LucideIcons.wallet, 'Total spent', formatInr(data.totalSpent)),
      (LucideIcons.heart, 'Wishlisted', '${data.wishlisted}'),
      (LucideIcons.tag, 'Listed for resale', '${data.listedForResale}'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile?.name ?? '',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (since != null)
            Text(
              'Collecting since ${DateFormat('MMMM y').format(since.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (icon, label, value) in cells)
                    SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          // One purchase is a purchase; two from the same artist is a taste,
          // and worth telling someone about their own collection.
          if (data.artistsCollected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'You collect '),
                  TextSpan(
                    text: data.artistsCollected.take(3).join(', '),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const TextSpan(text: ' more than once.'),
                ],
              ),
            ),
          ],
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
