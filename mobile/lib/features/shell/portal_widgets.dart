import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/launch.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/artwork.dart' show ReviewStatus;
import '../legal/data/faq_data.dart';
import '../legal/screens/faq_screen.dart';

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
  const ContactLinkRow({super.key, this.icon, this.glyph, required this.label, required this.url});

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
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.tertiary),
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

/// FAQs and walkthrough videos, shown inside every portal's Support screen —
/// one place a signed-in user goes when they need an answer.
///
/// The answers are native now, generated from the web's own `faq-data.ts`, so
/// they read the same on both clients without a network round trip.
class SupportFaqPanel extends StatelessWidget {
  const SupportFaqPanel({super.key, this.audience});

  /// Opens the FAQ on this portal's own tab — an artist should not land on
  /// the buyer questions.
  final FaqAudience? audience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FAQs', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        PortalCard(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FaqScreen(initialAudience: audience)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.circleHelp, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Read the FAQs',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Placeholder for the walkthrough videos: everything beyond the
        // aggregator-terms explainer is hosted on YouTube and linked from
        // here — drop the links in when the channel is ready.
        PortalCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.circlePlay, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video walkthroughs',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Short videos explaining listing, aggregator display and '
                      'settlement will be linked here. Coming soon.',
                      style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown wherever an artist sees what a sale pays them.
///
/// The split is one of the project's open decisions — the mocked code, the
/// business requirement and the SAD's schema disagree — so every screen that
/// prints the number says so rather than letting an artist plan around it.
class ProvisionalPayoutNotice extends StatelessWidget {
  const ProvisionalPayoutNotice({super.key});

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
              'Payout figures are provisional. The final split is still being '
              'agreed, so these show your own price less a 2% platform '
              'pass-through.',
              style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A notice that sits above a form: an icon, an optional bold [title], the
/// [body], and optionally an [action]. [gold] frames it as something to do,
/// [destructive] as something wrong.
class PortalNotice extends StatelessWidget {
  const PortalNotice({
    super.key,
    required this.icon,
    required this.body,
    this.title,
    this.gold = false,
    this.destructive = false,
    this.action,
  });

  final IconData icon;
  final String? title;
  final String body;
  final bool gold;
  final bool destructive;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: gold,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: destructive ? AppColors.destructive : theme.colorScheme.tertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
                Text(body, style: theme.textTheme.labelSmall?.copyWith(height: 1.45)),
                ?action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed-outline placeholder for something the product has promised and not
/// built (a walkthrough video, a preview card), so the gap is visible and
/// labelled rather than silently absent.
class ComingSoonTile extends StatelessWidget {
  const ComingSoonTile({super.key, required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                Text(text, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status/label pill. The status vocabularies across the portals
/// (holding, shipment, settlement, review verdicts) all render as one, so the
/// colour choice lives in a single place rather than a copy per screen.
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// The colour a review verdict reads in: quiet when nothing has happened,
/// gold while it is with GalleryZone, green once approved, red when it is not.
Color reviewStatusColor(BuildContext context, ReviewStatus status) => switch (status) {
      ReviewStatus.notSubmitted => Theme.of(context).colorScheme.onSurfaceVariant,
      ReviewStatus.submitted => Theme.of(context).colorScheme.tertiary,
      ReviewStatus.approved => const Color(0xFF34D399),
      ReviewStatus.rejected => AppColors.destructive,
    };

/// Where a GST number stands with GalleryZone. Shared by the artist and
/// aggregator profiles so the same state never reads two ways. Port of
/// `components/shared/gst-status-badge.tsx`.
class GstStatusBadge extends StatelessWidget {
  const GstStatusBadge({super.key, required this.status});

  final ReviewStatus status;

  static const labels = {
    ReviewStatus.notSubmitted: 'Not started',
    ReviewStatus.submitted: 'Pending GalleryZone approval',
    ReviewStatus.approved: 'Approved',
    ReviewStatus.rejected: 'Rejected — resubmit',
  };

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: labels[status]!, color: reviewStatusColor(context, status));
  }
}

/// Standard GSTIN shape: 2-digit state code, 10-char PAN, entity number, a
/// literal "Z", then a checksum character.
final gstinPattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

/// Shown at the foot of every portal's wallet. GST is optional for everyone —
/// leaving it blank is a valid answer and must never block a payout. When a
/// number IS entered its shape is checked locally; there is no GST portal
/// integration, which the business deliberately does not want.
///
/// It sits at the bottom because it is set once, not the first thing anyone
/// opens their wallet to read.
class GstNumberCard extends StatefulWidget {
  const GstNumberCard({
    super.key,
    required this.value,
    required this.onSave,
    required this.description,
  });

  final String value;
  final Future<void> Function(String gstin) onSave;
  final String description;

  @override
  State<GstNumberCard> createState() => _GstNumberCardState();
}

class _GstNumberCardState extends State<GstNumberCard> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _invalid {
    final value = _controller.text.trim();
    return value.isNotEmpty && !gstinPattern.hasMatch(value);
  }

  Future<void> _save() async {
    if (_invalid) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 17, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text('GST number', style: theme.textTheme.titleMedium),
              const SizedBox(width: 6),
              Text('(optional)', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.description, style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 15,
            onChanged: (_) => setState(() => _saved = false),
            decoration: InputDecoration(
              hintText: '22AAAAA0000A1Z5',
              errorText: _invalid
                  ? 'That does not look like a valid GSTIN. Leave it blank if '
                        'you do not have one.'
                  : null,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _saving || _invalid ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
              if (_saved) ...[
                const SizedBox(width: 10),
                Text(
                  'Saved',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
