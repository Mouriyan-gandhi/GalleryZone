import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/pricing.dart';
import '../../../core/similar_artworks.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/display_clock.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';

// StatusPill moved to the shared portal widgets; re-exported so this portal's
// screens keep their single widgets import.
export '../../shell/portal_widgets.dart' show StatusPill;

const _sky = Color(0xFF38BDF8);
const _emerald = Color(0xFF34D399);
const _slate = Color(0xFF94A3B8);

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
      HoldingStatus.returned => const StatusPill(
        label: 'Returned',
        color: _slate,
        icon: LucideIcons.undo2,
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
      ShipmentStatus.dispatched => const StatusPill(
        label: 'Dispatched',
        color: _sky,
      ),
      ShipmentStatus.delivered => const StatusPill(
        label: 'Delivered',
        color: _emerald,
      ),
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
      SettlementStatus.pending => StatusPill(
        label: 'Pending',
        color: theme.colorScheme.tertiary,
      ),
      SettlementStatus.processed => const StatusPill(
        label: 'Processed',
        color: _emerald,
      ),
      SettlementStatus.failed => StatusPill(
        label: 'Failed',
        color: theme.colorScheme.error,
      ),
    };
  }
}

/// Progress through a holding's 30-day display window, plus the days left.
///
/// A holding carries only `expiresAt` at most call sites, but the window is
/// always exactly 30 days (SAD §2.7), so the start is reconstructable rather
/// than needing to be passed alongside. "Now" is [displayNow]: the real clock
/// against the real service, the fixture date in the offline demo.
class ExpiryCountdown extends ConsumerWidget {
  const ExpiryCountdown({super.key, required this.expiresAt});

  final String expiresAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expires = DateTime.parse(expiresAt);
    final now = displayNow(ref);
    final elapsed = now.difference(expires.subtract(holdingWindow));
    final progress = (elapsed.inMinutes / holdingWindow.inMinutes)
        .clamp(0.0, 1.0)
        .toDouble();
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
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// The standing caveat on every commission figure in this portal. The split
/// is an open product decision, so the number is shown, sourced, and
/// labelled rather than quietly presented as final.
/// How the wallet actually works, said once where the balance is.
///
/// This replaced a notice calling the commission "provisional" and computing
/// it off the marketplace price. It is neither any more: MOU §8's 20% of the
/// markup over the artist's price is settled, and the sheet is explicit that
/// the advance is held rather than spent.
class WalletMechanicsNotice extends StatelessWidget {
  const WalletMechanicsNotice({super.key});

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
              'Reserving a piece HOLDS its advance and delivery from your '
              'balance rather than charging you. The hold is released when the '
              'piece sells; if it goes back unsold the advance is released but '
              'the delivery leg is spent. Commission is 20% of your markup '
              "over the artist's price, before GST.",
              style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a piece stands in its five-month rotation. A piece that doesn't sell
/// moves to a DIFFERENT aggregator each month, up to five times, cheaper each
/// time; "month 3 of 5" says that but doesn't show it, so this draws the whole
/// track. Used on the browse list, the reserve page and the holding page so
/// the same shape means the same thing everywhere. Port of `cycle-stepper.tsx`.
class CycleStepper extends StatelessWidget {
  const CycleStepper({
    super.key,
    required this.currentMonth,
    this.totalMonths = aggregatorCycleMonths,
    this.small = false,
  });

  final int currentMonth;
  final int totalMonths;

  /// Numberless dots, for the browse cards.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    final size = small ? 16.0 : 24.0;

    Widget dot(int month) {
      final past = month < currentMonth;
      final current = month == currentMonth;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: current ? gold : (past ? gold.withValues(alpha: 0.1) : null),
          border: Border.all(
            color: current
                ? gold
                : (past ? gold.withValues(alpha: 0.4) : theme.colorScheme.outline),
          ),
        ),
        child: small
            ? null
            : Text(
                '$month',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: current
                      ? const Color(0xFF171310)
                      : (past ? gold : theme.colorScheme.onSurfaceVariant),
                ),
              ),
      );
    }

    return Semantics(
      label: 'Month $currentMonth of $totalMonths',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var month = 1; month <= totalMonths; month++)
              if (month < totalMonths)
                Expanded(
                  child: Row(
                    children: [
                      dot(month),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: month < currentMonth
                              ? gold.withValues(alpha: 0.4)
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              else
                dot(month),
          ],
        ),
      ),
    );
  }
}

/// Pieces still open for reservation that are like [references] in category,
/// price and size - "Suggestions: same type of paintings show to him" (client,
/// 30 Sep 2026). Shown on the reserve page (like the piece being reserved), on
/// a holding (like the piece held) and above the browse list (like everything
/// this aggregator holds). Port of `suggested-artworks.tsx`.
class SuggestedArtworks extends ConsumerWidget {
  const SuggestedArtworks({
    super.key,
    required this.references,
    required this.title,
    this.limit = 4,
  });

  final List<Artwork> references;
  final String title;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inventory = ref.watch(aggregatorInventoryProvider).value ?? const <ReservableArtwork>[];
    final suggestions = similarTo(references, inventory, (item) => item.artwork, limit: limit);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return SizedBox(
                width: 122,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => context.push('/aggregator/inventory/${item.artwork.id}/reserve'),
                  child: PortalCard(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: ArtworkImageView(url: item.artwork.thumbnailUrl),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        PriceTag(
                          amount: item.offer.offerPrice,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
