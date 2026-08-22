import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../data/models/artist_network.dart';
import '../providers/artist_network_providers.dart';

/// Closing the account is a request, not a switch. A GalleryZone admin decides,
/// because an account on its way out may still owe a settlement, have a piece
/// sitting with an aggregator, or have a transfer someone is waiting to accept.
///
/// This app has no admin portal — the decision is made in the web console — so
/// on the phone a request is made, shown as pending, and can be withdrawn.
/// Deleting your data is a different thing and stays where it was: that is a
/// Play requirement and must not be routed through a review.
const _confirmWord = 'DEACTIVATE';

class DeactivationTile extends ConsumerStatefulWidget {
  const DeactivationTile({super.key});

  @override
  ConsumerState<DeactivationTile> createState() => _DeactivationTileState();
}

class _DeactivationTileState extends ConsumerState<DeactivationTile> {
  final _reason = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _reason.text.trim().isNotEmpty &&
      _confirm.text.trim().toUpperCase() == _confirmWord &&
      !_busy;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.read(artistNetworkRevisionProvider.notifier).bump();
      _reason.clear();
      _confirm.clear();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = ref.watch(deactivationRequestProvider).value;
    final repository = ref.read(artistNetworkRepositoryProvider);
    final pending = request?.status == DeactivationStatus.pending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger zone',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        if (pending) ...[
          Text(
            'Deactivation requested on ${formatLongDate(request!.requestedAt)}, '
            'awaiting review. Your listings stay live until it is approved.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text('Your reason: ${request.reason}', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() => repository.withdrawDeactivation(request.id)),
            child: const Text('Withdraw request'),
          ),
        ] else ...[
          if (request?.status == DeactivationStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Your last request was refused'
                '${request!.decisionNote != null ? ": ${request.decisionNote}" : "."} '
                'You can ask again.',
                style: theme.textTheme.labelSmall,
              ),
            ),
          if (request?.status == DeactivationStatus.approved)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'This account has been deactivated by GalleryZone. Contact '
                'support to reopen it.',
                style: theme.textTheme.labelSmall,
              ),
            ),
          Text(
            'Deactivating removes your listings from the marketplace. It is '
            'reviewed by GalleryZone first — certificates, ownership records '
            'and anything still owed to you have to be settled before an '
            'account closes.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Why are you closing the account?',
              hintText: 'Moving abroad',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Type $_confirmWord to confirm',
              hintText: _confirmWord,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _canSubmit
                ? () => _run(
                    () => repository
                        .requestDeactivation(reason: _reason.text)
                        .then((_) {}),
                  )
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(_busy ? 'Sending…' : 'Request deactivation'),
          ),
        ],
      ],
    );
  }
}
