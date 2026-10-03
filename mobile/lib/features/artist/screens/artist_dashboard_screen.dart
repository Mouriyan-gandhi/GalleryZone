import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../data/mock/seed/artist_seed.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../auth/providers/auth_providers.dart';
import '../../shell/portal_menu.dart' show accountNameProvider, firstNameOf;
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';
import '../widgets/rating_widgets.dart';

const _liveFamily = {
  ArtworkStatus.marketplace,
  ArtworkStatus.reserved,
  ArtworkStatus.withAggregator,
};
const _soldFamily = {
  ArtworkStatus.sold,
  ArtworkStatus.settlementComplete,
  ArtworkStatus.delivered,
  ArtworkStatus.completed,
  ArtworkStatus.soldExternally,
};
const _inProgressFamily = {
  ArtworkStatus.preparingDispatch,
  ArtworkStatus.inTransit,
  ArtworkStatus.returned,
};

/// Port of `app/dashboard/page.tsx`, in the order the website uses on a phone:
/// who is signed in, the free period, verification, the one thing to do next,
/// the artworks at a glance, what needs attention, the figures, and the latest
/// activity.
class ArtistDashboardScreen extends ConsumerWidget {
  const ArtistDashboardScreen({super.key});

  static const path = '/dashboard';

  /// "Good morning", by the phone's own clock.
  static String greeting(DateTime now) =>
      now.hour < 12 ? 'Good morning' : (now.hour < 17 ? 'Good afternoon' : 'Good evening');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworksState = ref.watch(artistArtworksProvider);
    final artworks = artworksState.value;
    final kpis = ref.watch(artistKpisProvider);
    final activity = ref.watch(artistActivityProvider).value ?? const [];
    final profile = ref.watch(artistProfileDetailsProvider).value;
    final remote = ref.watch(remoteBackendProvider);
    final name = remote ? ref.watch(accountNameProvider) : currentArtistName;
    final firstName = name.isEmpty ? 'there' : firstNameOf(name);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistKpisProvider);
          ref.invalidate(artistActivityProvider);
          ref.invalidate(artistArtworksProvider);
          ref.invalidate(artistProfileDetailsProvider);
          ref.invalidate(artistSettlementsProvider);
          ref.invalidate(mouAcceptanceProvider);
          await ref.read(artistArtworksProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${greeting(DateTime.now())}, $firstName', style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text("Here's what needs your attention.", style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/marketplace'),
                        icon: const Icon(LucideIcons.store, size: 14),
                        label: const Text('View site'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (profile?.freeAccess?.active ?? false) ...[
                    _FreeAccessNote(access: profile!.freeAccess!),
                    const SizedBox(height: 16),
                  ],
                  const _VerificationProgress(),
                  const SizedBox(height: 16),
                  const _NextActionCard(),
                  const SizedBox(height: 16),
                  if (artworksState.hasError && artworks == null)
                    PortalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Couldn't load your artworks.", style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => ref.invalidate(artistArtworksProvider),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  else if (artworks == null)
                    const Center(
                      child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                    )
                  else
                    _ArtworkOverview(artworks: artworks),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const _NeedsAttentionCard(),
                  const SizedBox(height: 16),
                  kpis.when(
                    loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => PortalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Couldn't load your figures.", style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => ref.invalidate(artistKpisProvider),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                    data: (list) => Column(
                      children: [
                        for (final kpi in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _KpiCard(kpi: kpi),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  PortalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent activity', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 14),
                        if (activity.isEmpty)
                          Text('Nothing yet.', style: theme.textTheme.bodySmall)
                        else
                          for (final entry in activity.take(5))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ActivityRow(entry: entry),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RatingCard(),
                  // The wider artist community is not built, and the website
                  // dropped it; only the offline demo still teases it.
                  if (!remote) ...[
                    const SizedBox(height: 16),
                    const CommunityTeaser(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Early Artist Program's free period: six months from joining, a full year
/// for artists who filled in the survey. Silent once it has ended, rather than
/// promising anything about what comes after.
class _FreeAccessNote extends StatelessWidget {
  const _FreeAccessNote({required this.access});

  final FreeAccess access;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final until = DateTime.tryParse(access.until);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.gift, size: 16, color: theme.colorScheme.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: access.surveyRespondent
                        ? 'A full year of free access to every premium feature, because you filled in our survey. '
                        : 'Free access to every premium feature, for your first six months. ',
                  ),
                  if (until != null)
                    TextSpan(
                      text: 'It runs until ${DateFormat('d MMMM y').format(until.toLocal())}.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationProgress extends ConsumerWidget {
  const _VerificationProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tiers = ref.watch(verificationTiersProvider);
    return PortalCard(
      gold: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification', style: theme.textTheme.titleMedium),
              Flexible(
                child: Text(
                  'Unlocks the Gold ✦ Verified badge',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tier in tiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      tier.status == VerificationTierStatus.complete
                          ? LucideIcons.circleCheckBig
                          : LucideIcons.circle,
                      size: 15,
                      color: tier.status == VerificationTierStatus.complete
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tier ${tier.tier}: ${tier.title}', style: theme.textTheme.bodyMedium),
                        Text(tier.description, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextButton(
            onPressed: () => context.push('/dashboard/verification'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Complete your first sale'),
          ),
        ],
      ),
    );
  }
}

/// The single most important thing to do next, not a list - the attention card
/// shows the rest of the same underlying list.
class _NextActionCard extends ConsumerWidget {
  const _NextActionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(artistAttentionProvider);
    final top = items.firstOrNull;

    if (top == null) {
      return PortalCard(
        gold: true,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(LucideIcons.partyPopper, size: 20, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Text("You're all caught up.", style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }
    return PortalCard(
      gold: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT UP', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text(top.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push(top.path),
            icon: const Icon(LucideIcons.arrowRight, size: 14),
            label: const Text('Continue'),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}

class _NeedsAttentionCard extends ConsumerWidget {
  const _NeedsAttentionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(artistAttentionProvider);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Needs attention', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Row(
              children: [
                Icon(LucideIcons.circleCheckBig, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text("You're all caught up.", style: theme.textTheme.bodySmall),
              ],
            )
          else
            for (final item in items)
              InkWell(
                onTap: () => context.push(item.path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.circleAlert, size: 16, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.message, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Live, under review, draft, in transit and sold - only the groups that have
/// something in them.
class _ArtworkOverview extends StatelessWidget {
  const _ArtworkOverview({required this.artworks});

  final List<ArtistArtwork> artworks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int count(bool Function(ArtworkStatus) test) => artworks.where((a) => test(a.artwork.status)).length;
    final rows = [
      ('Live', count(_liveFamily.contains)),
      ('Under review', count((s) => s == ArtworkStatus.pendingApproval)),
      ('Draft', count((s) => s == ArtworkStatus.draft)),
      ('In transit', count(_inProgressFamily.contains)),
      ('Sold', count(_soldFamily.contains)),
    ].where((row) => row.$2 > 0);

    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Your artworks', style: theme.textTheme.titleMedium),
              Text(
                '${artworks.length}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                  Text(
                    '${row.$2}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => context.push('/dashboard/artworks'),
            icon: const Icon(LucideIcons.arrowRight, size: 14),
            label: const Text('View all artworks'),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
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
        children: [
          Text(kpi.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.delta,
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
        ActivityKind.settlement => LucideIcons.banknote,
        ActivityKind.verification => LucideIcons.shieldCheck,
        ActivityKind.withdrawal => LucideIcons.arrowDownRight,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(_icon(entry.kind), size: 16, color: theme.colorScheme.tertiary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: theme.textTheme.bodyMedium),
              Text(entry.detail, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(entry.time, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
