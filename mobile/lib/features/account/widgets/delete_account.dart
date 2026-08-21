import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/storage/mock_db.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/login_screen.dart';
import '../../shell/portal_widgets.dart';

/// Account deletion, shared by all three portals.
///
/// Google Play requires an app that creates accounts to offer deletion from
/// inside the app, not only on a website, so this is a submission
/// requirement rather than a nicety. It is one flow in one file because the
/// three portals delete exactly the same thing.
///
/// Two steps on purpose: a sheet that says plainly what goes, then a
/// confirm dialog. Destructive and irreversible actions should cost one
/// deliberate extra tap — but not a typed-out confirmation, which is
/// friction disguised as safety at this scale.
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(LucideIcons.trash2, size: 20, color: theme.colorScheme.error),
      title: Text(
        'Delete account',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
      ),
      subtitle: Text(
        'Permanently remove your account and its data',
        style: theme.textTheme.labelSmall,
      ),
      onTap: () => showDeleteAccountSheet(context),
    );
  }
}

Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  bool _working = false;

  static const _removed = [
    'Your profile, contact and payout details',
    'Your orders, wallet balance and settlement history',
    'Saved artworks, followed artists and support tickets',
    'Any artwork or listing you have submitted',
  ];

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this account?'),
        content: const Text(
          'This removes your account and everything in it. It cannot be undone, '
          'and nothing is recoverable afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep my account'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    // Order matters: wipe the data first, then drop the session. Signing out
    // first would send the router to /login while the account's records were
    // still on disk, and a re-login would resurrect them.
    await MockDb.clearAll();
    await ref.read(sessionProvider.notifier).signOut();
    if (!mounted) return;

    Navigator.of(context).pop();
    context.go(LoginScreen.path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account and its data have been deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete your account', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Deleting is immediate and permanent. These go with it:',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          PortalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in _removed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.minus, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.triangleAlert, size: 15, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'If you have a wallet balance, withdraw it before deleting — '
                    'it is removed with everything else and cannot be paid out '
                    'afterwards.',
                    style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: _working ? null : _confirm,
              icon: _working
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.trash2, size: 16),
              label: Text(_working ? 'Deleting…' : 'Delete account'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _working ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
