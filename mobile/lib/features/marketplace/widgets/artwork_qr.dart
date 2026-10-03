import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/verify_url.dart';

/// The QR that goes on the physical label and the certificate. It encodes the
/// public verification URL ([verifyUrlFor]), so scanning it with any phone
/// opens the passport - no app, no NFC. Dark ink on white at medium error
/// correction, so a printed-and-photographed label still reads.
class ArtworkQr extends StatelessWidget {
  const ArtworkQr({super.key, required this.artworkId, this.size = 128, this.showUrl = false});

  final String artworkId;
  final double size;
  final bool showUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = verifyUrlFor(artworkId);
    const ink = Color(0xFF1A1612);
    return Semantics(
      image: true,
      label: 'QR code linking to $url',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: QrImageView(
              data: url,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ink),
            ),
          ),
          if (showUrl) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 256),
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
