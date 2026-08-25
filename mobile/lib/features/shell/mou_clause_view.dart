import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../artist/mou_data.dart';

/// One numbered clause of an MOU, in the house style: a gold heading, then
/// paragraphs, then any bulleted points, then any closing paragraphs.
///
/// Shared because GalleryZone has two of these documents — the artist's and
/// the aggregator's — and they are structurally identical. Only the wording
/// differs, and that lives in the two `*_mou_data.dart` transcriptions.

class MouClauseView extends StatelessWidget {
  const MouClauseView({super.key, required this.clause});

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
