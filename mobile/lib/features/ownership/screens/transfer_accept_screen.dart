import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/artwork.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/ownership_providers.dart';

/// Where a transfer link lands. Public and unguarded, like the passport: the
/// person receiving a piece may not have an account, and requiring one before
/// they can accept would strand the hand-over.
class TransferAcceptScreen extends ConsumerStatefulWidget {
  const TransferAcceptScreen({super.key, required this.transferId});

  static const path = '/transfer/:transferId';

  final String transferId;

  @override
  ConsumerState<TransferAcceptScreen> createState() => _TransferAcceptScreenState();
}

class _TransferAcceptScreenState extends ConsumerState<TransferAcceptScreen> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final accepted = await ref.read(ownershipRepositoryProvider).accept(widget.transferId);
      ref.invalidate(transferProvider(widget.transferId));
      ref.invalidate(artworkTransfersProvider(accepted.artworkId));
      ref.invalidate(artworkProvider(accepted.artworkId));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfer = ref.watch(transferProvider(widget.transferId));

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer rights')),
      body: transfer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: 'Something went wrong',
          description: "We couldn't open this transfer right now.",
          action: OutlinedButton(
            onPressed: () => ref.invalidate(transferProvider(widget.transferId)),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => data == null
            ? const EmptyState(
                icon: LucideIcons.unlink,
                title: "This transfer link isn't valid",
                description:
                    'It may have been mistyped, or the transfer was removed. Ask the sender for a new link.',
              )
            : _Body(transfer: data, busy: _busy, onAccept: _accept),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.transfer, required this.busy, required this.onAccept});

  final OwnershipTransfer transfer;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artwork = ref.watch(artworkProvider(transfer.artworkId)).value;
    // The tag's state is on the public passport; the listing doesn't carry it.
    final passport = ref.watch(passportProvider(transfer.artworkId)).value;
    final isDisplay = transferKindOf(transfer) == TransferKind.display;

    return ContentWidth(
      maxWidth: 520,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          if (artwork != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 180,
                  height: 220,
                  child: ArtworkImageView(url: artwork.thumbnailUrl),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            'GALLERYZONE PASSPORT',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.tertiary,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDisplay
                ? '${transfer.fromName} is giving you display rights'
                : '${transfer.fromName} is transferring ownership to you',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            transfer.artworkTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          PortalCard(
            child: Column(
              children: [
                PortalDetailRow(
                  label: 'What',
                  value: transferKindLabel[transferKindOf(transfer)]!,
                ),
                PortalDetailRow(label: 'From', value: transfer.fromName),
                PortalDetailRow(
                  label: 'To',
                  value: transfer.toEmail.isEmpty ? transfer.toName : '${transfer.toName} · ${transfer.toEmail}',
                  gold: true,
                ),
                PortalDetailRow(label: 'Started', value: formatLongDate(transfer.initiatedAt)),
                if (isDisplay && transfer.displayEndsAt != null)
                  PortalDetailRow(
                    label: 'On display until',
                    value: formatLongDate(transfer.displayEndsAt!),
                  ),
                // The link is all the recipient gets, so the piece's own tag and
                // its full record are reachable from here rather than from a
                // second URL the sender would have to send separately.
                if (passport?.nfcLinked ?? false)
                  PortalDetailRow(label: 'NFC tag', value: passport!.nfcLocked ? 'Linked and locked' : 'Linked'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/verify/${transfer.artworkId}'),
            icon: const Icon(LucideIcons.scanLine, size: 15),
            label: const Text('View full passport'),
          ),
          const SizedBox(height: 20),
          switch (transfer.status) {
            TransferStatus.accepted => Column(
              children: [
                Icon(
                  LucideIcons.circleCheckBig,
                  size: 34,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  isDisplay ? 'Display rights recorded' : 'Ownership transferred',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  isDisplay
                      ? 'The passport records this piece as on display with '
                            '${transfer.toName}. Ownership has not changed — the '
                            'passport shows both.'
                      : '“${transfer.artworkTitle}” is now recorded to ${transfer.toName}. The artwork’s '
                            'passport shows the full chain of ownership.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/verify/${transfer.artworkId}'),
                  child: const Text('View the passport'),
                ),
              ],
            ),
            TransferStatus.cancelled => Column(
              children: [
                Icon(LucideIcons.circleX, size: 34, color: theme.colorScheme.outline),
                const SizedBox(height: 10),
                Text('This transfer was cancelled', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${transfer.fromName} cancelled the hand-over of “${transfer.artworkTitle}”. Nothing has changed '
                  'on the ownership record.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
            TransferStatus.pending => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isDisplay
                      ? 'Accepting records the piece as on display with you until '
                            'that date. Ownership stays where it is, and the display '
                            'ends on its own when the date passes.'
                      : 'Accepting records you as the artwork’s owner on its digital passport. The previous '
                            'owners stay in its history — provenance is added to, never rewritten.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: Text(
                    busy
                        ? 'Accepting…'
                        : isDisplay
                        ? 'Accept display rights'
                        : 'Accept ownership',
                  ),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
