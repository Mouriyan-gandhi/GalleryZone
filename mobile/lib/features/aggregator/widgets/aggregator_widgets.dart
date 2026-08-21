import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/seed/aggregator_seed.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../shell/portal_widgets.dart';

const _sky = Color(0xFF38BDF8);
const _emerald = Color(0xFF34D399);

/// Small status/label pill. The three status vocabularies in this portal
/// (holding, shipment, settlement) all render as one, so the colour choice
/// lives in a single place rather than three copies of the same container.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class HoldingStatusPill extends StatelessWidget {
  const HoldingStatusPill({super.key, required this.status});

  final HoldingStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      HoldingStatus.reserved => const StatusPill(
          label: 'Reserved',
          color: _sky,
          icon: LucideIcons.bookmarkCheck,
        ),
      HoldingStatus.soldPendingSettlement => const StatusPill(
          label: 'Sold, pending settlement',
          color: _emerald,
          icon: LucideIcons.circleCheckBig,
        ),
    };
  }
}

class ShipmentStatusPill extends StatelessWidget {
  const ShipmentStatusPill({super.key, required this.status});

  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    return switch (status) {
      ShipmentStatus.preparing => StatusPill(label: 'Preparing', color: gold),
      ShipmentStatus.dispatched => const StatusPill(label: 'Dispatched', color: _sky),
      ShipmentStatus.delivered => const StatusPill(label: 'Delivered', color: _emerald),
    };
  }
}

class SettlementStatusPill extends StatelessWidget {
  const SettlementStatusPill({super.key, required this.status});

  final SettlementStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      SettlementStatus.pending =>
        StatusPill(label: 'Pending', color: theme.colorScheme.tertiary),
      SettlementStatus.processed => const StatusPill(label: 'Processed', color: _emerald),
      SettlementStatus.failed =>
        StatusPill(label: 'Failed', color: theme.colorScheme.error),
    };
  }
}

/// Progress through a holding's 30-day display window, plus the days left.
///
/// A holding carries only `expiresAt` at most call sites, but the window is
/// always exactly 30 days (SAD §2.7), so the start is reconstructable rather
/// than needing to be passed alongside. "Now" is [fixtureToday], not the
/// real clock — see that constant for why.
class ExpiryCountdown extends StatelessWidget {
  const ExpiryCountdown({super.key, required this.expiresAt});

  final String expiresAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expires = DateTime.parse(expiresAt);
    final now = fixtureToday;
    final elapsed = now.difference(expires.subtract(holdingWindow));
    final progress =
        (elapsed.inMinutes / holdingWindow.inMinutes).clamp(0.0, 1.0).toDouble();
    final daysLeft = expires.difference(now).inHours / 24;
    final remaining = daysLeft <= 0 ? 0 : daysLeft.ceil();
    final urgent = remaining <= 3;
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: theme.colorScheme.outline,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          remaining == 0
              ? 'Expires today'
              : '$remaining day${remaining == 1 ? '' : 's'} left',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// The standing caveat on every commission figure in this portal. The split
/// is an open product decision, so the number is shown, sourced, and
/// labelled rather than quietly presented as final.
class ProvisionalCommissionNotice extends StatelessWidget {
  const ProvisionalCommissionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 15, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Commission figures are provisional. The final split is still '
              'being agreed, so these use 20% of your markup over the '
              'marketplace price.',
              style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page intro used by the screens pushed off the dashboard, matching the
/// heading + one-line description each web page opens with.
class SectionIntro extends StatelessWidget {
  const SectionIntro({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
      ),
    );
  }
}
