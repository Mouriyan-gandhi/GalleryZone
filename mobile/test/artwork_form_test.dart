import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/pricing_rules.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/artwork_form_data.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artwork_upload_screen.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';

ArtistProfileDetails _profile({String? pan}) => ArtistProfileDetails(
      fullName: 'Ananya Rao',
      email: 'a@b.co',
      phone: '9000000000',
      bio: '',
      instagram: '@ananya',
      website: '',
      bankAccountMasked: '',
      ifsc: '',
      aadhaarStatus: ReviewStatus.notSubmitted,
      aadhaarMasked: '',
      pan: pan,
    );

PricingRules _rules({double markup = 0.3, double gst = 0.05}) => PricingRules(
      gstRate: gst,
      platformMarkup: markup,
      artistListingFeeRate: 0,
      serviceGstRate: 0.18,
      artistTdsRate: 0.01,
      artistConvenienceRate: 0.02,
      aggregatorCommissionRate: 0.2,
      aggregatorAdvanceRate: 0.05,
      nfcTagCharge: 500,
      subscriptionFee: 0,
      deliveryCharge: 2500,
      insuranceThreshold: 20000,
    );

class _Artist implements ArtistRepository {
  _Artist({this.pan = 'ABCDE1234F', this.rules, this.penalties = const [], this.existing});

  final String? pan;
  final PricingRules? rules;
  final List<ExternalSalePenalty> penalties;
  final ArtistArtwork? existing;

  final submissions = <SubmitArtworkInput>[];
  final edits = <SubmitArtworkInput>[];
  Object? failWith;
  ArtworkStatus resultStatus = ArtworkStatus.pendingApproval;

  @override
  Future<ArtistProfileDetails> getProfile() async => _profile(pan: pan);

  @override
  Future<PricingRules?> getPricingRules() async => rules;

  @override
  Future<List<ExternalSalePenalty>> listPenalties() async => penalties;

  @override
  Future<ArtistArtwork?> getArtwork(String artworkId) async => existing;

  @override
  Future<Artwork> submitArtwork(SubmitArtworkInput input) async {
    if (failWith != null) throw failWith!;
    submissions.add(input);
    return fixtureArtwork(id: 'aw-new', title: input.title, status: resultStatus);
  }

