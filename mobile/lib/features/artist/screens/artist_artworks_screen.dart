import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/artworks-board.tsx` — the management board,
/// the only screen in the app that shows drafts and in-review submissions,
/// and the only one that shows the artist's own asking price beside the
/// customer price.
class ArtistArtworksScreen extends ConsumerWidget {
  const ArtistArtworksScreen({super.key});

  static const path = '/dashboard/artworks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworks = ref.watch(artistArtworksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Artworks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/artworks/upload'),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Submit artwork'),
      ),
      body: artworks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your artworks",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: LucideIcons.frame,
                title: 'No artworks yet',
                description:
                    'Submit your first piece — drafts stay private until you send '
                    'them for review.',
                action: FilledButton(
                  onPressed: () => context.push('/dashboard/artworks/upload'),
                  child: const Text('Submit artwork'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(artistArtworksProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      ContentWidth(child: ArtistArtworkRow(entry: list[index])),
                ),
              ),
      ),
    );
  }
}

/// Shows both prices side by side. This is the type wall in action: the row
/// takes an [ArtistArtwork], the only shape carrying `artistPrice`, so a
/// customer-facing screen physically cannot render this widget.
class ArtistArtworkRow extends StatelessWidget {
  const ArtistArtworkRow({super.key, required this.entry});

  final ArtistArtwork entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = entry.artwork;
    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 60,
              height: 60,
              child: ArtworkImageView(url: artwork.thumbnailUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('${artwork.medium} · ${artwork.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                ArtworkStatusPill(status: artwork.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Your price', style: theme.textTheme.labelSmall),
              Text(
                formatInr(entry.artistPrice),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 6),
              Text('Buyer pays', style: theme.textTheme.labelSmall),
              Text(formatInr(artwork.customerPrice), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
