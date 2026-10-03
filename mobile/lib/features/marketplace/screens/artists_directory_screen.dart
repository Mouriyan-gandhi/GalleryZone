import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/artwork_card.dart';

/// Port of `app/artists/page.tsx` - the independent artists selling on
/// GalleryZone, newest listing first as the API sends them.
class ArtistsDirectoryScreen extends ConsumerWidget {
  const ArtistsDirectoryScreen({super.key});

  static const path = '/artists';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artists = ref.watch(artistsProvider);
    final textScale = ArtworkGridDelegate.textScaleOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Artists')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistsProvider);
          try {
            await ref.read(artistsProvider.future);
          } catch (_) {
            // Offline: the screen already says so.
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Artists',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Independent artists building their practice on GalleryZone: every listing backed by full '
                      'price privacy and a signed certificate of authenticity.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ),
            ...artists.when(
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisExtent: 240 * textScale,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                      ),
                      childCount: 6,
                    ),
                  ),
                ),
              ],
              error: (error, stack) => [
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: LucideIcons.users,
                    title: "Couldn't load artists",
                    description: 'Please try again in a moment.',
                    action: OutlinedButton(
                      onPressed: () => ref.invalidate(artistsProvider),
                      child: const Text('Try again'),
                    ),
                  ),
                ),
              ],
              data: (list) => list.isEmpty
                  ? const [
                      SliverToBoxAdapter(
                        child: EmptyState(
                          icon: LucideIcons.users,
                          title: 'No artists listed yet',
                          description:
                              'Artists appear here as soon as their first piece is approved for the marketplace.',
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 240 * textScale,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ArtistCardTile(artist: list[index]),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One artist in the directory: portrait, name, verification, and the line
/// they use to describe their work.
class ArtistCardTile extends StatelessWidget {
  const ArtistCardTile({super.key, required this.artist});

  final ArtistProfile artist;

  /// Bios are stored as simple `<p>` markup; a card only ever needs a plain
  /// excerpt, so the tags are stripped rather than rendered.
  static String bioExcerpt(String bio, {int maxLength = 120}) {
    final text = bio.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= maxLength ? text : '${text.substring(0, maxLength).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Bios usually open with the artist's own name, so a two-line excerpt just
    // repeated the heading; the headline is the profile's one-liner.
    final blurb = artist.headline.isNotEmpty ? artist.headline : bioExcerpt(artist.bio);
    return Material(
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        onTap: () => context.push('/artists/${artist.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ArtistAvatar(name: artist.name, imageUrl: artist.profileImageUrl),
              const SizedBox(height: 12),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              VerifiedBadge(verification: artist.verification, small: true),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
