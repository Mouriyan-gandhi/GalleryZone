import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist_network.dart';
import '../../marketplace/widgets/artwork_card.dart' show ArtworkImageView;
import '../../shell/portal_widgets.dart';
import '../providers/artist_network_providers.dart';
import '../providers/artist_providers.dart';

/// Connections and collaborations. The web keeps both at the foot of its
/// profile page; on a phone that page is already long, so they get their own
/// route reached from the dashboard's Manage list — the same treatment every
/// other web sidebar item gets here.
///
/// Collaborations stay gated on the MOU, and the repository refuses regardless
/// of what this screen shows.
class ArtistNetworkScreen extends ConsumerWidget {
  const ArtistNetworkScreen({super.key});

  static const path = '/dashboard/network';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectionsAsync = ref.watch(artistConnectionsProvider);
    final mouAsync = ref.watch(mouAcceptanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (connections) {
          final incoming = connections
              .where(
                (c) =>
                    c.status == ConnectionStatus.pending &&
                    connectionDirection(c, currentArtistId) ==
                        ConnectionDirection.incoming,
              )
              .toList();
          final outgoing = connections
              .where(
                (c) =>
                    c.status == ConnectionStatus.pending &&
                    connectionDirection(c, currentArtistId) ==
                        ConnectionDirection.outgoing,
              )
              .toList();
          final accepted = connections
              .where((c) => c.status == ConnectionStatus.accepted)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Text(
                'Connect with other GalleryZone artists from their public '
                'profile. Once you are connected you can propose a '
                'collaboration.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (incoming.isNotEmpty) ...[
                Text('REQUESTS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                const SizedBox(height: 8),
                for (final connection in incoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(connection: connection),
                  ),
                const SizedBox(height: 8),
              ],
              Text(
                'CONNECTED ARTISTS',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              if (accepted.isEmpty)
                PortalCard(
                  child: Text(
                    'No connections yet. Open an artist from the marketplace '
                    'and send a request from their profile.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                for (final connection in accepted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PeerTile(connection: connection),
                  ),
              if (outgoing.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Waiting on '
                  '${outgoing.map((c) => connectionPeer(c, currentArtistId).name).join(", ")}.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: 24),
              _CollaborationsSection(
                mouSigned: mouAsync.value != null,
                accepted: accepted,
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.avatar});

  final String avatar;
  static const size = 36.0;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: ArtworkImageView(url: avatar),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.connection});

  final ArtistConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final peer = connectionPeer(connection, currentArtistId);

    Future<void> respond(bool accept) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(artistNetworkRepositoryProvider)
            .respondToConnection(
              connectionId: connection.id,
              viewerId: currentArtistId,
              accept: accept,
            );
        ref.read(artistNetworkRevisionProvider.notifier).bump();
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text('$error')));
      }
    }

    return PortalCard(
      gold: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeerAvatar(avatar: peer.avatar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(peer.name, style: theme.textTheme.bodyMedium),
                    if (connection.message.isNotEmpty)
                      Text('“${connection.message}”', style: theme.textTheme.bodySmall),
                    Text(
                      'Asked ${formatShortDate(connection.requestedAt)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => respond(true),
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => respond(false),
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text('Ignore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.connection});

  final ArtistConnection connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peer = connectionPeer(connection, currentArtistId);
    return PortalCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: _PeerAvatar(avatar: peer.avatar),
        title: Text(peer.name, style: theme.textTheme.bodyMedium),
        subtitle: Text(
          'Connected ${formatShortDate(connection.respondedAt ?? connection.requestedAt)}',
          style: theme.textTheme.labelSmall,
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => context.push('/artists/${peer.id}'),
      ),
    );
  }
}

class _CollaborationsSection extends ConsumerStatefulWidget {
  const _CollaborationsSection({required this.mouSigned, required this.accepted});

  final bool mouSigned;
  final List<ArtistConnection> accepted;

  @override
  ConsumerState<_CollaborationsSection> createState() =>
      _CollaborationsSectionState();
}

class _CollaborationsSectionState extends ConsumerState<_CollaborationsSection> {
  final _titleController = TextEditingController();
  final _briefController = TextEditingController();
  String? _partnerId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  Future<void> _propose() async {
    final partnerId = _partnerId;
    if (partnerId == null) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(artistNetworkRepositoryProvider)
          .proposeCollaboration(
            proposerId: currentArtistId,
            partnerId: partnerId,
            title: _titleController.text,
            brief: _briefController.text,
          );
      ref.read(artistNetworkRevisionProvider.notifier).bump();
      _titleController.clear();
      _briefController.clear();
      setState(() => _partnerId = null);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.mouSigned) {
      return PortalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.handshake, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Text('Collaborations', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign your MOU to work with other artists on joint pieces and '
              'shows. Collaborations open as soon as it is signed.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/dashboard/mou'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Open the MOU'),
            ),
          ],
        ),
      );
    }

    final collaborationsAsync = ref.watch(artistCollaborationsProvider);
    final rows = collaborationsAsync.value ?? const <ArtistCollaboration>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.handshake, size: 18, color: theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            Text('Collaborations', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            'Nothing yet. Propose a joint piece or show to one of your '
            'connections below.',
            style: theme.textTheme.bodySmall,
          ),
        for (final collaboration in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CollaborationCard(collaboration: collaboration),
          ),
        const SizedBox(height: 12),
        if (widget.accepted.isEmpty)
          PortalCard(
            child: Text(
              'Connect with an artist first — a collaboration is always with '
              'someone you are connected to.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          PortalCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPOSE A COLLABORATION',
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _partnerId,
                  decoration: const InputDecoration(labelText: 'Artist'),
                  items: [
                    for (final connection in widget.accepted)
                      DropdownMenuItem(
                        value: connectionPeer(connection, currentArtistId).id,
                        child: Text(connectionPeer(connection, currentArtistId).name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _partnerId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Two Coasts',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _briefController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What you have in mind',
                    hintText:
                        'A paired series, six canvases each, hung as alternating pairs.',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _submitting || _partnerId == null ? null : _propose,
                  child: const Text('Send proposal'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CollaborationCard extends ConsumerWidget {
  const _CollaborationCard({required this.collaboration});

  final ArtistCollaboration collaboration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final peerName = collaborationPeerName(collaboration, currentArtistId);
    final invitedMe =
        collaboration.partnerId == currentArtistId &&
        collaboration.status == CollaborationStatus.proposed;

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        ref.read(artistNetworkRevisionProvider.notifier).bump();
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text('$error')));
      }
    }

    final repository = ref.read(artistNetworkRepositoryProvider);

    return PortalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(collaboration.title, style: theme.textTheme.bodyMedium),
              ),
              Text(
                collaborationStatusLabel[collaboration.status]!,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          Text(
            'With $peerName · proposed ${formatShortDate(collaboration.proposedAt)}',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          Text(collaboration.brief, style: theme.textTheme.bodySmall),
          if (invitedMe) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => run(
                    () => repository.respondToCollaboration(
                      collaborationId: collaboration.id,
                      viewerId: currentArtistId,
                      accept: true,
                    ),
                  ),
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => run(
                    () => repository.respondToCollaboration(
                      collaborationId: collaboration.id,
                      viewerId: currentArtistId,
                      accept: false,
                    ),
                  ),
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Decline'),
                ),
              ],
            ),
          ],
          if (collaboration.status == CollaborationStatus.active) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => run(
                () => repository.completeCollaboration(
                  collaborationId: collaboration.id,
                  viewerId: currentArtistId,
                ),
              ),
              child: const Text('Mark completed'),
            ),
          ],
        ],
      ),
    );
  }
}
