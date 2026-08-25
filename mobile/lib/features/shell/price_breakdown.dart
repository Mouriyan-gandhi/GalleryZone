import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/pricing.dart';
import '../../core/theme/app_theme.dart';
import '../marketplace/widgets/artwork_card.dart' show PriceTag;

/// The one price breakdown, used by both checkout steps and the receipt on a
/// past order. Port of `components/shared/price-breakdown.tsx`, which replaced
/// three near-identical copies on the web — and they drifted the moment GST
/// moved inside the displayed price.
///
/// The rule this widget exists to hold: GST is ALREADY part of [displayPrice].
/// It is shown so the buyer can see the tax component, and it is never added
/// to the total. Only delivery and the fees are additions.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.displayPrice,
    required this.gstIncluded,
    required this.deliveryCharge,
    this.convenienceFee = 0,
    this.platformFee = 0,
    this.totalLabel = 'Total',
    this.priceLabel = 'Artwork price',
  });

  /// The artwork's listed price, GST included.
  final double displayPrice;

  /// The GST portion of [displayPrice]. Informational only.
  final double gstIncluded;
  final double deliveryCharge;
  final double convenienceFee;
  final double platformFee;

  /// "Total" while deciding, "Total paid" on a completed order.
  final String totalLabel;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total =
        displayPrice + deliveryCharge + convenienceFee + platformFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(label: priceLabel, amount: displayPrice),
          // Sits under the price, not beside the other rows, because it is a
          // component of the number above rather than another charge.
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Includes GST (${(gstRate * 100).round()}%)',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  formatInr(gstIncluded),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          // Both fees are ₹0 for now and shown anyway: a fee that appears at
          // the payment step having never been mentioned is the thing buyers
          // hate.
          _Row(label: 'Platform fee', amount: platformFee, freeWhenZero: true),
          _Row(
            label: 'Convenience fee',
            amount: convenienceFee,
            freeWhenZero: true,
          ),
          _Row(label: 'Delivery', amount: deliveryCharge),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _Row(label: totalLabel, amount: total, emphasized: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.amount,
    this.freeWhenZero = false,
    this.emphasized = false,
  });

  final String label;
  final double amount;
  final bool freeWhenZero;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A zero fee reads better as "Free" than as ₹0.
    final free = freeWhenZero && amount == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasized
                ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                : theme.textTheme.bodySmall,
          ),
          if (free)
            Text(
              'Free',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            )
          else
            PriceTag(
              amount: amount,
              style: emphasized
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}
