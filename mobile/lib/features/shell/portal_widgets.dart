import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/launch.dart';
import '../../core/theme/app_theme.dart';

/// One destination model, shared by all three portal shells. Each portal's
/// web sidebar (nine to fifteen grouped items) collapses to four primary
/// destinations here, with the rest reached from that portal's dashboard.
/// Fifteen bottom-nav tabs is not a design.
class ShellDestination {
  const ShellDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Card frame the customer, artist and aggregator portals' rows and panels
/// sit in — one place for the surface + hairline ring treatment, rather
/// than the same `BoxDecoration` copied down forty screens.
class PortalCard extends StatelessWidget {
  const PortalCard({super.key, required this.child, this.padding, this.gold = false});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gold ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: gold
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: child,
    );
  }
}

/// Label/value row used across settlements, KYC, COA, gallery-space and
/// sale-detail panels.
class PortalDetailRow extends StatelessWidget {
  const PortalDetailRow({super.key, required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: gold ? theme.colorScheme.tertiary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A contact point that actually opens — mail client, dialer, or browser.
/// Shared by the About screen and all three portals' support screens, which
/// previously rendered the same address as plain selectable text because the
/// app had no `url_launcher`.
class ContactLinkRow extends StatelessWidget {
  const ContactLinkRow({
    super.key,
    this.icon,
    this.glyph,
    required this.label,
    required this.url,
  });

  final IconData? icon;
  final Widget? glyph;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PortalCard(
        child: InkWell(
          onTap: () => openExternal(context, url),
          child: Row(
            children: [
              glyph ?? Icon(icon, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.tertiary),
                ),
              ),
              Icon(LucideIcons.externalLink, size: 14, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
