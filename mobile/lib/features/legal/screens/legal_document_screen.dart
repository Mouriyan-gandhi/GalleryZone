import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/adaptive.dart';
import '../../shell/portal_widgets.dart';
import '../data/aggregator_terms_sections.dart';
import '../data/artist_terms_sections.dart';
import '../data/cookies_sections.dart';
import '../data/privacy_sections.dart';
import '../data/terms_sections.dart';
import '../legal_section.dart';

/// The five legal documents, native, offline, and identical in wording to the
/// website. Each gets its own `/legal/<id>` route, so an unknown legal path
/// hits the router's error page instead of an empty document.
enum LegalDoc { terms, privacy, cookies, artistTerms, aggregatorTerms }

class LegalDocSpec {
  const LegalDocSpec({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String id;
  final String title;

  /// Shown under the title, same string the web page passes to `LegalLayout`.
  final String lastUpdated;
  final List<LegalSection> sections;
}

const legalDocs = <LegalDoc, LegalDocSpec>{
  LegalDoc.terms: LegalDocSpec(
    id: 'terms',
    title: 'Terms of Service',
    lastUpdated: 'August 2026',
    sections: termsSections,
  ),
  LegalDoc.privacy: LegalDocSpec(
    id: 'privacy',
    title: 'Privacy Policy',
    lastUpdated: 'August 2026',
    sections: privacySections,
  ),
  LegalDoc.cookies: LegalDocSpec(
    id: 'cookies',
    title: 'Cookie Policy',
    lastUpdated: 'August 2026',
    sections: cookiesSections,
  ),
  LegalDoc.artistTerms: LegalDocSpec(
    id: 'artist-terms',
    title: 'Artist Terms & Conditions',
    lastUpdated: 'August 2026',
    sections: artistTermsSections,
  ),
  LegalDoc.aggregatorTerms: LegalDocSpec(
    id: 'aggregator-terms',
    title: 'Aggregator Terms & Conditions',
    lastUpdated: 'August 2026',
    sections: aggregatorTermsSections,
  ),
};

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.spec});

  static String routeFor(LegalDoc doc) => '/legal/${legalDocs[doc]!.id}';

  final LegalDocSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(spec.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last updated ${spec.lastUpdated}', style: theme.textTheme.labelSmall),
                const SizedBox(height: 20),
                for (final section in spec.sections) ...[
                  Text(
                    section.heading,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final paragraph in section.body) ...[
                    Text(
                      paragraph,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (section.id == 'cookie-categories') const _CookieTable(),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one section in the five documents whose content is a table. The web
/// renders a real `<table>`; on a phone each row is a card, because three
/// columns of prose at 360px is unreadable.
class _CookieTable extends StatelessWidget {
  const _CookieTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final row in cookieCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PortalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.category,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(row.examples, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text(row.purpose, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Rows linking into the documents above, shared by the About screen and both
/// portals' Support screens so the same three taps exist everywhere.
class LegalDocRow extends StatelessWidget {
  const LegalDocRow({super.key, required this.doc, required this.icon, required this.subtitle});

  final LegalDoc doc;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = legalDocs[doc]!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: theme.colorScheme.tertiary),
      title: Text(spec.title, style: theme.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.push(LegalDocumentScreen.routeFor(doc)),
    );
  }
}
