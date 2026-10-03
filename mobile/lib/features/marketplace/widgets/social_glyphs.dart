import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/artwork.dart';

/// Port of `components/social-icons.tsx`. Lucide ships no brand glyphs, so
/// the web hand-drew these in the same minimal line-art voice (stroke 1.6,
/// currentColor, round caps) — the exact same paths are reused here through
/// `SvgPicture.string`, which needs no asset registration for shapes this
/// small.
class SocialGlyph extends StatelessWidget {
  const SocialGlyph({super.key, required this.platform, this.size = 16, this.color});

  final SocialProofPlatform platform;
  final double size;
  final Color? color;

  static const _paths = <SocialProofPlatform, String>{
    SocialProofPlatform.instagram:
        '<rect x="3" y="3" width="18" height="18" rx="5"/>'
            '<circle cx="12" cy="12" r="4.2"/>'
            '<circle cx="17.2" cy="6.8" r="0.6" fill="COLOR" stroke="none"/>',
    SocialProofPlatform.x: '<path d="M5 5 L19 19"/><path d="M19 5 L5 19"/>',
    SocialProofPlatform.youtube: '<rect x="3" y="6" width="18" height="12" rx="4"/>'
        '<path d="M10.3 9.4 L15 12 L10.3 14.6 Z" fill="COLOR" stroke="none"/>',
    SocialProofPlatform.tiktok:
        '<path d="M13.5 3.5 v11.3 a3.3 3.3 0 1 1 -3.3 -3.3 c0.3 0 0.6 0.03 0.9 0.08"/>'
            '<path d="M13.5 3.5 a4.6 4.6 0 0 0 4.6 4.6"/>',
  };

  static String label(SocialProofPlatform platform) => switch (platform) {
        SocialProofPlatform.instagram => 'Instagram',
        SocialProofPlatform.youtube => 'YouTube',
        SocialProofPlatform.x => 'X',
        SocialProofPlatform.tiktok => 'TikTok',
      };

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    final hex = '#${(tint.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final body = _paths[platform]!.replaceAll('COLOR', hex);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="$hex" stroke-width="1.6" stroke-linecap="round" '
      'stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
    );
  }
}
