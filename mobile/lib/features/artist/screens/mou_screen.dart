import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../shell/portal_widgets.dart';
import '../../shell/mou_clause_view.dart';
import '../mou_data.dart';
import '../providers/artist_providers.dart';

/// The artist's Memorandum of Understanding with GalleryZone.
///
/// Read-and-accept, stored against [mouVersion] so a later revision asks
/// again rather than silently inheriting an acceptance of different wording.
/// Distinct from the per-artwork listing terms.
class MouScreen extends ConsumerWidget {
  const MouScreen({super.key});

  static const path = '/dashboard/mou';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final acceptance = ref.watch(mouAcceptanceProvider).value;
    final accepted = acceptance != null && acceptance.version == mouVersion;

    return Scaffold(
      appBar: AppBar(title: const Text('Artist MOU')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          ContentWidth(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  gold: accepted,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        accepted ? LucideIcons.circleCheckBig : LucideIcons.fileText,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          accepted
                              ? 'Accepted on ${formatLongDate(acceptance.acceptedAt)} '
                                    '(version $mouVersion).'
                              : 'Version $mouVersion. Read it through — accepting is how '
                                    'your work is listed, promoted and sold here.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (final paragraph in mouPreamble) ...[
                  Text(paragraph, style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                for (final clause in mouClauses) ...[
                  MouClauseView(clause: clause),
                  const SizedBox(height: 18),
                ],
                const SizedBox(height: 4),
                if (!accepted)
                  FilledButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(artistRepositoryProvider).acceptMou(mouVersion);
                      ref.invalidate(mouAcceptanceProvider);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('MOU accepted')),
                      );
                    },
                    child: const Text('I accept this MOU'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
