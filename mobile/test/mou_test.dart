import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/mou.dart';
import 'package:gallery_zone/features/aggregator/aggregator_mou_data.dart';
import 'package:gallery_zone/features/artist/mou_data.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/shell/mou/mou_agreement_page.dart';
import 'package:gallery_zone/features/shell/mou/mou_document.dart';
import 'package:gallery_zone/features/shell/mou/mou_pdf.dart';
import 'package:gallery_zone/features/shell/mou/signature_pad.dart';

const _pngUrl = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

MouParties _parties({
  String? name = 'Ananya Rao',
  String? address = '14 Ghat Road, Pune, Maharashtra 411001',
  String? mobile = '+91 90000 00000',
  String? email = 'ananya@example.com',
  String? governmentId = 'PAN ABCDE1234F',
  String? companyName = 'Meera Iyer',
  String? designation = 'Director',
}) =>
    MouParties(
      party: MouPartyDetails(
        name: name,
        address: address,
        mobile: mobile,
        email: email,
        governmentId: governmentId,
      ),
      company: MouCompanyDetails(name: companyName, designation: designation),
    );

void main() {
  group('the documents are the website\'s, at the version the API requires', () {
    test('versions match the API', () {
      expect(mouVersion, '2026.3', reason: 'CURRENT_MOU_VERSION.artist in backend/packages/db/src/mou.ts');
      expect(aggregatorMouVersion, '2026.2', reason: 'CURRENT_MOU_VERSION.aggregator');
      expect(artistMou.version, mouVersion);
      expect(aggregatorMou.version, aggregatorMouVersion);
      expect(artistMou.party, MouParty.artist);
      expect(aggregatorMou.party, MouParty.aggregator);
    });

    test('every clause made the trip', () {
      // Counted from the website's generated data when this file was made.
      expect(artistMou.blocks, hasLength(453));
      expect(aggregatorMou.blocks, hasLength(264));
      expect(artistMou.blocks.whereType<MouField>(), hasLength(13));
      expect(aggregatorMou.blocks.whereType<MouField>(), hasLength(14));
      expect(artistMou.blocks.first, isA<MouTitle>());
      expect((artistMou.blocks.first as MouTitle).text, 'MEMORANDUM OF UNDERSTANDING');
      expect((artistMou.blocks.last as MouNote).text, startsWith('LEGAL REVIEW NOTE'));
    });

    test('the artist signs for the artist details, the aggregator for the business', () {
      final artistKeys = artistMou.blocks.whereType<MouField>().map((f) => f.key).toSet();
      expect(artistKeys, containsAll([MouFieldKey.partyName, MouFieldKey.partyGovernmentId, MouFieldKey.partySignature]));
      final aggregatorKeys = aggregatorMou.blocks.whereType<MouField>().map((f) => f.key).toSet();
      expect(aggregatorKeys, containsAll([MouFieldKey.partyBusinessName, MouFieldKey.partyGstNo]));
    });
  });

  group('dates are Indian dates', () {
    test('whatever the reader\'s clock says', () {
      expect(mouDate('2026-09-29T13:15:00.000Z'), '29/09/2026');
      expect(mouDateTime('2026-09-29T13:15:00.000Z'), '29 September 2026 at 6:45 pm IST');
    });

    test('an agreement signed at 00:30 IST is dated that day, not the day before', () {
      // 19:00 UTC on the 28th is 00:30 IST on the 29th.
      expect(mouDate('2026-09-28T19:00:00.000Z'), '29/09/2026');
      expect(mouDateTime('2026-09-28T19:00:00.000Z'), '29 September 2026 at 12:30 am IST');
    });

    test('noon and midnight read the way people say them', () {
      expect(mouDateTime('2026-01-01T06:30:00.000Z'), '1 January 2026 at 12:00 pm IST');
    });
  });

  group('filling a blank', () {
    final draft = MouFill(parties: _parties(), date: '2026-09-29T13:15:00.000Z', signed: false);
    final signed = MouFill(
      parties: _parties(),
      date: '2026-09-29T13:15:00.000Z',
      signed: true,
      signatureName: 'Ananya Rao',
      signatureDataUrl: _pngUrl,
    );

    MouFieldValue value(MouFieldKey key, MouFill fill, {MouParty party = MouParty.artist}) =>
        mouFieldValue(key, fill, party);

    test('the signer\'s details come from the profile', () {
      expect((value(MouFieldKey.partyName, draft) as MouFilled).text, 'Ananya Rao');
      expect((value(MouFieldKey.partyGovernmentId, draft) as MouFilled).text, 'PAN ABCDE1234F');
    });

    test('a required detail the profile lacks is flagged, an optional one is just a line', () {
      final empty = MouFill(parties: _parties(address: null, governmentId: null), date: draft.date, signed: false);
      expect(value(MouFieldKey.partyAddress, empty), isA<MouMissing>());
      expect(value(MouFieldKey.partyGovernmentId, empty), isA<MouMissing>());
      expect(value(MouFieldKey.partyGstNo, empty), isA<MouBlank>(), reason: 'not every aggregator is registered');
      expect(
        value(MouFieldKey.partyBusinessName, empty, party: MouParty.aggregator),
        isA<MouMissing>(),
        reason: 'but an aggregator must name its business',
      );
    });

    test('before signing the signature and date are pending; after, they are the record', () {
      expect(value(MouFieldKey.partySignature, draft), isA<MouPending>());
      expect((value(MouFieldKey.partyDate, draft) as MouPending).text, '29/09/2026');
      expect((value(MouFieldKey.partyEffectiveDate, draft) as MouPending).text, '29 / 09 / 2026');

      final signature = value(MouFieldKey.partySignature, signed) as MouSignature;
      expect(signature.name, 'Ananya Rao');
      expect(signature.image, _pngUrl);
      expect((value(MouFieldKey.partyDate, signed) as MouFilled).text, '29/09/2026');
    });

    test('GalleryZone signs through its signatory, and leaves its lines blank when there is none', () {
      expect((value(MouFieldKey.companySignatory, draft) as MouFilled).text, 'Meera Iyer');
      expect((value(MouFieldKey.companyDesignation, draft) as MouFilled).text, 'Director');
      expect((value(MouFieldKey.companySignature, draft) as MouPending).text, 'Signed electronically when you sign');
      expect((value(MouFieldKey.companySignature, signed) as MouFilled).text, 'Signed electronically');

      final nobody = MouFill(parties: _parties(companyName: null, designation: null), date: draft.date, signed: true);
      expect(value(MouFieldKey.companySignatory, nobody), isA<MouBlank>(), reason: 'never a name nobody gave');
      expect(value(MouFieldKey.companySignature, nobody), isA<MouBlank>());
      expect(value(MouFieldKey.companyDate, nobody), isA<MouBlank>());
    });
  });

  group('the offline mock fills the blanks the way the API does', () {
    test('the mobile number is written the way it is read aloud', () {
      final filled = mouPartyDetailsFor(party: MouParty.artist, fullName: 'A B', email: 'a@b.co', phone: '9876543210');
      expect(filled.details.mobile, '+91 98765 43210');
      final other = mouPartyDetailsFor(party: MouParty.artist, fullName: 'A B', email: 'a@b.co', phone: '+91 98765 43210');
      expect(other.details.mobile, '+91 98765 43210', reason: 'already formatted: left alone');
    });

    test('the address needs all four parts, and reads as one line', () {
      final full = mouPartyDetailsFor(
        party: MouParty.artist,
        fullName: 'A B',
        email: 'a@b.co',
        phone: '9876543210',
        pickupLine1: '14 Ghat Road',
        pickupLine2: 'Behind the market',
        pickupCity: 'Pune',
        pickupState: 'Maharashtra',
        pickupPincode: '411001',
      );
      expect(full.details.address, '14 Ghat Road, Behind the market, Pune, Maharashtra 411001');
      final partial = mouPartyDetailsFor(
        party: MouParty.artist,
        fullName: 'A B',
        email: 'a@b.co',
        phone: '9876543210',
        pickupLine1: '14 Ghat Road',
        pickupCity: 'Pune',
      );
      expect(partial.details.address, isNull);
      expect(partial.missing, contains('address'));
    });

    test('PAN identifies an artist, Aadhaar only ever masked and only as a fallback', () {
      MouPartyDetails detailsOf({String? pan, String? aadhaar}) =>
          mouPartyDetailsFor(party: MouParty.artist, fullName: 'A B', email: 'a@b.co', phone: '1', pan: pan, aadhaarMasked: aadhaar)
              .details;
      expect(detailsOf(pan: 'ABCDE1234F', aadhaar: '•••• 4821').governmentId, 'PAN ABCDE1234F');
      expect(detailsOf(aadhaar: '•••• 4821').governmentId, 'Aadhaar •••• 4821');
      expect(detailsOf().governmentId, isNull);
    });

    test('what is missing differs by party, and GST is never required', () {
      final artist = mouPartyDetailsFor(party: MouParty.artist, fullName: '', email: '', phone: '');
      expect(artist.missing, ['name', 'address', 'mobile', 'email', 'governmentId']);
      final aggregator = mouPartyDetailsFor(party: MouParty.aggregator, fullName: '', email: '', phone: '');
      expect(aggregator.missing, ['name', 'businessName', 'address', 'mobile']);
      expect(aggregator.missing, isNot(contains('gstNo')));
    });
  });

  group('the signature pad', () {
    Future<List<String?>> pump(WidgetTester tester, {bool enabled = true}) async {
      final reported = <String?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SignaturePad(
                enabled: enabled,
                encode: (strokes, size) async => strokes.isEmpty ? null : _pngUrl,
                onChanged: reported.add,
              ),
            ),
          ),
        ),
      );
      return reported;
    }

    Future<void> draw(WidgetTester tester) async {
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(SignaturePad.surfaceKey)));
      await gesture.moveBy(const Offset(40, 10));
      await gesture.moveBy(const Offset(30, -20));
      await gesture.up();
      await tester.pump();
    }

    testWidgets('invites a signature, then hands one over after the stroke', (tester) async {
      final reported = await pump(tester);
      expect(find.text('Draw your signature here'), findsOneWidget);

      await draw(tester);
      expect(reported, [_pngUrl]);
      expect(find.text('Draw your signature here'), findsNothing);
    });

    testWidgets('clearing takes it back', (tester) async {
      final reported = await pump(tester);
      await draw(tester);
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(reported, [_pngUrl, null]);
      expect(find.text('Draw your signature here'), findsOneWidget);
    });

    testWidgets('a pad that is switched off draws nothing', (tester) async {
      final reported = await pump(tester, enabled: false);
      await draw(tester);
      expect(reported, isEmpty);
      expect(find.text('Draw your signature here'), findsOneWidget);
    });

    testWidgets('a tap is a dot, and counts', (tester) async {
      final reported = await pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(SignaturePad.surfaceKey)));
      await gesture.up();
      await tester.pump();
      expect(reported, [_pngUrl]);
    });

    testWidgets('the real encoder makes a PNG data URL, and nothing from nothing', (tester) async {
      await tester.runAsync(() async {
        expect(await encodeSignaturePng(const [], const Size(300, 144)), isNull);
        expect(await encodeSignaturePng(const [[]], const Size(300, 144)), isNull);

        final url = await encodeSignaturePng(
          const [
            [Offset(10, 10), Offset(60, 40), Offset(120, 20), Offset(200, 100)],
            [Offset(50, 50)],
          ],
          const Size(300, 144),
        );
        expect(url, startsWith('data:image/png;base64,'));
        final bytes = base64Decode(url!.split(',').last);
        expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10], reason: 'the PNG signature');
        expect(url.length, lessThan(300000), reason: 'what the API will accept');
      });
    });
  });

  group('signing', () {
    // Sixty paragraphs: taller than any phone, so the reading has to be done.
    final longDocument = MouDocument(
      party: MouParty.artist,
      version: '2026.3',
      title: 'Artist Memorandum of Understanding',
      intro: 'Your agreement with Galleryzone.',
      footer: 'footer',
      blocks: [
        const MouTitle('MEMORANDUM OF UNDERSTANDING'),
        const MouField('Artist Name', MouFieldKey.partyName),
        const MouField('Government ID', MouFieldKey.partyGovernmentId),
        for (var i = 1; i <= 60; i++) MouParagraph('$i. The artist agrees to clause number $i of this agreement.'),
        const MouField('Signature', MouFieldKey.partySignature),
        const MouNote('LEGAL REVIEW NOTE: for counsel.'),
      ],
    );

    MouState unsigned({List<String> missing = const [], String version = '2026.3'}) => MouState(
          draft: MouDraft(
            version: version,
            parties: _parties(governmentId: missing.contains('governmentId') ? null : 'PAN ABCDE1234F'),
            missing: missing,
            asOf: '2026-09-29T13:15:00.000Z',
          ),
        );

    Future<List<Map<String, String>>> open(
      WidgetTester tester,
      MouState state, {
      MouDocument? document,
      Future<void> Function()? failWith,
      List<({Uint8List bytes, String name})>? shared,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final signings = <Map<String, String>>[];
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [
            initialRoleProvider.overrideWithValue(null),
            signatureEncoderProvider.overrideWithValue((strokes, size) async => strokes.isEmpty ? null : _pngUrl),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MouAgreementPage(
              title: 'Artist MOU',
              document: document ?? longDocument,
              state: state,
              profileRoute: '/dashboard/profile',
              share: (bytes, name) async => shared?.add((bytes: bytes, name: name)),
              onSign: ({required signatureName, required version, required signatureDataUrl}) async {
                if (failWith != null) await failWith();
                signings.add({'name': signatureName, 'version': version, 'url': signatureDataUrl});
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return signings;
    }

    Future<void> scrollToEnd(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
        await tester.pumpAndSettle();
      }
    }

    bool signEnabled(WidgetTester tester) {
      final button = find.ancestor(of: find.text('Sign and accept'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      return tester.widget<ButtonStyleButton>(button.first).onPressed != null;
    }

    testWidgets('shows the agreement with the signer\'s own details written into it', (tester) async {
      await open(tester, unsigned());
      expect(find.text('Artist Memorandum of Understanding'), findsOneWidget);
      expect(find.text('Your agreement with Galleryzone.'), findsOneWidget);
      expect(find.text('MEMORANDUM OF UNDERSTANDING'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsWidgets);
      expect(find.text('PAN ABCDE1234F'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Agree'), findsOneWidget);
      expect(find.text('Sign'), findsOneWidget);
    });

    testWidgets('nothing can be agreed until the end has been reached', (tester) async {
      await open(tester, unsigned());
      expect(find.text('Read to the end to continue'), findsNothing, reason: 'it is further down the page');

      await scrollToEnd(tester);
      expect(find.text('Read to the end to continue'), findsNothing, reason: 'reached - the cue goes');
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNotNull);
    });

    testWidgets('before the end the checkbox is locked and the cue is shown', (tester) async {
      await open(tester, unsigned());
      // Scroll far enough to put the checkbox in the tree without passing the text.
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, 0);
      // The controls sit after the sentinel, so they're not built yet - nothing to tick early.
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('the name must match the profile, and a signature must be drawn', (tester) async {
      final signings = await open(tester, unsigned());
      await scrollToEnd(tester);

      expect(signEnabled(tester), isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(signEnabled(tester), isFalse, reason: 'agreed, but no name or signature yet');

      await tester.enterText(find.widgetWithText(TextField, 'Type your full name'), 'Someone Else');
      await tester.pumpAndSettle();
      expect(find.textContaining("doesn't match the name on your profile"), findsOneWidget);
      expect(signEnabled(tester), isFalse);

      await tester.enterText(find.widgetWithText(TextField, 'Type your full name'), '  ananya rao ');
      await tester.pumpAndSettle();
      expect(find.textContaining("doesn't match"), findsNothing, reason: 'case and spacing do not matter');
      expect(signEnabled(tester), isFalse, reason: 'still no drawn signature');

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(SignaturePad.surfaceKey)));
      await gesture.moveBy(const Offset(60, 20));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(signEnabled(tester), isTrue);

      await tester.tap(find.text('Sign and accept'));
      await tester.pumpAndSettle();
      expect(signings.single, {'name': 'ananya rao', 'version': '2026.3', 'url': _pngUrl});
      expect(find.text('Signed'), findsWidgets);
    });

    testWidgets('a refusal from the API is shown, and the person can try again', (tester) async {
      var attempts = 0;
      final signings = await open(
        tester,
        unsigned(),
        failWith: () async {
          attempts++;
          if (attempts == 1) throw Exception('The signature must match the name on your profile');
        },
      );
      await scrollToEnd(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Type your full name'), 'Ananya Rao');
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(SignaturePad.surfaceKey)));
      await gesture.moveBy(const Offset(60, 20));
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign and accept'));
      await tester.pumpAndSettle();
      expect(find.text('The signature must match the name on your profile'), findsOneWidget);
      expect(signings, isEmpty);

      await tester.tap(find.text('Sign and accept'));
      await tester.pumpAndSettle();
      expect(signings, hasLength(1));
      expect(find.text('The signature must match the name on your profile'), findsNothing);
    });

    testWidgets('missing profile details block signing and say what to add', (tester) async {
      await open(tester, unsigned(missing: ['governmentId']));
      expect(find.text('Your profile is missing details this agreement needs'), findsOneWidget);
      expect(find.textContaining('PAN. Add them to your profile and save.'), findsOneWidget);
      expect(find.text('Open my profile'), findsOneWidget);
      expect(find.text('Missing from your profile'), findsOneWidget, reason: 'in the blank itself');

      await scrollToEnd(tester);
      final box = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(box.onChanged, isNull, reason: 'cannot agree to a document with holes in it');
    });

    testWidgets('a newer text than this build knows blocks signing', (tester) async {
      await open(tester, unsigned(version: '2026.4'));
      expect(find.textContaining('has been updated since this version of the app was made'), findsOneWidget);
      await scrollToEnd(tester);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    });
  });

  group('once signed', () {
    final longDocument = MouDocument(
      party: MouParty.artist,
      version: '2026.3',
      title: 'Artist Memorandum of Understanding',
      intro: 'intro',
      footer: 'GalleryZone Private Limited — Artist MOU Revised Draft',
      blocks: [
        const MouTitle('MEMORANDUM OF UNDERSTANDING'),
        const MouHeading('BETWEEN'),
        const MouField('Artist Name', MouFieldKey.partyName),
        const MouParagraph('The artist’s work – “as is” − priced in ₹.'),
        const MouItem('a.', 'establishing the marketplace'),
        const MouSubheading('Clause 4'),
        const MouSigner('ARTIST'),
        const MouField('Signature', MouFieldKey.partySignature),
        const MouField('Date', MouFieldKey.partyDate),
        const MouNote('LEGAL REVIEW NOTE'),
      ],
    );

    final state = MouState(
      draft: MouDraft(version: '2026.3', parties: _parties(name: 'Changed Since'), asOf: '2026-10-02T00:00:00.000Z'),
      acceptance: MouAcceptance(
        version: '2026.3',
        acceptedAt: '2026-09-29T13:15:00.000Z',
        signatureName: 'Ananya Rao',
        signatureDataUrl: _pngUrl,
        parties: _parties(),
      ),
    );

    testWidgets('is a receipt: who signed, when, at which version, with the signature itself', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialRoleProvider.overrideWithValue(null)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MouAgreementPage(
              title: 'Artist MOU',
              document: longDocument,
              state: state,
              profileRoute: '/dashboard/profile',
              onSign: ({required signatureName, required version, required signatureDataUrl}) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Signed 29 September 2026 at 6:45 pm IST. Version 2026.3.'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);
      expect(find.text('Signed by'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget, reason: 'the drawn signature');
      expect(find.text('Download signed PDF'), findsOneWidget);
      expect(find.text('Sign and accept'), findsNothing);
    });

    testWidgets('the document folds away, and when opened shows the details as they were signed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialRoleProvider.overrideWithValue(null)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MouAgreementPage(
              title: 'Artist MOU',
              document: longDocument,
              state: state,
              profileRoute: '/dashboard/profile',
              onSign: ({required signatureName, required version, required signatureDataUrl}) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MEMORANDUM OF UNDERSTANDING'), findsNothing);

      await tester.tap(find.text('Read the signed agreement'));
      await tester.pumpAndSettle();
      expect(find.text('MEMORANDUM OF UNDERSTANDING'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsWidgets, reason: 'as signed');
      expect(find.text('Changed Since'), findsNothing, reason: 'editing the profile never rewrites a signed agreement');
      expect(find.text('29/09/2026'), findsOneWidget);
    });

    testWidgets('the PDF is built and handed to the share sheet under a tidy name', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final shared = <({Uint8List bytes, String name})>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialRoleProvider.overrideWithValue(null)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MouAgreementPage(
              title: 'Artist MOU',
              document: longDocument,
              state: state,
              profileRoute: '/dashboard/profile',
              share: (bytes, name) async => shared.add((bytes: bytes, name: name)),
              onSign: ({required signatureName, required version, required signatureDataUrl}) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('Download signed PDF'));
        // The PDF is built off the test clock.
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();

      expect(shared, hasLength(1));
      expect(shared.single.name, 'Galleryzone-artist-MOU-2026.3-Ananya-Rao.pdf');
      expect(String.fromCharCodes(shared.single.bytes.sublist(0, 5)), '%PDF-');
      expect(shared.single.bytes.length, greaterThan(1500));
    });

    test('the PDF builds for the whole of both real agreements', () async {
      final fill = MouFill(
        parties: _parties(),
        date: '2026-09-29T13:15:00.000Z',
        signed: true,
        signatureName: 'Ananya Rao',
        signatureDataUrl: _pngUrl,
      );
      for (final document in [artistMou, aggregatorMou]) {
        final bytes = await buildMouPdf(document, fill);
        expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-', reason: document.title);
        expect(bytes.length, greaterThan(20000), reason: '${document.title} is many pages');
      }
    });

    test('a malformed signature image only loses the drawing', () async {
      final fill = MouFill(
        parties: _parties(),
        date: '2026-09-29T13:15:00.000Z',
        signed: true,
        signatureName: 'Ananya Rao',
        signatureDataUrl: 'not a data url',
      );
      final bytes = await buildMouPdf(longDocument, fill);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('the file is named for the document and the signer', () {
      final fill = MouFill(parties: _parties(), date: 'x', signed: true, signatureName: "Ananya O'Rao-Menon");
      expect(mouPdfFileName(artistMou, fill), 'Galleryzone-artist-MOU-2026.3-Ananya-O-Rao-Menon.pdf');
      expect(mouPdfFileName(aggregatorMou, fill), startsWith('Galleryzone-aggregator-MOU-2026.2-'));
    });
  });
}
