import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';

/// Port of `app/account/wishlist/page.tsx`, widened: the collector keeps
/// both saved artworks and followed artists here, on two segments, rather
/// than getting a fifth bottom tab for the second list.
///
/// The route stays `/account/wishlist` while the screen reads "Saved" — the
/// path is the web's and is worth keeping stable; the label is what people
/// see, and it has to cover artists too.
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  static const path = '/account/wishlist';

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

enum _Segment { artworks, artists }

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  _Segment _segment = _Segment.artworks;

  @override
  Widget build(BuildContext context) {
    final savedCount = ref.watch(wishlistProvider).length;
    final followCount = ref.watch(followsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<_Segment>(
              segments: [
                ButtonSegment(
                  value: _Segment.artworks,
                  label: Text(savedCount == 0 ? 'Artworks' : 'Artworks ($savedCount)'),
                ),
                ButtonSegment(
                  value: _Segment.artists,
                  label: Text(followCount == 0 ? 'Artists' : 'Artists ($followCount)'),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (selection) =>
                  setState(() => _segment = selection.first),
            ),
          ),
          Expanded(
            child: switch (_segment) {
              _Segment.artworks => const _SavedArtworks(),
              _Segment.artists => const _FollowedArtists(),
            },
          ),
        ],
      ),
    );
  }
}

class _SavedArtworks extends ConsumerWidget {
  const _SavedArtworks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(wishlistProvider);
    final artworks = ref.watch(artworksByIdProvider);

    return artworks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const EmptyState(
        icon: LucideIcons.triangleAlert,
        title: "Couldn't load your saved work",
        description: 'Something went wrong. Try again in a moment.',
      ),
      data: (byId) {
        // Joined to the live records on every read, so a piece that sold
        // since it was saved shows its real status rather than a stale one.
        final saved = [
          for (final id in ids)
            if (byId[id] != null) byId[id]!,
        ];
        if (saved.isEmpty) {
          return EmptyState(
            icon: LucideIcons.heart,
            title: 'Nothing saved yet',
            description:
                'Tap the heart on any artwork to keep it here while you decide.',
            action: OutlinedButton(
              onPressed: () => context.push('/marketplace'),
              child: const Text('Browse the marketplace'),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.56,
          ),
          itemCount: saved.length,
          itemBuilder: (context, index) => ArtworkCard(artwork: saved[index]),
        );
      },
    );
  }
}

class _FollowedArtists extends ConsumerWidget {
  const _FollowedArtists();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(followsProvider);
    final artists = ref.watch(artistsProvider);

    return artists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const EmptyState(
        icon: LucideIcons.triangleAlert,
        title: "Couldn't load the artists you follow",
        description: 'Something went wrong. Try again in a moment.',
      ),
      data: (all) {
        final followed = [
          for (final artist in all)
            if (ids.contains(artist.id)) artist,
        ];
        if (followed.isEmpty) {
          return EmptyState(
            icon: LucideIcons.users,
            title: "You aren't following anyone yet",
            description:
                'Follow an artist from their profile to keep their new work '
                'together in one place.',
            action: OutlinedButton(
              onPressed: () => context.push('/marketplace'),
              child: const Text('Find an artist'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: followed.length,
          itemBuilder: (context, index) => _ArtistRow(artist: followed[index]),
        );
      },
    );
  }
}

class _ArtistRow extends ConsumerWidget {
  const _ArtistRow({required this.artist});

  final ArtistProfile artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listings = ref.watch(artworksByArtistProvider(artist.id)).value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/artists/${artist.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ArtworkImageView(url: artist.profileImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listings == null
                          ? 'Loading their work…'
                          : '${listings.length} '
                              'piece${listings.length == 1 ? '' : 's'} listed',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VerifiedBadge(verification: artist.verification, small: true),
              IconButton(
                tooltip: 'Unfollow ${artist.name}',
                icon: const Icon(LucideIcons.userMinus, size: 18),
                onPressed: () {
                  ref.read(followsProvider.notifier).toggle(artist.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unfollowed ${artist.name}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
