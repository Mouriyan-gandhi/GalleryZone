import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/payee.dart';
import '../../core/theme/app_theme.dart';

/// Where the money goes, shown wherever someone has to actually send it: the
/// checkout screen, and the aggregator's screen when a buyer is standing in
/// front of them. One widget, because an account number typed twice is an
/// account number that will eventually differ.
///
/// No QR is drawn until there is a live UPI ID. A code that scans to a
/// non-existent VPA is worse than no code — someone would try to pay it.
class PayeeDetails extends StatelessWidget {
  const PayeeDetails({super.key, required this.amount, required this.note});

  final double amount;

  /// Shows in the payer's app so the transfer can be matched to an order.
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upiIntent = upiIntentFor(amount, note);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.landmark, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay GalleryZone directly',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Transfer ${formatInr(amount)} to the account below. '
                      'Payment always goes to GalleryZone, including when you '
                      'are buying at a partner gallery.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _CopyRow(label: 'Account name', value: Payee.accountName),
          const _CopyRow(label: 'Account number', value: Payee.accountNumber, mono: true),
          const _CopyRow(label: 'IFSC', value: Payee.ifsc, mono: true),
          _PlainRow(label: 'Bank', value: '${Payee.bankName}, ${Payee.branch}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _PlainRow(label: 'Reference', value: note, mono: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: theme.colorScheme.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.qrCode, size: 26, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upiIntent != null ? 'Scan to pay by UPI' : 'UPI QR',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        upiIntent != null
                            ? 'Scan with any UPI app to pay the exact amount.'
                            : 'Appears here once the live UPI ID is connected. '
                                'Until then, use the account details above.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (mono ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)
                  ?.copyWith(
                fontFamily: mono ? 'monospace' : null,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatefulWidget {
  const _CopyRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  State<_CopyRow> createState() => _CopyRowState();
}

class _CopyRowState extends State<_CopyRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(widget.label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: widget.mono ? 'monospace' : null,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: _copy,
            visualDensity: VisualDensity.compact,
            iconSize: 15,
            tooltip: 'Copy ${widget.label}',
            icon: Icon(
              _copied ? LucideIcons.check : LucideIcons.copy,
              color: _copied ? theme.colorScheme.tertiary : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
