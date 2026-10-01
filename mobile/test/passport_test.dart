import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/core/verify_url.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/widgets/artwork_history.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/coa/coa_pdf.dart';
import 'package:gallery_zone/features/coa/download_coa_button.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:gallery_zone/features/marketplace/screens/passport_screen.dart';
import 'package:gallery_zone/features/marketplace/widgets/artwork_qr.dart';
import 'package:gallery_zone/features/ownership/providers/ownership_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';
import 'support/fake_repositories.dart';

CoaPdfInput _input({String number = 'GZ-COA-2026-0001', String title = 'Monsoon, Madurai'}) => CoaPdfInput(
      artworkId: 'aw-1',
      productCode: 'GZ000004',
      title: title,
      artistName: 'Ananya Rao',
      category: 'Mixed media',
      medium: 'Oil on canvas',
      dimensions: '24 × 36 in',
      yearCreated: 2021,
      coaCertificateNumber: number,
      coaIssueDate: '2026-03-04',
      ownerName: 'Dev Mehta',
    );

Widget _app(Widget home, {FakeCatalog? catalog, FakeOwnership? ownership}) => ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artworkRepositoryProvider.overrideWithValue(
          catalog ?? FakeCatalog(artworks: [fixtureArtwork()], artists: [fixtureArtist()]),
        ),
        ownershipRepositoryProvider.overrideWithValue(
          ownership ?? FakeOwnership(passports: {'aw-1': fixturePassport()}),
        ),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('the verification link', () {
    test('is one address on the real site, whatever the artwork id holds', () {
      expect(verifyUrlFor('aw-1'), 'https://www.galleryzone.art/verify/aw-1');
      expect(verifyUrlFor('a b/c'), 'https://www.galleryzone.art/verify/a%20b%2Fc');
    });
  });

  group('the certificate PDF', () {
    test('is a real PDF that carries the number, the owner and the verify link', () async {
      final bytes = await buildCoaPdf(_input(), now: DateTime(2026, 10, 2, 15, 30), compress: false);
      final raw = latin1.decode(bytes, allowInvalid: true);
      expect(raw.startsWith('%PDF'), isTrue);
      // The built-in fonts write text a word at a time, so read the words back.
      final words = [
        for (final match in RegExp(r'\[\((.*?)\)\]TJ').allMatches(raw)) match.group(1)!,
      ];
      expect(words, containsAllInOrder(['Certificate', 'No.', 'GZ-COA-2026-0001']));
      expect(words, containsAllInOrder(['Registered', 'legal', 'owner', 'Dev', 'Mehta']));
      expect(words, contains('https://www.galleryzone.art/verify/aw-1'));
      expect(words, containsAllInOrder(['Generated', '2', 'Oct', '2026,', '3:30', 'PM']));
    });

    test('typographic punctuation in a title survives the built-in font', () {
      expect(pdfSafe('Monsoon’s “end” – a study…'), 'Monsoon\'s "end" - a study...');
      expect(pdfSafe('Café'), 'Café', reason: 'Latin-1 is fine as it is');
      expect(pdfSafe('आकाश'), '????', reason: 'what the font cannot draw is marked, not blank');
    });

    test('is named after the certificate', () {
      expect(_input().fileName, 'GalleryZone-CoA-GZ-COA-2026-0001.pdf');
    });

    testWidgets('the button hands the finished file to the share sheet', (tester) async {
      Uint8List? shared;
      String? name;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: DownloadCoaButton(
                certificate: _input(),
                share: (bytes, fileName) async {
                  shared = bytes;
                  name = fileName;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Download certificate (PDF)'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      expect(name, 'GalleryZone-CoA-GZ-COA-2026-0001.pdf');
      expect(latin1.decode(shared!.sublist(0, 4)), '%PDF');
    });

    testWidgets('the button waits for a certificate number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: DownloadCoaButton(certificate: _input(number: '')))),
        ),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('the QR code', () {
    testWidgets('encodes the same link the tag carries', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Center(child: ArtworkQr(artworkId: 'aw-1', showUrl: true))),
        ),
      );
      expect(find.byType(QrImageView), findsOneWidget);
      // What a screen reader announces is the link the code encodes.
      expect(find.bySemanticsLabel(RegExp('QR code linking to ${RegExp.escape(verifyUrlFor('aw-1'))}')), findsOneWidget);
      expect(find.text(verifyUrlFor('aw-1')), findsOneWidget);
      semantics.dispose();
    });
  });

  group('the passport page', () {
    testWidgets('shows the certificate, who owns it and where, and the record of hand-overs', (tester) async {
      _phone(tester);
      final ownership = FakeOwnership(
        passports: {
          'aw-1': fixturePassport(
            events: [
              fixtureEvent(id: 'ev-2', to: 'Dev Mehta', initiatedAt: '2026-05-01T10:00:00.000Z', acceptedAt: '2026-05-02T10:00:00.000Z'),
              fixtureEvent(id: 'ev-1', from: 'Ananya Rao', to: 'Gallery Nine', kind: TransferKind.display, initiatedAt: '2026-04-01T10:00:00.000Z', acceptedAt: '2026-04-02T10:00:00.000Z'),
              fixtureEvent(id: 'ev-x', to: 'Nobody', status: TransferStatus.cancelled, initiatedAt: '2026-06-01T10:00:00.000Z', acceptedAt: null),
            ],
          ),
        },
      );
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'aw-1'), ownership: ownership));
      await tester.pumpAndSettle();

      expect(find.text('ARTWORK PASSPORT'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('GZ-COA-2026-0001'), findsOneWidget);
      expect(find.text('Dev Mehta'), findsWidgets, reason: 'the owner, from the public record');
      expect(find.text('COA issued 4 March 2026'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('PROVENANCE'), 300);
      expect(find.text('Gallery Nine'), findsOneWidget);
      expect(find.text('Display'), findsOneWidget, reason: 'a loan is marked as one');
      expect(find.text('Nobody'), findsNothing, reason: 'a cancelled hand-over never happened');
    });

    testWidgets('says a physical tag is linked, but never which chip', (tester) async {
      _phone(tester);
      final catalog = FakeCatalog(
        artworks: [fixtureArtwork(nfcTagId: 'NFC-ABC12345')],
        artists: [fixtureArtist()],
      );
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'aw-1'), catalog: catalog));
      await tester.pumpAndSettle();

      expect(find.text('Verified via NFC scan'), findsOneWidget);
      expect(find.text('NFC tag linked'), findsOneWidget);
      expect(find.textContaining('NFC-ABC12345'), findsNothing);
    });

    testWidgets('carries the QR and the certificate download once a number exists', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'aw-1')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(QrImageView), 300);
      await tester.scrollUntilVisible(find.text('Download certificate (PDF)'), 300);
      expect(find.text('Download certificate (PDF)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('View portfolio'), 300);
      expect(find.text('Verified GalleryZone artist'), findsOneWidget);
    });

    testWidgets('before a number is issued the card says so and the download waits', (tester) async {
      _phone(tester);
      final ownership = FakeOwnership(passports: {'aw-1': fixturePassport(coaNumber: null, coaIssuedAt: null)});
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'aw-1'), ownership: ownership));
      await tester.pumpAndSettle();

      expect(find.text('Pending issuance'), findsOneWidget);
      expect(find.textContaining('COA issued'), findsNothing);
    });

    testWidgets('a tag that resolves to nothing says so', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'nope')));
      await tester.pumpAndSettle();
      expect(find.text('No passport for this tag'), findsOneWidget);
    });

    testWidgets('a failed load can be tried again', (tester) async {
      _phone(tester);
      final ownership = FakeOwnership(passports: {'aw-1': fixturePassport()})..failPassport = true;
      await tester.pumpWidget(_app(const PassportScreen(artworkId: 'aw-1'), ownership: ownership));
      await tester.pumpAndSettle();
      expect(find.text("The passport didn't load"), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('ARTWORK PASSPORT'), findsOneWidget);
    });
  });

  group('an artwork\'s history', () {
    test('splits who owns it from who has been allowed to show it', () {
      final artwork = fixtureArtwork(
        nfcTagId: 'NFC-1',
        history: const [
          ArtworkStatusEvent(status: ArtworkStatus.pendingApproval, changedAt: '2026-03-01T00:00:00.000Z'),
          ArtworkStatusEvent(status: ArtworkStatus.marketplace, changedAt: '2026-03-04T00:00:00.000Z'),
          ArtworkStatusEvent(status: ArtworkStatus.withAggregator, changedAt: '2026-04-10T00:00:00.000Z'),
          ArtworkStatusEvent(status: ArtworkStatus.returned, changedAt: '2026-05-10T00:00:00.000Z'),
        ],
      );
      final history = ArtworkHistoryView.buildHistory(artwork, const [], const []);

      expect(history.ownership.map((e) => e.label), [
        'Approved and listed for sale',
        'Certificate of Authenticity issued',
        'NFC / QR tag linked',
        'Submitted to GalleryZone for review',
      ]);
      expect(history.display.map((e) => e.label), [
        'Came back from display',
        'On display with an aggregator',
      ]);
      expect(history.onDisplayNow, isFalse);
      expect(history.ownerName, 'Ananya Rao');
    });

    test('a running display loan is the live state, and a pending offer is only awaited', () {
      final future = DateTime.now().add(const Duration(days: 20)).toIso8601String();
      final transfers = [
        OwnershipTransfer(
          id: 't1',
          artworkId: 'aw-1',
          artworkTitle: 'Monsoon, Madurai',
          fromName: 'Ananya Rao',
          toName: 'Gallery Nine',
          toEmail: '',
          initiatedAt: '2026-09-01T00:00:00.000Z',
          acceptedAt: '2026-09-02T00:00:00.000Z',
          status: TransferStatus.accepted,
          kind: TransferKind.display,
          displayEndsAt: future,
        ),
        OwnershipTransfer(
          id: 't2',
          artworkId: 'aw-1',
          artworkTitle: 'Monsoon, Madurai',
          fromName: 'Ananya Rao',
          toName: 'Dev Mehta',
          toEmail: '',
          initiatedAt: '2026-09-20T00:00:00.000Z',
          status: TransferStatus.pending,
          kind: TransferKind.ownership,
        ),
      ];
      final history = ArtworkHistoryView.buildHistory(fixtureArtwork(), transfers, const []);

      expect(history.onDisplayNow, isTrue);
      expect(history.display.first.state, HistoryState.current);
      expect(history.ownership.first.state, HistoryState.pending);
      expect(history.ownership.first.label, 'Transfer to Dev Mehta');
    });
  });
}
