import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../data/models/auth.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/login_screen.dart';
import '../../shell/portal_menu.dart';
import '../providers/account_providers.dart';

/// The customer portal's "More" tab — a full screen now, not a slide-out
/// drawer, so the fifth bottom-nav destination is a real page you land on
/// rather than an overlay. Same [customerMenu] data the drawer used to
/// render (Wallet, Addresses, Resell artwork, Support, FAQs, About & legal).
class CustomerMoreScreen extends ConsumerWidget {
  const CustomerMoreScreen({super.key});

  static const path = '/account/more';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(portalDisplayNameProvider);
    final menu = portalMenuFor(Role.customer);
    final email = ref.watch(customerProfileProvider).value?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      portalInitials(name),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                        Text(
                          menu.roleLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (email != null && email.isNotEmpty)
                          Text(
                            email,
                            style: theme.textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final section in menu.groups) ...[
            const Divider(height: 25),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                section.title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            for (final item in section.items) _MoreRow(item: item),
          ],
          const Divider(height: 25),
          ListTile(
            leading: Icon(LucideIcons.logOut, size: 20, color: theme.colorScheme.error),
            title: Text(
              'Sign out',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
            onTap: () async {
              final router = GoRouter.of(context);
              await ref.read(sessionProvider.notifier).signOut();
              router.go(LoginScreen.path);
            },
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item});

  final PortalMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(item.icon, size: 20, color: theme.colorScheme.tertiary),
      title: Text(item.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(item.subtitle, style: theme.textTheme.labelSmall),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.push(item.route),
    );
  }
}
