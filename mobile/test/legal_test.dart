import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/features/legal/data/cookies_sections.dart';
import 'package:gallery_zone/features/legal/data/faq_data.dart';
import 'package:gallery_zone/features/legal/screens/faq_screen.dart';
import 'package:gallery_zone/features/legal/screens/legal_document_screen.dart';

void main() {
  group('legal documents', () {
    // Section counts as they stand in the web content files these were
    // generated from. A re-port that silently drops clauses fails here rather
    // than shipping a shorter contract than the website's.
    const expectedSections = <LegalDoc, int>{
      LegalDoc.terms: 21,
      LegalDoc.privacy: 6,
      LegalDoc.cookies: 3,
      LegalDoc.artistTerms: 32,
      LegalDoc.aggregatorTerms: 31,
    };

    test('every document is present and complete', () {
      expect(legalDocs.keys.toSet(), LegalDoc.values.toSet());
      for (final entry in expectedSections.entries) {
        expect(legalDocs[entry.key]!.sections.length, entry.value,
            reason: '${entry.key.name} lost or gained sections');
      }
    });

    test('every section has a heading, and body text unless it is the table', () {
      for (final spec in legalDocs.values) {
        expect(spec.title.trim(), isNotEmpty);
        for (final section in spec.sections) {
          expect(section.id.trim(), isNotEmpty);
          expect(section.heading.trim(), isNotEmpty);
          if (section.id != 'cookie-categories') {
            expect(section.body, isNotEmpty, reason: '${spec.id}/${section.id} is empty');
            for (final paragraph in section.body) {
              expect(paragraph.trim(), isNotEmpty);
            }
          }
        }
      }
    });

    test('the cookie table is rendered, not silently dropped', () {
      final cookies = legalDocs[LegalDoc.cookies]!;
      expect(cookies.sections.any((s) => s.id == 'cookie-categories'), isTrue);
      expect(cookieCategories, hasLength(2));
    });

    testWidgets('a document renders its own clauses', (tester) async {
      final spec = legalDocs[LegalDoc.privacy]!;
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: LegalDocumentScreen(spec: spec)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text(spec.sections.first.heading), findsOneWidget);
    });
  });

  group('FAQ', () {
    test('every audience has questions', () {
      expect(faqItems, hasLength(55));
      for (final audience in FaqAudience.values) {
        final items = faqItems.where((item) => item.audience == audience);
        expect(items, isNotEmpty, reason: 'no ${audience.name} questions');
        for (final item in items) {
          expect(item.question.trim(), isNotEmpty);
          expect(item.answer.trim(), isNotEmpty);
        }
      }
    });

    testWidgets('opens on the tab it was asked for', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FaqScreen(initialAudience: FaqAudience.artists)),
      );
      await tester.pumpAndSettle();

      final first = faqItems.firstWhere((item) => item.audience == FaqAudience.artists);
      expect(find.text(first.question), findsOneWidget);
    });
  });
}
