import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/artist_score.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist_network.dart';
import '../../auth/providers/auth_providers.dart';
import '../../shell/portal_widgets.dart';
import '../providers/artist_network_providers.dart';
import '../providers/artist_providers.dart';

/// Five stars filled to the nearest fraction. Half-fill is done by clipping a
/// filled row over an empty one — there is no half-star glyph, and rounding to
/// whole stars would make 4.4 and 4.6 look identical.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            LucideIcons.star,
            size: size,
            color: theme.colorScheme.outlineVariant,
          ),
      ],
    );
    final filled = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            LucideIcons.star,
            size: size,
            color: theme.colorScheme.tertiary,
            fill: 1,
          ),
      ],
    );

    return Semantics(
      label: '${value.toStringAsFixed(1)} out of 5',
      child: Stack(
        children: [
          empty,
          ClipRect(
            clipper: _FractionClipper((value / 5).clamp(0.0, 1.0)),
            child: filled,
          ),
        ],
      ),
    );
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  const _FractionClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// The artist's own rating, on their dashboard. Buyers leave a rating after a
/// delivered order; this is the read side of that. Collector reviews are not
/// collected yet, so against the real service the count is an honest zero.
///
/// Shows the 0-10 composite - customer ratings, profile completion and artwork
/// count combined (see `core/artist_score.dart`) - as the website's card does.
/// Port of `features/dashboard/rating-card.tsx`; "Latest reviews" came off the
/// card at the client's request and is not shown here either.
class RatingCard extends ConsumerWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artistId = ref.watch(accountProvider).value?.uid ?? currentArtistId;
    final ratingAsync = ref.watch(artistRatingProvider(artistId));
    final rating = ratingAsync.value;
    final profile = ref.watch(artistProfileDetailsProvider).value;
    final artworks = ref.watch(artistArtworksProvider).value;

    if (rating == null || profile == null || artworks == null) {
      return PortalCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: ratingAsync.hasError
                ? Text('Could not load your rating.', style: theme.textTheme.bodySmall)
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    final factors = (
      customerRating: rating.average * 2,
      profileCompletion: profileCompletionScore(profile),
      artworkCount: artworkCountScore(artworks.length),
    );
    final composite = scoreArtist(
      customerRating: factors.customerRating,
      profileCompletion: factors.profileCompletion,
      artworkCount: factors.artworkCount,
    );

    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your rating', style: theme.textTheme.titleMedium),
              Text(
                rating.count == 0
                    ? 'No ratings yet'
                    : '${rating.count} ${rating.count == 1 ? "rating" : "ratings"}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                composite.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.tertiary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRow(value: composite / 2),
                  const SizedBox(height: 2),
                  Text('out of 10', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FactorBar(label: 'Customer rating', value: factors.customerRating),
          _FactorBar(label: 'Profile completion', value: factors.profileCompletion),
          _FactorBar(label: 'Artworks posted', value: factors.artworkCount),
          const Divider(height: 24),
          if (rating.count == 0)
            Column(
              children: [
                Icon(LucideIcons.star, size: 24, color: theme.colorScheme.outline),
                const SizedBox(height: 8),
                Text(
                  'Buyers can rate you once an order is delivered. Your first rating will show here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            )
          else ...[
            Text(
              'CUSTOMER RATING BREAKDOWN',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            for (final star in starValues)
              _BreakdownBar(star: star, count: rating.breakdown[star] ?? 0, total: rating.count),
          ],
        ],
      ),
    );
  }
}

/// One factor of the composite, as a bar out of ten with its figure.
class _FactorBar extends StatelessWidget {
  const _FactorBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 124,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (value / 10).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.tertiary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(value.toStringAsFixed(1), style: theme.textTheme.labelSmall, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.star,
    required this.count,
    required this.total,
  });

  final int star;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$star',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            LucideIcons.star,
            size: 11,
            color: theme.colorScheme.outline,
            fill: 1,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.tertiary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card for something that does not exist yet. Not clickable, and honest
/// about not being ready — connections are live in the demo, the wider
/// community space is not.
class CommunityTeaser extends StatelessWidget {
  const CommunityTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.users, size: 20, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Artist Community',
                      style: theme.textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.tertiary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Coming soon',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Groups, local meetups and open calls with other GalleryZone '
                  'artists. Connections are live today under Manage — the wider '
                  'community space is next.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