  @override
  Future<Artwork> updateArtwork({required String artworkId, required SubmitArtworkInput patch}) async {
    if (failWith != null) throw failWith!;
    edits.add(patch);
    return fixtureArtwork(id: artworkId, title: patch.title);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Picker implements ImagePicker {
  _Picker({this.camera, this.gallery = const []});

  final XFile? camera;
  final List<XFile> gallery;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      source == ImageSource.camera ? camera : gallery.firstOrNull;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async =>
      gallery;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A picked file that claims a size without there being a file behind it.
class _Photo extends XFile {
  _Photo(super.path, this.size);

  final int size;

  @override
  Future<int> length() async => size;
}

XFile _photo(String name, {int? length}) => _Photo('/device/$name', length ?? 3);

Future<void> _open(
  WidgetTester tester,
  _Artist repository, {
  ImagePicker? picker,
  String? artworkId,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artistRepositoryProvider.overrideWithValue(repository),
        if (picker != null) imagePickerProvider.overrideWithValue(picker),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: ArtworkUploadScreen(artworkId: artworkId)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label, String option) async {
  await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, label));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, text);
  await tester.pump();
}

/// Fills in what the API insists on, on the marketplace channel so nothing
/// aggregator-shaped is in the way.
Future<void> _fillBasics(WidgetTester tester) async {
  await _tap(tester, find.text('Marketplace'));
  await _type(tester, 'Title', 'Monsoon Over Madurai');
  await _choose(tester, 'Category', 'Sculpture');
  await _choose(tester, 'Medium', 'Bronze');
  await _type(tester, 'Your rate (₹)', '18000');
}

bool _enabled(WidgetTester tester, String label) {
  final button = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  return tester.widget<ButtonStyleButton>(button.first).onPressed != null;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('the rules behind the form', () {
    test('a size round-trips through the one shape the API reads', () {
      final parsed = parseDimensions('24 x 36 x 2 cm');
      expect(parsed, (length: '24', width: '36', height: '2', unit: 'cm'));
      expect(composeDimensions(parsed), '24 x 36 x 2 cm');
      expect(composeDimensions(parseDimensions('24 X 36 IN')), '24 x 36 in');
    });

    test('a size the form did not write is left alone, not guessed at', () {
      expect(parseDimensions('60 × 90 cm').length, isEmpty);
      expect(parseDimensions(null).unit, 'in');
      expect(composeDimensions((length: '24', width: '', height: '2', unit: 'in')), isEmpty);
    });

    test('a typed measurement is tidied the way a number input would hand it over', () {
      expect(tidyMeasurement('60'), '60');
      expect(tidyMeasurement(' 60.0 '), '60');
      expect(tidyMeasurement('60.5'), '60.5');
      expect(tidyMeasurement('0'), isNull);
      expect(tidyMeasurement('abc'), isNull);
      expect(tidyMeasurement(''), isNull);
    });

    test('older records find their option; unknown ones are kept as they are', () {
      expect(normalizeOption('Oil on Canvas', artworkMediums), 'oil-on-canvas');
      expect(normalizeOption('oil-on-canvas', artworkMediums), 'oil-on-canvas');
      expect(normalizeOption('Ceramic & Mixed Media', artworkMediums), 'ceramic-mixed-media');
      expect(normalizeOption('Textile Art', artworkCategories), 'textile');
      expect(normalizeOption('Mixed Media', artworkCategories), 'mixed-media');
      expect(normalizeOption('landscape', artworkCategories), 'landscape');
      expect(normalizeOption('', artworkFormats), '');
    });

    test('the type of artwork is stored as its label, or as the artist\'s own words', () {
      expect(artworkTypeFields('Limited Edition Print'), (type: 'limited_edition_print', other: ''));
      expect(artworkTypeFields('Site-specific'), (type: 'other', other: 'Site-specific'));
      expect(artworkTypeFields(null), (type: '', other: ''));
      expect(artworkTypeToStore('limited_edition_print', ''), 'Limited Edition Print');
      expect(artworkTypeToStore('other', '  Site-specific '), 'Site-specific');
      expect(artworkTypeToStore('other', ' '), isNull);
      expect(artworkTypeToStore('', ''), isNull);
    });

    test('only a painting carries a style', () {
      expect(paintingStyleFields('Warli Painting'), (style: 'Warli Painting', other: ''));
      expect(paintingStyleFields('Cave art'), (style: 'Other', other: 'Cave art'));
      expect(paintingStyleToStore('painting', 'Warli Painting', ''), 'Warli Painting');
      expect(paintingStyleToStore('painting', 'Other', ' Cave art '), 'Cave art');
      expect(paintingStyleToStore('painting', '', ''), isNull);
      expect(paintingStyleToStore('sculpture', 'Warli Painting', ''), isNull);
    });

    test('the ladder rounds like the website does', () {
      expect(priceLadderFor(10000, markup: 0.3, gstRate: 0.05), (base: 13000.0, customer: 13650.0, gstIncluded: 650.0));
      // 18333 x 1.3 = 23832.9, then x 1.05 = 25024.65
      expect(priceLadderFor(18333, markup: 0.3, gstRate: 0.05), (base: 23833.0, customer: 25025.0, gstIncluded: 1192.0));
      expect(percentLabel(0.05), '5');
      expect(percentLabel(0.125), '12.5');
      expect(percentLabel(0.07), '7');
    });

    test('a photo is judged by its type and size', () {
      expect(imageProblem('a.JPG', 1000), isNull);
      expect(imageProblem('a.webp', maxImageBytes), isNull);
      expect(imageProblem('scan.tiff', 1000), '"scan.tiff" isn\'t a JPEG, PNG or WebP image.');
      expect(imageProblem('noextension', 1000), contains('JPEG, PNG or WebP'));
      expect(imageProblem('big.png', maxImageBytes + 1), '"big.png" is larger than 15 MB. Please resize it and try again.');
    });

    test('an aggregator listing needs the physical facts and the terms', () {
      expect(missingForAggregatorListing(const ArtworkPhysical(), termsAccepted: false), [
        'weight',
        'framing',
        'artwork format',
        'hangers included',
        'packing confirmation',
        'aggregator terms accepted',
      ]);
      expect(
        missingForAggregatorListing(
          const ArtworkPhysical(
            weightKg: 3.5,
            framing: FramingState.stretchedCanvas,
            format: 'canvas',
            hangingHardwareIncluded: true,
            packagingConfirmed: true,
          ),
          termsAccepted: true,
        ),
        isEmpty,
      );
      expect(
        missingForAggregatorListing(const ArtworkPhysical(weightKg: 1, framing: FramingState.unframedRolled, format: 'paper'), termsAccepted: true),
        contains('framed or stretched-canvas presentation'),
      );
    });
  });

  group('a new listing', () {
    testWidgets('asks for a PAN before it can go for review, but a draft is never blocked', (tester) async {
      await _open(tester, _Artist(pan: null));

      expect(find.text('PAN required before this can go live'), findsOneWidget);
      expect(_enabled(tester, 'Submit for review'), isFalse);
      expect(_enabled(tester, 'Save as draft'), isTrue);
    });

    testWidgets('with a PAN, the aggregator channel must be completed first; the marketplace alone need not', (tester) async {
      await _open(tester, _Artist());

      expect(find.text('PAN required before this can go live'), findsNothing);
      expect(find.text('Aggregator requirements'), findsOneWidget, reason: 'both channels is the default');
      expect(find.textContaining('Still needed for an aggregator listing:', findRichText: true), findsOneWidget);
      expect(_enabled(tester, 'Submit for review'), isFalse);
      expect(find.text('Required'), findsOneWidget, reason: 'insurance is not optional on this channel');

      await _tap(tester, find.text('Marketplace'));
      expect(find.text('Aggregator requirements'), findsNothing);
      expect(find.textContaining('Still needed', findRichText: true), findsNothing);
      expect(find.text('Required'), findsNothing);
      expect(_enabled(tester, 'Submit for review'), isTrue);
    });

    testWidgets('completing the aggregator checklist unlocks submission', (tester) async {
      await _open(tester, _Artist());

      await _type(tester, 'Weight (kg)', '3.5');
      await _tap(tester, find.widgetWithText(DropdownButtonFormField<FramingState>, 'Framing'));
      expect(find.text('Unframed / rolled'), findsNothing, reason: 'only what an aggregator can take is offered');
      await tester.tap(find.text('Stretched on canvas').last);
      await tester.pumpAndSettle();
      await _choose(tester, 'Format / surface', 'Canvas');
      expect(_enabled(tester, 'Submit for review'), isFalse);

      await _tap(tester, find.text('Hangers are included with the artwork.'));
      await _tap(tester, find.text("Packed to GalleryZone's shipping standard."));
      await _tap(tester, find.text('I accept the aggregator display terms for this artwork.'));
      expect(find.textContaining('Still needed', findRichText: true), findsNothing);
      expect(_enabled(tester, 'Submit for review'), isTrue);
    });

    testWidgets('a painting style is asked for only when the piece is a painting', (tester) async {
      await _open(tester, _Artist());

      expect(find.text('Painting style'), findsNothing);
      await _choose(tester, 'Category', 'Painting');
      expect(find.text('Painting style'), findsOneWidget);
      expect(find.textContaining('97 world painting traditions'), findsOneWidget);
      await _choose(tester, 'Category', 'Sculpture');
      expect(find.text('Painting style'), findsNothing);
    });

    testWidgets('the style is picked from a searchable list, with a way to say something else', (tester) async {
      final repository = _Artist();
      await _open(tester, repository);
      await _fillBasics(tester);
      await _choose(tester, 'Category', 'Painting');

      await _tap(tester, find.text('Painting style'));
      await tester.enterText(find.byType(TextField).last, 'warli');
      await tester.pumpAndSettle();
      expect(find.text('Warli Painting'), findsOneWidget);
      expect(find.text('Pattachitra'), findsNothing);
      await tester.tap(find.text('Warli Painting'));
      await tester.pumpAndSettle();
      expect(find.text('Warli Painting'), findsOneWidget, reason: 'shown in the field now');

      // Choosing the chosen one again clears it, as on the website.
      await _tap(tester, find.text('Warli Painting'));
      expect(find.text('Warli Painting'), findsNWidgets(2), reason: 'in the field, and ticked in the list');
      await tester.tap(find.text('Warli Painting').last);
      await tester.pumpAndSettle();
      expect(find.text('Warli Painting'), findsNothing);

      // "Other" is always within reach, and asks for a name.
      await _tap(tester, find.text('Painting style'));
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching style.'), findsOneWidget);
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      await _type(tester, 'Name the painting style', ' Cave art ');

      await _tap(tester, find.text('Save as draft'));
      expect(repository.submissions.single.paintingStyle, 'Cave art');
    });

    testWidgets('the ladder is quoted from the published rules, and says where each rupee goes', (tester) async {
      await _open(tester, _Artist(rules: _rules(markup: 0.2, gst: 0.12)));
      await _type(tester, 'Your rate (₹)', '10000');

      expect(find.text('You receive'), findsOneWidget);
      expect(find.text('₹10,000'), findsWidgets);
      expect(find.text('GalleryZone margin'), findsOneWidget);
      expect(find.text('₹2,000'), findsOneWidget);
      expect(find.text('GST (12%)'), findsOneWidget);
      expect(find.text('₹1,440'), findsOneWidget);
      expect(find.text('Listed price buyers see'), findsOneWidget);
      expect(find.text('₹13,440'), findsWidgets);
      expect(find.text('Listing is free for your first 6 months.'), findsOneWidget);
      expect(find.textContaining('20% margin and 12% GST'), findsOneWidget);
    });

    testWidgets('falls back to the bundled terms while the published ones are not there', (tester) async {
      await _open(tester, _Artist());
      await _type(tester, 'Your rate (₹)', '10000');
      expect(find.text('GST (5%)'), findsOneWidget);
      expect(find.text('₹13,650'), findsWidgets);
    });

    testWidgets('a draft needs only what the API insists on, and goes without a title as "Untitled artwork"', (tester) async {
      final repository = _Artist();
      await _open(tester, repository);
      await _tap(tester, find.text('Marketplace'));
      await _choose(tester, 'Category', 'Sculpture');
      await _choose(tester, 'Medium', 'Bronze');
      await _type(tester, 'Your rate (₹)', '18000');
      await _tap(tester, find.text('Save as draft'));

      final sent = repository.submissions.single;
      expect(sent.title, 'Untitled artwork');
      expect(sent.asDraft, isTrue);
      expect(sent.category, 'sculpture');
      expect(sent.medium, 'bronze');
      expect(sent.artistPrice, 18000);
      expect(sent.listingType, ListingType.marketplaceOnly);
      expect(sent.yearCreated, DateTime.now().year, reason: 'blank means this year, as on the website');
      expect(sent.dimensions, isNull);
      expect(sent.artworkType, isNull);
      expect(sent.paintingStyle, isNull);
      expect(sent.insuranceNumber, isNull);
      expect(find.text('Saved as draft.'), findsOneWidget);
      expect(find.textContaining('continue editing it any time from My Artworks'), findsOneWidget);
    });

    testWidgets('a draft still has to say which category, medium and price - the API refuses it otherwise', (tester) async {
      final repository = _Artist();
      await _open(tester, repository);
      await _tap(tester, find.text('Save as draft'));

      expect(find.text('Select a category'), findsOneWidget);
      expect(find.text('Select a medium'), findsOneWidget);
      expect(find.text('Enter your price for this artwork'), findsOneWidget);
      expect(find.text('A title is required'), findsNothing, reason: 'a draft may be untitled');
      expect(repository.submissions, isEmpty);
    });

    testWidgets('a submission needs a title, and a photo', (tester) async {
      final repository = _Artist();
      await _open(tester, repository);
      await _tap(tester, find.text('Marketplace'));
      await _choose(tester, 'Category', 'Sculpture');
      await _choose(tester, 'Medium', 'Bronze');
      await _type(tester, 'Your rate (₹)', '18000');

      await _tap(tester, find.text('Submit for review'));
      expect(find.text('A title is required'), findsOneWidget);

      await _type(tester, 'Title', 'ab');
      await _tap(tester, find.text('Submit for review'));
      expect(find.text('Use at least 3 characters'), findsOneWidget);

      await _type(tester, 'Title', 'Monsoon');
      await _tap(tester, find.text('Submit for review'));
      expect(find.text('Add at least one photo of the piece'), findsOneWidget);
      expect(repository.submissions, isEmpty);
    });

    testWidgets('sends what was typed, in the shapes the API reads', (tester) async {
      final repository = _Artist();
      await _open(tester, repository, picker: _Picker(camera: _photo('shot.jpg')));
      await _fillBasics(tester);
      await _type(tester, 'Description', 'Cast in 2024.');
      await _choose(tester, 'Type of artwork', 'Limited Edition Print');
      await _type(tester, 'Year created', '2024');
      await _type(tester, 'Length', '24');
      await _type(tester, 'Width', '36.0');
      await _type(tester, 'Height', '2.5');
      await _choose(tester, 'Unit', 'cm');
      await _type(tester, 'Weight (kg)', '3.5');
      await _tap(tester, find.text('Camera'));
      await _tap(tester, find.text('Submit for review'));

      final sent = repository.submissions.single;
      expect(sent.title, 'Monsoon Over Madurai');
      expect(sent.description, 'Cast in 2024.');
      expect(sent.artworkType, 'Limited Edition Print');
      expect(sent.yearCreated, 2024);
      expect(sent.dimensions, '24 x 36 x 2.5 cm');
      expect(sent.physical!.weightKg, 3.5);
      expect(sent.asDraft, isFalse);
      expect(sent.images.single.url, '/device/shot.jpg');
      expect(sent.images.single.id, isNull, reason: 'a new photo, still to upload');
      expect(sent.images.single.altText, 'Monsoon Over Madurai, photo 1');
      expect(find.text('Submitted for review.'), findsOneWidget);
      expect(find.text('View it on the marketplace'), findsNothing);
    });

    testWidgets('says "Approved and live." only if the API says it went live', (tester) async {
      final repository = _Artist()..resultStatus = ArtworkStatus.marketplace;
      await _open(tester, repository, picker: _Picker(camera: _photo('shot.jpg')));
      await _fillBasics(tester);
      await _tap(tester, find.text('Camera'));
      await _tap(tester, find.text('Submit for review'));

      expect(find.text('Approved and live.'), findsOneWidget);
      expect(find.text('View it on the marketplace'), findsOneWidget);
    });

    testWidgets('an insurance number goes with the piece', (tester) async {
      final repository = _Artist();
      await _open(tester, repository, picker: _Picker(camera: _photo('shot.jpg')));
      await _fillBasics(tester);
      await _tap(tester, find.byType(Switch));
      await _type(tester, 'Policy / certificate number', ' HD-5521 ');
      await _tap(tester, find.text('Camera'));
      await _tap(tester, find.text('Submit for review'));

      final sent = repository.submissions.single;
      expect(sent.insuranceOpted, isTrue);
      expect(sent.insuranceNumber, 'HD-5521');
    });

    testWidgets('a failure stays on the form, in words, and can be retried', (tester) async {
      final repository = _Artist()..failWith = Exception('Your session has expired');
      await _open(tester, repository);
      await _tap(tester, find.text('Marketplace'));
      await _choose(tester, 'Category', 'Sculpture');
      await _choose(tester, 'Medium', 'Bronze');
      await _type(tester, 'Your rate (₹)', '18000');
      await _tap(tester, find.text('Save as draft'));

      expect(find.text('Your session has expired'), findsOneWidget);
      expect(find.text('Save as draft'), findsOneWidget);
      expect(_enabled(tester, 'Save as draft'), isTrue);
    });

    testWidgets('a photo that could not be uploaded leaves a draft and never offers to make a second one', (tester) async {
      final repository = _Artist()
        ..failWith = const ArtworkSavedAsDraft(
          'aw-7',
          'Saved "Monsoon" as a draft, but "pic.jpg": A piece can have at most 8 photos Open it from My Artworks to add the photo and submit.',
        );
      await _open(tester, repository, picker: _Picker(camera: _photo('shot.jpg')));
      await _fillBasics(tester);
      await _tap(tester, find.text('Camera'));
      await _tap(tester, find.text('Submit for review'));

      expect(find.text('Saved as draft.'), findsOneWidget);
      expect(find.textContaining('at most 8 photos'), findsOneWidget);
      expect(find.text('Submit for review'), findsNothing, reason: 'the form is gone - nothing to submit twice');
      expect(find.text('Back to My Artworks'), findsOneWidget);
    });

    testWidgets('only the first eight photos are taken, and a file the API would refuse is refused up front', (tester) async {
      final picker = _Picker(
        gallery: [
          for (var i = 0; i < 7; i++) _photo('p$i.jpg'),
          _photo('scan.tiff'),
          _photo('huge.png', length: maxImageBytes + 1),
          _photo('last.webp'),
          _photo('overflow.jpg'),
        ],
      );
      await _open(tester, _Artist(), picker: picker);
      await _tap(tester, find.text('Gallery'));

      expect(find.text('8 / 8 uploaded'), findsOneWidget, reason: 'refused files use up no place; the ninth is turned away');
      expect(find.byTooltip('Remove photo 8'), findsOneWidget);
      expect(find.byTooltip('Remove photo 9'), findsNothing);
      expect(find.textContaining('"scan.tiff" isn\'t a JPEG, PNG or WebP image.'), findsOneWidget);
      expect(find.textContaining('"huge.png" is larger than 15 MB'), findsOneWidget, reason: 'told in one note');
    });

    testWidgets('shows the banners for a fee that will be charged, one under review, and one waived', (tester) async {
      const approved = ExternalSalePenalty(
        id: 'p1',
        artworkId: 'a1',
        artworkTitle: 'Old piece',
        amount: 1500,
        createdAt: '2026-09-01T00:00:00.000Z',
        status: PenaltyStatus.approved,
      );
      const reviewing = ExternalSalePenalty(
        id: 'p2',
        artworkId: 'a2',
        artworkTitle: 'Other piece',
        amount: 800,
        createdAt: '2026-09-02T00:00:00.000Z',
        status: PenaltyStatus.pendingReview,
      );
      const waived = ExternalSalePenalty(
        id: 'p3',
        artworkId: 'a3',
        artworkTitle: 'Third piece',
        amount: 500,
        createdAt: '2026-09-03T00:00:00.000Z',
        status: PenaltyStatus.waived,
        decisionNote: 'It was promised to a gallery.',
      );
      await _open(tester, _Artist(penalties: const [approved, reviewing, waived]));

      expect(find.text('₹1,500 off-platform sale fee is due on this listing'), findsOneWidget);
      expect(find.text('₹800 off-platform sale fee is with GalleryZone for review'), findsOneWidget);
      expect(find.text('An earlier off-platform sale fee was waived: It was promised to a gallery.'), findsOneWidget);
    });
  });

  group('editing a listing', () {
    ArtistArtwork stored({ArtworkStatus status = ArtworkStatus.draft}) => ArtistArtwork(
          artistPrice: 18000,
          artwork: fixtureArtwork(
            id: 'aw-9',
            title: 'Monsoon, Madurai',
            category: 'painting',
            medium: 'Oil on Canvas',
            status: status,
            nfcTagUid: '04a1b2c3d4e580',
            nfcLinkedAt: '2026-09-28T10:00:00.000Z',
          ).copyWith(
            listingType: ListingType.marketplaceOnly,
            artworkType: 'Original',
            paintingStyle: 'Warli Painting',
            insuranceNumber: 'HD-1',
            insuranceStatus: ReviewStatus.submitted,
            insured: true,
            dimensions: '24 x 36 in',
            images: const [
              ArtworkImage(url: 'https://x/1.png', thumbnailUrl: 'https://x/1.png', sortOrder: 0, altText: 'a', id: 'i1'),
              ArtworkImage(url: 'https://x/2.png', thumbnailUrl: 'https://x/2.png', sortOrder: 1, altText: 'b', id: 'i2'),
            ],
            physical: const ArtworkPhysical(weightKg: 3.5, framing: FramingState.framed, format: 'canvas'),
          ),
        );

    testWidgets('opens with everything the piece already says', (tester) async {
      await _open(tester, _Artist(existing: stored()), artworkId: 'aw-9');

      expect(find.text('Edit artwork'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsWidgets);
      expect(find.text('Oil on Canvas'), findsOneWidget, reason: 'the old display name found its option');
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Warli Painting'), findsOneWidget);
      expect(find.text('2 / 8 uploaded'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget, reason: 'the insurer\'s number is with GalleryZone');
      expect(find.text('This piece is still a draft — edit it freely until you send it for review.'), findsOneWidget);
      expect(find.text('PAN required before this can go live'), findsNothing, reason: 'an edit is never gated on it');
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('saves with the photos it has and the size it was given', (tester) async {
      final repository = _Artist(existing: stored());
      await _open(tester, repository, artworkId: 'aw-9', picker: _Picker(camera: _photo('new.jpg')));

      await _tap(tester, find.byTooltip('Remove photo 1'));
      await _tap(tester, find.text('Camera'));
      await _type(tester, 'Title', 'Monsoon, Madurai II');
      await _tap(tester, find.text('Save changes'));

      final patch = repository.edits.single;
      expect(patch.title, 'Monsoon, Madurai II');
      expect(patch.images.map((i) => i.id), ['i2', null], reason: 'one kept by id, one new');
      expect(patch.images.last.url, '/device/new.jpg');
      expect(patch.dimensions, '24 x 36 in');
      expect(patch.medium, 'oil-on-canvas');
      expect(patch.artworkType, 'Original');
      expect(patch.paintingStyle, 'Warli Painting');
      expect(patch.insuranceNumber, 'HD-1');
      expect(find.text('Changes saved.'), findsOneWidget);
    });

    testWidgets('keeps a size it cannot split when the boxes are left empty', (tester) async {
      final legacy = stored();
      final repository = _Artist(
        existing: legacy.copyWith(artwork: legacy.artwork.copyWith(dimensions: '60 × 90 cm')),
      );
      await _open(tester, repository, artworkId: 'aw-9');
      await _tap(tester, find.text('Save changes'));
      expect(repository.edits.single.dimensions, '60 × 90 cm');
    });

    testWidgets('a piece past its edit window cannot be saved', (tester) async {
      final closed = stored(status: ArtworkStatus.sold);
      await _open(tester, _Artist(existing: closed), artworkId: 'aw-9');
      expect(find.text('This artwork has been claimed or sold — changes can no longer be saved.'), findsOneWidget);
      expect(_enabled(tester, 'Save changes'), isFalse);
    });

    testWidgets('a piece that cannot be found says so', (tester) async {
      await _open(tester, _Artist(), artworkId: 'nope');
      expect(find.text("Couldn't open this artwork"), findsOneWidget);
      expect(find.text('Artwork not found'), findsOneWidget);
    });
  });
}
