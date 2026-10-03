import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import 'coa_pdf.dart';

typedef SharePdf = Future<void> Function(Uint8List bytes, String fileName);

/// Hands the finished file to the phone's share sheet, where it can be saved
/// to Files, mailed or printed - the app's equivalent of the website's
/// "download".
Future<void> shareCoaPdf(Uint8List bytes, String fileName) =>
    Printing.sharePdf(bytes: bytes, filename: fileName);

/// One button, used wherever a certificate is shown (the artist's board, the
/// public passport, the buyer's collection). Disabled until a number exists:
/// numbers are issued when the artwork is approved for listing.
class DownloadCoaButton extends StatefulWidget {
  const DownloadCoaButton({super.key, required this.certificate, this.share = shareCoaPdf});

  final CoaPdfInput certificate;

  /// Replaced in tests; the platform share sheet is not there to talk to.
  final SharePdf share;

  @override
  State<DownloadCoaButton> createState() => _DownloadCoaButtonState();
}

class _DownloadCoaButtonState extends State<DownloadCoaButton> {
  bool _busy = false;

  bool get _ready => widget.certificate.coaCertificateNumber.isNotEmpty;

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await buildCoaPdf(widget.certificate);
      await widget.share(bytes, widget.certificate.fileName);
    } catch (error) {
      final text = error.toString();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            text.startsWith('Exception: ') ? text.substring(11) : "Couldn't build the certificate PDF.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = OutlinedButton.icon(
      onPressed: !_ready || _busy ? null : _download,
      icon: _busy
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(LucideIcons.download, size: 14),
      label: const Text('Download certificate (PDF)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: theme.colorScheme.tertiary,
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: _ready ? 0.6 : 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
    return _ready ? button : Tooltip(message: 'Issued when the artwork is approved for listing', child: button);
  }
}
