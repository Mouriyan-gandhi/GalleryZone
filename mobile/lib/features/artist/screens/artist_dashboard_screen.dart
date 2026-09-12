import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../data/mock/seed/artist_seed.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';
import '../widgets/rating_widgets.dart';

const _soldFamily = {
  ArtworkStatus.sold,
  ArtworkStatus.settlementComplete,
  ArtworkStatus.delivered,
  ArtworkStatus.completed,
  ArtworkStatus.soldExternally,
};

/// Port of `app/dashboard/page.tsx` — status tiles, a promo to submit new
/// work, verification ladder, and the activity feed.
class ArtistDashboardScreen extends ConsumerWidget {
  const ArtistDashboardScreen({super.key});

  static const path = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworks = ref.watch(artistArtworksProvider).value;
    final kpis = ref.watch(artistKpisProvider).value ?? const [];
    final activity = ref.watch(artistActivityProvider).value ?? const [];

    final totalEarnings = kpis
        .where((kpi) => kpi.label == 'Total revenue')
        .map((kpi) => kpi.value)
        .firstOrNull;
    final inReview =
        artworks?.where((a) => a.artwork.status == ArtworkStatus.pendingApproval).length;
    final sold = artworks?.where((a) => _soldFamily.contains(a.artwork.status)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistKpisProvider);
          ref.invalidate(artistActivityProvider);
          ref.invalidate(artistArtworksProvider);
          await ref.read(artistKpisProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back, ${currentArtistName.split(' ').first}',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text("Here's what's happening with your art.",
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 20),
                  if (artworks == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    // 2x2 on a phone, four across when there's room.
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: WindowSize.of(context).isCompact ? 2 : 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: WindowSize.of(context).isCompact ? 1.5 : 1.7,
                      children: [
                        _KpiCard(
                          kpi: ArtistKpi(
                            label: 'Artworks',
                            value: '${artworks.length}',
                            delta: 'Active',
                            positive: true,
                          ),
                        ),
                        _KpiCard(
                          kpi: ArtistKpi(
                            label: 'In review',
                            value: '${inReview ?? 0}',
                            delta: 'With GalleryZone',
                            positive: (inReview ?? 0) == 0,
                          ),
                        ),
                        _KpiCard(
                          kpi: ArtistKpi(
                            label: 'Sold',
                            value: '${sold ?? 0}',
                            delta: 'All time',
                            positive: true,
                          ),
                        ),
                        _KpiCard(
                          kpi: ArtistKpi(
                            label: 'Total earnings',
                            value: totalEarnings ?? '—',
                            delta: 'All time',
                            positive: true,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  PortalCard(
                    gold: true,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(LucideIcons.imagePlus, size: 22, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Share your new work', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'Reach collectors, galleries and aggregators.',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => context.push('/dashboard/artworks/upload'),
                          child: const Text('Upload'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent activity', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.push('/dashboard/artworks'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final entry in activity.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActivityRow(entry: entry),
                    ),
                  const SizedBox(height: 20),
                  PortalCard(
                    gold: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Verification', style: theme.textTheme.titleMedium),
                            Text('Unlocks Gold ✦',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: theme.colorScheme.tertiary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final tier in artistVerificationTiers())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  tier.status == VerificationTierStatus.complete
                                      ? LucideIcons.circleCheckBig
                                      : LucideIcons.circle,
                                  size: 15,
                                  color: tier.status == VerificationTierStatus.complete
                                      ? theme.colorScheme.tertiary
                                      : theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tier ${tier.tier}: ${tier.title}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextButton(
                          onPressed: () => context.push('/dashboard/verification'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('See what unlocks the badge'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const RatingCard(),
                  const SizedBox(height: 20),
                  const CommunityTeaser(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final ArtistKpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(kpi.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.delta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: kpi.positive ? theme.colorScheme.tertiary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final ActivityEntry entry;

  static IconData _icon(ActivityKind kind) => switch (kind) {
        ActivityKind.artworkApproved => LucideIcons.circleCheckBig,
        ActivityKind.artworkSubmitted => LucideIcons.upload,
        ActivityKind.settlement => LucideIcons.wallet,
        ActivityKind.verification => LucideIcons.badgeCheck,
        ActivityKind.withdrawal => LucideIcons.arrowDownRight,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(entry.kind), size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(entry.detail, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(entry.time, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
