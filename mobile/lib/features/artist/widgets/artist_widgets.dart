import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';

// PortalCard / PortalDetailRow moved to the shared portal file when the
// aggregator portal became their third consumer; re-exported so every
// artist screen keeps its single widgets import.
export '../../shell/portal_widgets.dart';

/// Status pill for the artist's own board, where every `ArtworkStatus` can
/// actually occur — unlike the marketplace card, which only ever sees a
/// listed piece. Port of `features/dashboard/artwork-status-pill.tsx`.
class ArtworkStatusPill extends StatelessWidget {
  const ArtworkStatusPill({super.key, required this.status});

  final ArtworkStatus status;

  static const _sky = Color(0xFF38BDF8);
  static const _amber = Color(0xFFFBBF24);
  static const _emerald = Color(0xFF34D399);

  static (String, IconData, Color) _style(ArtworkStatus status) => switch (status) {
        ArtworkStatus.draft => ('Draft', LucideIcons.pencil, Color(0xFF9C9686)),
        ArtworkStatus.pendingApproval => ('In review', LucideIcons.clock3, _amber),
        ArtworkStatus.marketplace => ('Live', LucideIcons.circleCheckBig, _emerald),
        ArtworkStatus.reserved => ('Reserved', LucideIcons.bookmarkCheck, _sky),
        ArtworkStatus.preparingDispatch => ('Preparing dispatch', LucideIcons.packageCheck, _amber),
        ArtworkStatus.inTransit => ('In transit', LucideIcons.truck, _amber),
        ArtworkStatus.withAggregator => ('With gallery', LucideIcons.frame, _sky),
        ArtworkStatus.sold => ('Sold', LucideIcons.circleCheckBig, _emerald),
        ArtworkStatus.settlementComplete => ('Settled', LucideIcons.wallet, _emerald),
        ArtworkStatus.delivered => ('Delivered', LucideIcons.checkCheck, _emerald),
        ArtworkStatus.completed => ('Completed', LucideIcons.checkCheck, _emerald),
        ArtworkStatus.returned => ('Returned', LucideIcons.circleX, AppColors.destructive),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon, color) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
