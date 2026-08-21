import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../auth/providers/auth_providers.dart';
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
class ArtistArtworkRow extends ConsumerWidget {
  const ArtistArtworkRow({super.key, required this.entry});

  final ArtistArtwork entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artwork = entry.artwork;
    final editState = artworkEditState(artwork);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      '${artwork.medium} · ${artwork.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
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
                  Text('Listed price', style: theme.textTheme.labelSmall),
                  Text(formatInr(artwork.customerPrice), style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Text(listingTypeLabel[artwork.listingType]!, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (editState.editable)
                _RowAction(
                  icon: LucideIcons.pencil,
                  label: artwork.status == ArtworkStatus.draft
                      ? 'Continue editing'
                      : 'Edit · ${editState.daysLeft} '
                            '${editState.daysLeft == 1 ? "day" : "days"} left',
                  onTap: () => context.push('/dashboard/artworks/${artwork.id}/edit'),
                )
              else
                _RowAction(
                  icon: LucideIcons.lock,
                  label: editState.reason == ArtworkEditReason.purchased
                      ? 'Locked — sold or claimed'
                      : 'Edit window closed',
                ),
              if (artwork.status == ArtworkStatus.draft)
                _RowAction(
                  icon: LucideIcons.send,
                  label: 'Send for review',
                  onTap: () => _sendForReview(context, ref, artwork),
                ),
              if (withdrawableStatuses.contains(artwork.status))
                _RowAction(
                  icon: LucideIcons.externalLink,
                  label: 'Sold on other platform',
                  destructive: true,
                  onTap: () => _confirmSoldElsewhere(context, ref, entry),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _sendForReview(BuildContext context, WidgetRef ref, Artwork artwork) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(artistRepositoryProvider).submitForReview(artwork.id);
    ref.invalidate(artistArtworksProvider);
    ref.invalidate(artistKpisProvider);
    ref.invalidate(artistActivityProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Sent for review — it goes live once approved')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

/// The withdrawal is irreversible and costs the artist money, so the exact
/// fee is named in the dialog rather than described as "a fee".
Future<void> _confirmSoldElsewhere(BuildContext context, WidgetRef ref, ArtistArtwork entry) async {
  final fee = (entry.artwork.customerPrice * externalSalePenaltyRate).roundToDouble();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mark as sold on another platform?'),
      content: Text(
        '"${entry.artwork.title}" is removed from every GalleryZone sales channel '
        'immediately and cannot be relisted. A 1% fee of its listed price — '
        '${formatInr(fee)} — is charged on your next listing.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Mark as sold elsewhere'),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false)) return;
  try {
    await ref.read(artistRepositoryProvider).markSoldElsewhere(entry.artwork.id);
    ref.invalidate(artistArtworksProvider);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({required this.icon, required this.label, this.onTap, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onTap == null
        ? theme.textTheme.labelSmall?.color
        : destructive
        ? AppColors.destructive
        : theme.colorScheme.tertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
