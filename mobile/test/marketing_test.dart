import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/launch.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/features/marketing/screens/about_screen.dart';

void main() {
  final links = [...AboutScreen.companyLinks, ...AboutScreen.legalLinks];

  test('every marketing link points at a real public page on the site', () {
    // The eight pages Phase 7 covers. `/` is the "Visit galleryzone.in"
    // button rather than a row, so seven paths live in the two lists. If a
    // page is renamed on the web, this list is what has to change with it —
    // `frontend-web/app/<name>/page.tsx` is the source of truth.
    expect(
      links.map((link) => link.path).toSet(),
      {'/about', '/faq', '/contact', '/artist-survey', '/terms', '/privacy', '/cookies'},
    );

    for (final link in links) {
      final url = Uri.parse('$galleryZoneSite${link.path}');
      expect(url.scheme, 'https', reason: '${link.label} must not open over http');
      expect(url.host, 'galleryzone.in');
      expect(link.label.trim(), isNotEmpty);
      expect(link.subtitle.trim(), isNotEmpty);
    }
  });

  testWidgets('the About screen offers every page and contact point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    for (final link in links) {
      await tester.scrollUntilVisible(find.text(link.label), 200);
      expect(find.text(link.label), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.text(galleryZoneEmail), 200);
    expect(find.text(galleryZoneEmail), findsOneWidget);
    expect(find.text('Visit galleryzone.in'), findsOneWidget);
  });
}
