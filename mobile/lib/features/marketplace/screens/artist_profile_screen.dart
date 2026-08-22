import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/launch.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist.dart';
import '../../../data/models/artist_network.dart';
import '../../../data/models/auth.dart';
import '../../artist/providers/artist_network_providers.dart';
import '../../auth/providers/auth_providers.dart';
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
              // Artist-to-artist connect. Renders nothing unless the viewer is
              // a signed-in artist looking at someone else's profile.
              _ConnectButton(artistId: artist.id),
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

/// The LinkedIn-shaped half of artist connections: one button on another
/// artist's public profile. The dashboard's Connections screen is the other
/// half — it is where a request is accepted.
///
/// Only a signed-in artist sees this. Collectors and aggregators have no use
/// for it, and a dead button shown to a signed-out visitor is worse than no
/// button. There is one demo artist account, so "who am I" is that artist's id
/// whenever the session says artist.
class _ConnectButton extends ConsumerStatefulWidget {
  const _ConnectButton({required this.artistId});

  final String artistId;

  @override
  ConsumerState<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends ConsumerState<_ConnectButton> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(artistNetworkRepositoryProvider)
          .sendConnectionRequest(
            requesterId: currentArtistId,
            recipientId: widget.artistId,
            message: _messageController.text,
          );
      ref.read(artistNetworkRevisionProvider.notifier).bump();
      _messageController.clear();
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openComposer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a connection request',
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText:
                    'We both work coastal light — would be good to compare notes.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(sessionProvider);
    if (role != Role.artist || widget.artistId == currentArtistId) {
      return const SizedBox.shrink();
    }

    final connection = ref.watch(connectionWithProvider(widget.artistId)).value;

    if (connection?.status == ConnectionStatus.accepted) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 15, color: theme.colorScheme.tertiary),
            const SizedBox(width: 6),
            Text('Connected', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    if (connection?.status == ConnectionStatus.pending) {
      final waitingOnMe = connection!.recipientId == currentArtistId;
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          waitingOnMe
              ? 'They asked to connect — answer under Connections'
              : 'Request sent',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: _openComposer,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('Connect'),
        ),
      ),
    );
  }
}
