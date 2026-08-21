import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/launch.dart';
import '../../../data/models/artist.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';
import '../widgets/social_glyphs.dart';

/// Port of `app/artists/[artistId]/page.tsx` — public, unauthenticated
/// artist profile: header + verification summary, story, and their listings.
class ArtistProfileScreen extends ConsumerWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  static const path = '/artists/:artistId';

  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(artistProfileProvider(artistId));

    return Scaffold(
      appBar: AppBar(title: const Text('Artist')),
      body: artist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: 'Something went wrong',
          description: "We couldn't load this profile right now.",
        ),
        data: (data) => data == null
            ? const EmptyState(
                icon: LucideIcons.searchX,
                title: 'Artist not found',
                description: 'This profile may no longer exist.',
              )
            : _ArtistProfileBody(artist: data),
      ),
    );
  }
}

class _ArtistProfileBody extends ConsumerWidget {
  const _ArtistProfileBody({required this.artist});

  final ArtistProfile artist;

  /// Restates what the tier count actually means — the badge itself only
  /// ever says "Verified" or "Gold ✦ Verified"; this is the one place the
  /// count is spelled out.
  static String _verificationSummary(ArtistProfile artist) {
    final tiers = verifiedTierCount(artist.verification);
    if (tiers == 3) {
      return 'Gold ✦ Verified: completed social media, active plan, and '
          'first-sale verification.';
    }
    if (tiers > 0) return 'Verified: $tiers of 3 verification tiers complete.';
    return 'This artist is completing their GalleryZone verification.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listings = ref.watch(artworksByArtistProvider(artist.id));

    return ContentWidth(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: ArtworkImageView(url: artist.profileImageUrl),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                artist.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              VerifiedBadge(verification: artist.verification),
              const SizedBox(height: 10),
              Text(
                _verificationSummary(artist),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              _FollowButton(artistId: artist.id, artistName: artist.name),
              if (artist.socialLinks.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final link in artist.socialLinks)
                      ActionChip(
                        avatar: SocialGlyph(platform: link.platform, size: 14),
                        label: Text(SocialGlyph.label(link.platform)),
                        onPressed: () => openExternal(context, link.url),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('Story', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          // The web sanitizes this with DOMPurify because it renders the bio
          // as HTML. Nothing here interprets markup, so the tags are simply
          // stripped — no injection surface to sanitize in the first place.
          Text(_stripTags(artist.bio), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          const SizedBox(height: 28),
          Text('Listed artworks', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          listings.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => const EmptyState(
              icon: LucideIcons.triangleAlert,
              title: 'Something went wrong',
              description: "We couldn't load these listings right now.",
            ),
            data: (results) => results.isEmpty
                ? EmptyState(
                    icon: LucideIcons.palette,
                    title: 'No artworks listed yet',
                    description:
                        "${artist.name} doesn't have any artwork on the marketplace "
                        'right now. Check back soon.',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.56,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) => ArtworkCard(artwork: results[index]),
                  ),
          ),
        ],
      ),
    );
  }

  static String _stripTags(String html) =>
      html.replaceAll(RegExp(r'</p>\s*<p>'), '\n\n').replaceAll(RegExp(r'<[^>]+>'), '').trim();
}

/// Follow / Following toggle. Filled while not following (it is the action
/// on offer), outlined once followed (the action becomes "stop"), which is
/// the convention every social product has trained people on.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.artistId, required this.artistName});

  final String artistId;
  final String artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(followsProvider).contains(artistId);

    void toggle() {
      ref.read(followsProvider.notifier).toggle(artistId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            following
                ? 'Unfollowed $artistName'
                : "Following $artistName — new work shows up under Saved",
          ),
        ),
      );
    }

    final icon = Icon(following ? LucideIcons.check : LucideIcons.plus, size: 16);
    final label = Text(following ? 'Following' : 'Follow');

    return SizedBox(
      height: 40,
      child: following
          ? OutlinedButton.icon(onPressed: toggle, icon: icon, label: label)
          : FilledButton.icon(onPressed: toggle, icon: icon, label: label),
    );
  }
}
