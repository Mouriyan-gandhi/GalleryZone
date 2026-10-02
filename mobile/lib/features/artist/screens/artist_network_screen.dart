import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist_network.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart'
    show ArtworkImageView, EmptyState;
import '../../shell/portal_widgets.dart';
import '../providers/artist_network_providers.dart';

/// The people this artist is connected to: requests waiting on them, requests
/// they have sent, and the ones that stuck. Port of
/// `features/dashboard/artist-network-panel.tsx`.
///
/// The web keeps this at the foot of its profile page; on a phone that page is
/// already long, so it gets its own route reached from the dashboard's Manage
/// list - the same treatment every other web sidebar item gets here.
///
/// Connections have no routes on the API yet, exactly as on the website: every
/// read is empty and sending a request says so. Collaborations were taken out
/// of the product on 27 Aug 2026 and are gone from here too.
class ArtistNetworkScreen extends ConsumerWidget {
  const ArtistNetworkScreen({super.key});

  static const path = '/dashboard/network';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectionsAsync = ref.watch(artistConnectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your connections",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(artistConnectionsProvider),
            child: const Text('Try again'),
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${accepted.length} connected'
                      '${incoming.isNotEmpty ? ' · ${incoming.length} waiting on you' : ''}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with other GalleryZone artists from their public profile.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
              if (incoming.isNotEmpty) ...[
                Text(
                  'REQUESTS',
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                for (final connection in incoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(connection: connection),
                  ),
                const SizedBox(height: 8),
              ],
              if (accepted.isNotEmpty) ...[
                Text(
                  'CONNECTED ARTISTS',
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                for (final connection in accepted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PeerTile(connection: connection),
                  ),
              ] else
                PortalCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.userPlus,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No connections yet. Browse artists and send a request from their profile.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/artists'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Browse artists'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (outgoing.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Waiting on ${outgoing.map((c) => connectionPeer(c, currentArtistId).name).join(", ")}.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
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
        messenger.showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
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
                      Text(
                        '“${connection.message}”',
                        style: theme.textTheme.bodySmall,
                      ),
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
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}
