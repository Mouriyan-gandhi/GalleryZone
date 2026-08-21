import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/launch.dart';
import '../../../data/models/artwork.dart' show SocialProofPlatform;
import '../../marketplace/widgets/social_glyphs.dart';
import '../../shell/portal_widgets.dart';

/// Phase 7, link-out form. The eight public pages the web serves —
/// home, about, contact, faq, privacy, terms, cookies, artist-survey — are
/// reached from this one native screen rather than rebuilt as eight native
/// screens.
///
/// The reasoning, so a later session doesn't undo it by accident: these are
/// marketing and legal copy with essentially no interaction. Rebuilding them
/// natively means the same paragraphs live in two repositories and drift the
/// first time legal changes a sentence. What the app owes the reader is a
/// reliable way to reach the current text, which is what this is.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const path = '/about';

  @visibleForTesting
  static const companyLinks = <({IconData icon, String label, String subtitle, String path})>[
    (
      icon: LucideIcons.building2,
      label: 'About GalleryZone',
      subtitle: 'Who we are and how the platform works',
      path: '/about'
    ),
    (
      icon: LucideIcons.circleHelp,
      label: 'Frequently asked questions',
      subtitle: 'Buying, selling, authenticity and delivery',
      path: '/faq'
    ),
    (
      icon: LucideIcons.mail,
      label: 'Contact us',
      subtitle: 'Reach the artist or collector support desk',
      path: '/contact'
    ),
    (
      icon: LucideIcons.clipboardList,
      label: 'Artist survey',
      subtitle: 'Help shape the Early Artist Program',
      path: '/artist-survey'
    ),
  ];

  @visibleForTesting
  static const legalLinks = <({IconData icon, String label, String subtitle, String path})>[
    (
      icon: LucideIcons.scale,
      label: 'Terms of service',
      subtitle: 'The agreement covering your use of GalleryZone',
      path: '/terms'
    ),
    (
      icon: LucideIcons.shieldCheck,
      label: 'Privacy policy',
      subtitle: 'What we collect and what we do with it',
      path: '/privacy'
    ),
    (
      icon: LucideIcons.cookie,
      label: 'Cookie policy',
      subtitle: 'Cookies the website sets, and why',
      path: '/cookies'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  gold: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'GZ',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'GALLERYZONE',
                            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Where original art finds its identity.',
                        style: theme.textTheme.titleLarge?.copyWith(height: 1.25),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'GalleryZone gives every artwork a trusted digital identity, a '
                        'verifiable history, and a global stage to be discovered.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Company', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'These pages open galleryzone.in in your browser, so you always '
                  'get the current version.',
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 8),
                for (final item in companyLinks) _LinkRow(item: item),
                const SizedBox(height: 20),
                Text('Legal', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final item in legalLinks) _LinkRow(item: item),
                const SizedBox(height: 24),
                Text('Get in touch', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ContactLinkRow(
                  icon: LucideIcons.mail,
                  label: galleryZoneEmail,
                  url: 'mailto:$galleryZoneEmail',
                ),
                ContactLinkRow(
                  icon: LucideIcons.phone,
                  label: '+91 94929 53627',
                  url: 'tel:$galleryZonePhone',
                ),
                // Instagram only. The web footer also renders X and LinkedIn
                // marks, but both point at "#" there — no account exists yet,
                // and a tap that goes nowhere is worse than an absent icon.
                ContactLinkRow(
                  glyph: const SocialGlyph(platform: SocialProofPlatform.instagram, size: 16),
                  label: '@galleryzone.in',
                  url: 'https://www.instagram.com/galleryzone.in',
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => openExternal(context, galleryZoneSite),
                    icon: const Icon(LucideIcons.externalLink, size: 15),
                    label: const Text('Visit galleryzone.in'),
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.item});

  final ({IconData icon, String label, String subtitle, String path}) item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(item.icon, size: 20, color: theme.colorScheme.tertiary),
      title: Text(item.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(item.subtitle, style: theme.textTheme.labelSmall),
      trailing: const Icon(LucideIcons.externalLink, size: 15),
      onTap: () => openExternal(context, '$galleryZoneSite${item.path}'),
    );
  }
}
