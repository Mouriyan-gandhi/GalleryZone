import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../shell/portal_widgets.dart';
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
                  _Clause(clause: clause),
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

class _Clause extends StatelessWidget {
  const _Clause({required this.clause});

  final MouClause clause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${clause.number}. ${clause.title}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        for (final paragraph in clause.paragraphs) ...[
          Text(paragraph, style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
          const SizedBox(height: 8),
        ],
        if (clause.points != null)
          for (final point in clause.points!)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      LucideIcons.dot,
                      size: 12,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        if (clause.closing != null)
          for (final paragraph in clause.closing!)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                paragraph,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
      ],
    );
  }
}
