import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/launch.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/features/legal/screens/legal_document_screen.dart';
import 'package:gallery_zone/features/marketing/screens/about_screen.dart';

void main() {
  test('every marketing link points at a real public page on the site', () {
    // What still lives on the website. The legal documents and the FAQ left
    // this list when they became native screens; `/` is the "Visit
    // galleryzone.art" button rather than a row. If a page is renamed on the
    // web, this list changes with it — `frontend-web/app/<name>/page.tsx` is
    // the source of truth.
    expect(
      AboutScreen.companyLinks.map((link) => link.path).toSet(),
      {'/about', '/contact', '/artist-survey'},
    );

    for (final link in AboutScreen.companyLinks) {
      final url = Uri.parse('$galleryZoneSite${link.path}');
      expect(url.scheme, 'https', reason: '${link.label} must not open over http');
      expect(url.host, 'www.galleryzone.art');
      expect(link.label.trim(), isNotEmpty);
      expect(link.subtitle.trim(), isNotEmpty);
    }
  });

  test('the legal rows cover every document the app ships', () {
    expect(
      AboutScreen.legalDocs.map((row) => row.doc).toSet(),
      LegalDoc.values.toSet(),
    );
    for (final row in AboutScreen.legalDocs) {
      expect(row.subtitle.trim(), isNotEmpty);
    }
  });

  testWidgets('the About screen offers every page and contact point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    for (final link in AboutScreen.companyLinks) {
      await tester.scrollUntilVisible(find.text(link.label), 200);
      expect(find.text(link.label), findsOneWidget);
    }
    for (final row in AboutScreen.legalDocs) {
      final title = legalDocs[row.doc]!.title;
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.text(galleryZoneEmail), 200);
    expect(find.text(galleryZoneEmail), findsOneWidget);
    expect(find.text('Visit galleryzone.art'), findsOneWidget);
  });
}
