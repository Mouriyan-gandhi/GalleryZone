import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist_network.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/repositories/artist_network_repository.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/kyc_rules.dart';
import 'package:gallery_zone/features/artist/providers/artist_network_providers.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artist_kyc_screen.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';

ArtistProfileDetails _profile({
  String? pan,
  String? gstin,
  ReviewStatus gstStatus = ReviewStatus.notSubmitted,
  ReviewStatus aadhaar = ReviewStatus.approved,
  String instagram = 'ananya.art',
  String pickupPincode = '',
  String line1 = '',
  String bank = '',
  String ifsc = '',
}) =>
    ArtistProfileDetails(
      fullName: 'Ananya Rao',
      email: 'ananya@example.com',
      phone: '9000000000',
      bio: 'Paints the coast.',
      instagram: instagram,
      website: '',
      bankAccountMasked: bank,
      ifsc: ifsc,
      aadhaarStatus: aadhaar,
      aadhaarMasked: '•••• •••• 4821',
      pan: pan,
      gstin: gstin,
      gstStatus: gstStatus,
      joinedAt: '2026-03-04T09:00:00.000Z',
      pickupLine1: line1,
      pickupCity: line1.isEmpty ? '' : 'Pune',
      pickupState: line1.isEmpty ? '' : 'Maharashtra',
      pickupPincode: pickupPincode,
    );

class _Artist implements ArtistRepository {
  _Artist(this.profile, {this.mou, this.failLoad = false});

  ArtistProfileDetails profile;
  final MouAcceptance? mou;
  final bool failLoad;

  final saved = <ArtistProfileDetails>[];
  final banks = <({String number, String ifsc})>[];

  @override
  Future<ArtistProfileDetails> getProfile() async {
    if (failLoad) throw Exception('The server is not reachable');
    return profile;
  }

  @override
  Future<ArtistProfileDetails> updateProfile(ArtistProfileDetails next) async {
    saved.add(next);
    profile = next;
    return next;
  }

  @override
  Future<ArtistProfileDetails> updateBankDetails({String accountNumber = '', required String ifsc}) async {
    banks.add((number: accountNumber, ifsc: ifsc));
    profile = profile.copyWith(
      bankAccountMasked: accountNumber.isEmpty ? profile.bankAccountMasked : '•••• •••• •••• ${accountNumber.substring(accountNumber.length - 4)}',
      ifsc: ifsc,
    );
    return profile;
  }

  @override
  Future<MouAcceptance?> getMouAcceptance() async => mou;

  @override
  Future<List<ArtistArtwork>> listArtworks() async => [
        ArtistArtwork(artwork: fixtureArtwork(id: 'a1', status: ArtworkStatus.marketplace), artistPrice: 40000),
        ArtistArtwork(artwork: fixtureArtwork(id: 'a2', status: ArtworkStatus.draft), artistPrice: 40000),
        ArtistArtwork(artwork: fixtureArtwork(id: 'a3', status: ArtworkStatus.pendingApproval), artistPrice: 40000),
        ArtistArtwork(artwork: fixtureArtwork(id: 'a4', status: ArtworkStatus.delivered), artistPrice: 40000),
      ];

  @override
  Future<WalletSummary> getWallet() async => const WalletSummary(balance: 30000, pendingBalance: 0, lockedBalance: 5000);

  @override
  Future<List<WalletTransaction>> listWalletTransactions() async => const [
        WalletTransaction(
          id: 't1',
          type: WalletTransactionType.settlement,
          label: 'Marketplace sale settled',
          amount: 38000,
          date: '2026-09-20T00:00:00.000Z',
          status: WalletTransactionStatus.completed,
        ),
        WalletTransaction(
          id: 't2',
          type: WalletTransactionType.settlement,
          label: 'Marketplace sale settled',
          amount: 22000,
          date: '2026-09-25T00:00:00.000Z',
          status: WalletTransactionStatus.completed,
        ),
        WalletTransaction(
          id: 't3',
          type: WalletTransactionType.withdrawal,
          label: 'Withdrawal to bank',
          amount: -5000,
          date: '2026-09-26T00:00:00.000Z',
          status: WalletTransactionStatus.pending,
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No reviews yet, answered at once (the offline mock waits half a second, which
/// a test would have to sit out).
class _Network implements ArtistNetworkRepository {
  @override
  Future<ArtistRating> getRating(String artistId) async =>
      ArtistRating(artistId: artistId, average: 0, count: 0, breakdown: const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, _Artist repository) async {
  tester.view.physicalSize = const Size(390 * 3, 3600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artistRepositoryProvider.overrideWithValue(repository),
        artistNetworkRepositoryProvider.overrideWithValue(_Network()),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ArtistKycScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  // The GSTIN has its own label row above it, so it is found by its hint.
  final field = label == 'GSTIN'
      ? find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '22AAAAA0000A1Z5')
      : find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, text);
  await tester.pump();
}

/// A field that refuses pastes takes its digits one at a time.
Future<void> _typeSlowly(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.pump();
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
  }
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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

  group('the rules behind the forms', () {
    test('an account number is 9-18 digits and not a test entry', () {
      expect(bankAccountNumberInvalid(''), isFalse, reason: 'nothing typed is not wrong, just not there yet');
      expect(bankAccountNumberInvalid('50100234567812'), isFalse);
      expect(bankAccountNumberInvalid('321654987012'), isFalse);
      expect(bankAccountNumberInvalid('12345678'), isTrue, reason: 'too short');
      expect(bankAccountNumberInvalid('1234567890123456789'), isTrue, reason: 'too long');
      expect(bankAccountNumberInvalid('12345678a9'), isTrue);
      expect(bankAccountNumberInvalid('111111111111'), isTrue, reason: 'one digit repeated');
      expect(bankAccountNumberInvalid('123456789012'), isTrue, reason: 'a straight run up');
      expect(bankAccountNumberInvalid('987654321098'), isTrue, reason: 'a straight run down');
    });

    test('PAN, IFSC and pincode shapes', () {
      expect(panPattern.hasMatch('ABCDE1234F'), isTrue);
      expect(panPattern.hasMatch('ABCDE12345'), isFalse);
      expect(panPattern.hasMatch('abcde1234f'), isFalse, reason: 'the field upper-cases before it is checked');
      expect(ifscPattern.hasMatch('HDFC0001234'), isTrue);
      expect(ifscPattern.hasMatch('HDFC1001234'), isFalse, reason: 'the fifth character is always a zero');
      expect(pincodePattern.hasMatch('313001'), isTrue);
      expect(pincodePattern.hasMatch('013001'), isFalse, reason: 'no pincode starts with 0');
      expect(pincodePattern.hasMatch('31300'), isFalse);
    });

    test('the private figures come from settlements, the wallet and the drafts', () {
      final stats = artistPrivateStatsFor(
        transactions: const [
          WalletTransaction(
            id: '1',
            type: WalletTransactionType.settlement,
            label: 's',
            amount: 38001,
            date: '2026-09-20T00:00:00.000Z',
            status: WalletTransactionStatus.completed,
          ),
          WalletTransaction(
            id: '2',
            type: WalletTransactionType.settlement,
            label: 's',
            amount: 22000,
            date: '2026-09-21T00:00:00.000Z',
            status: WalletTransactionStatus.completed,
          ),
          WalletTransaction(
            id: '3',
            type: WalletTransactionType.settlement,
            label: 'not yet',
            amount: 99999,
            date: '2026-09-22T00:00:00.000Z',
            status: WalletTransactionStatus.pending,
          ),
        ],
        wallet: const WalletSummary(balance: 1, pendingBalance: 0, lockedBalance: 5000),
        artworks: [
          ArtistArtwork(artwork: fixtureArtwork(status: ArtworkStatus.draft), artistPrice: 1),
          ArtistArtwork(artwork: fixtureArtwork(status: ArtworkStatus.pendingApproval), artistPrice: 1),
          ArtistArtwork(artwork: fixtureArtwork(status: ArtworkStatus.marketplace), artistPrice: 1),
        ],
      );
      expect(stats.earned, 60001);
      expect(stats.pending, 5000);
      expect(stats.averageSale, 30001, reason: 'rounded: 60001 / 2');
      expect(stats.drafts, 2, reason: 'drafts and work awaiting review');
    });

    test('the public figures count what collectors can see', () {
      final stats = artistPublicStatsFor([
        for (final status in [
          ArtworkStatus.marketplace,
          ArtworkStatus.marketplace,
          ArtworkStatus.sold,
          ArtworkStatus.delivered,
          ArtworkStatus.withAggregator,
          ArtworkStatus.draft,
          ArtworkStatus.soldExternally,
        ])
          ArtistArtwork(artwork: fixtureArtwork(status: status), artistPrice: 1),
      ]);
      expect(stats, (listed: 2, sold: 2, atGalleries: 1));
    });

    test('the join date reads as a month and a year', () {
      expect(joinedLabelFor('2026-03-04T09:00:00.000Z'), 'March 2026');
      expect(joinedLabelFor(''), '—');
    });
  });

  group('the profile page', () {
    testWidgets('asks for a PAN, and will not save without one', (tester) async {
      final repository = _Artist(_profile());
      await _open(tester, repository);

      expect(find.text('Add your PAN.'), findsOneWidget);
      await _tap(tester, 'Save profile');
      expect(find.text('PAN is required before you can list artwork.'), findsOneWidget);
      expect(repository.saved, isEmpty);

      await _type(tester, 'PAN (admin-only · required)', 'abc');
      expect(find.text("That doesn't look like a valid PAN."), findsOneWidget);
    });

    testWidgets('saves the profile with the PAN in capitals and says so', (tester) async {
      final repository = _Artist(_profile());
      await _open(tester, repository);

      await _type(tester, 'PAN (admin-only · required)', 'abcde1234f');
      await _type(tester, 'Bio', 'Paints the coast, and the rain.');
      await _tap(tester, 'Save profile');

      final sent = repository.saved.single;
      expect(sent.pan, 'ABCDE1234F');
      expect(sent.bio, 'Paints the coast, and the rain.');
      expect(sent.instagram, 'ananya.art');
      expect(sent.gstin, isNull, reason: 'GST is optional');
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Add your PAN.'), findsNothing, reason: 'the reminder goes once it is on file');
    });

    testWidgets('an Instagram handle is required, and a GSTIN that is typed must be well formed', (tester) async {
      final repository = _Artist(_profile(pan: 'ABCDE1234F', instagram: ''));
      await _open(tester, repository);

      await _type(tester, 'GSTIN', '22AAAAA0000A1');
      await _tap(tester, 'Save profile');
      expect(find.text('Add your Instagram handle'), findsOneWidget);
      expect(find.textContaining("doesn't look like a valid GSTIN"), findsOneWidget);
      expect(repository.saved, isEmpty);

      await _type(tester, 'Instagram handle (required, private)', 'ananya.art');
      await _type(tester, 'GSTIN', '22aaaaa0000a1z5');
      await _tap(tester, 'Save profile');
      expect(repository.saved.single.gstin, '22AAAAA0000A1Z5');
      expect(repository.saved.single.instagram, 'ananya.art');
    });

    testWidgets('shows where the GST number stands', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F', gstin: '22AAAAA0000A1Z5', gstStatus: ReviewStatus.submitted)));
      expect(find.text('Pending GalleryZone approval'), findsOneWidget);
      expect(find.textContaining('Your GST registration is with GalleryZone for review'), findsOneWidget);
    });

    testWidgets('the sign-in email is shown, not offered as something that would quietly do nothing', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F')));
      final email = tester.widget<TextField>(find.widgetWithText(TextField, 'Email'));
      expect(email.readOnly, isTrue);
      expect(find.text('ananya@example.com'), findsOneWidget);
    });

    testWidgets('shows Aadhaar as it really stands', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F', aadhaar: ReviewStatus.submitted)));
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('•••• •••• 4821'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('lays out both halves of the profile, labelled', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F', line1: '14 Ghat Road', pickupPincode: '411001')));

      expect(find.text('Since March 2026'), findsNothing, reason: 'it is joined with the location in one line');
      expect(find.text('Pune, Maharashtra · Since March 2026'), findsOneWidget);
      expect(find.text('WHAT COLLECTORS SEE'), findsOneWidget);
      expect(find.text('ONLY YOU SEE THIS'), findsOneWidget);
      expect(find.text('₹60,000'), findsOneWidget, reason: 'earned to date');
      expect(find.text('₹5,000'), findsOneWidget, reason: 'withdrawal pending');
      expect(find.text('₹30,000'), findsOneWidget, reason: 'average per sale');
      expect(find.text('Your prices and earnings are never shown on your public page.'), findsOneWidget);
    });
  });

  group('the agreement card', () {
    testWidgets('leads the page until the agreement is signed', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F')));
      expect(find.text('Sign the artist agreement'), findsOneWidget);
      expect(find.text('Read and sign'), findsOneWidget);
      final card = tester.getTopLeft(find.text('Sign the artist agreement')).dy;
      final summary = tester.getTopLeft(find.text('Your profile')).dy;
      expect(card, lessThan(summary));
    });

    testWidgets('settles at the foot as a record once it is signed', (tester) async {
      await _open(
        tester,
        _Artist(
          _profile(pan: 'ABCDE1234F'),
          mou: const MouAcceptance(version: '2026.3', acceptedAt: '2026-09-20T09:30:00.000Z'),
        ),
      );
      expect(find.text('Sign the artist agreement'), findsNothing);
      expect(find.text('Artist agreement'), findsOneWidget);
      expect(find.textContaining('Signed 20 September 2026 · version 2026.3'), findsOneWidget);
      expect(find.text('View the agreement'), findsOneWidget);
      final card = tester.getTopLeft(find.text('Artist agreement')).dy;
      final payout = tester.getTopLeft(find.text('Payout account')).dy;
      expect(card, greaterThan(payout));
    });
  });

  group('the pickup address', () {
    testWidgets('says why it matters until it is complete, and wants a real pincode', (tester) async {
      final repository = _Artist(_profile(pan: 'ABCDE1234F'));
      await _open(tester, repository);

      expect(find.textContaining('Add this before your first sale.'), findsOneWidget);
      await _type(tester, 'PIN code', '12345');
      expect(find.text('A PIN code is six digits.'), findsOneWidget);
      expect(_enabled(tester, 'Save pickup address'), isFalse);

      await _type(tester, 'Address', '14 Ghat Road');
      await _type(tester, 'City', 'Udaipur');
      await _type(tester, 'State', 'Rajasthan');
      await _type(tester, 'PIN code', '313001');
      expect(find.textContaining('Add this before your first sale.'), findsNothing);
      await _tap(tester, 'Save pickup address');

      final sent = repository.saved.single;
      expect(sent.pickupLine1, '14 Ghat Road');
      expect(sent.pickupCity, 'Udaipur');
      expect(sent.pickupState, 'Rajasthan');
      expect(sent.pickupPincode, '313001');
      expect(sent.fullName, 'Ananya Rao', reason: 'the rest of the profile rides along untouched');
    });
  });

  group('the payout account', () {
    testWidgets('says what is on file', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F', bank: '•••• •••• •••• 6142', ifsc: 'HDFC0001234')));
      expect(find.textContaining('On file: •••• •••• •••• 6142 · HDFC0001234.'), findsOneWidget);
    });

    testWidgets('and says so when nothing is', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F')));
      expect(find.textContaining('Nothing on file yet — withdrawals need this.'), findsOneWidget);
    });

    testWidgets('the number is typed twice, and a slip shows up before any money moves', (tester) async {
      final repository = _Artist(_profile(pan: 'ABCDE1234F'));
      await _open(tester, repository);

      expect(_enabled(tester, 'Save payout account'), isFalse, reason: 'nothing to save yet');

      await _type(tester, 'Account number', '12345678');
      expect(find.textContaining('Enter the real 9–18 digit account number'), findsOneWidget);
      await _type(tester, 'Account number', '50100234567812');
      expect(find.textContaining('Enter the real 9–18 digit account number'), findsNothing);
      expect(_enabled(tester, 'Save payout account'), isFalse, reason: 'not yet typed a second time');

      await _typeSlowly(tester, 'Re-enter account number', '5010023456781');
      expect(find.text('The two account numbers don’t match.'), findsOneWidget);
      expect(_enabled(tester, 'Save payout account'), isFalse);

      await _typeSlowly(tester, 'Re-enter account number', '50100234567812');
      expect(find.text('The two account numbers don’t match.'), findsNothing);
      await _type(tester, 'IFSC', 'hdfc0001234');
      await _tap(tester, 'Save payout account');

      expect(repository.banks.single, (number: '50100234567812', ifsc: 'HDFC0001234'));
      expect(find.text('Saved'), findsOneWidget);
      expect(find.textContaining('On file: •••• •••• •••• 7812 · HDFC0001234.'), findsOneWidget);
      final number = tester.widget<TextField>(find.widgetWithText(TextField, 'Account number'));
      expect(number.controller!.text, isEmpty, reason: 'the full number is never kept on screen');
    });

    testWidgets('a pasted second entry is refused', (tester) async {
      await _open(tester, _Artist(_profile(pan: 'ABCDE1234F')));
      await _type(tester, 'Account number', '50100234567812');
      await _type(tester, 'Re-enter account number', '50100234567812');
      final again = tester.widget<TextField>(find.widgetWithText(TextField, 'Re-enter account number'));
      expect(again.controller!.text, isEmpty, reason: 'fourteen digits in one go is a paste');
    });

    testWidgets('the IFSC can be corrected without retyping the account number', (tester) async {
      final repository = _Artist(_profile(pan: 'ABCDE1234F', bank: '•••• •••• •••• 6142', ifsc: 'HDFC0001234'));
      await _open(tester, repository);

      await _type(tester, 'IFSC', 'HDFC00');
      expect(find.text('IFSC looks like HDFC0001234.'), findsOneWidget);
      expect(_enabled(tester, 'Save payout account'), isFalse);
      await _type(tester, 'IFSC', 'SBIN0004321');
      await _tap(tester, 'Save payout account');
      expect(repository.banks.single, (number: '', ifsc: 'SBIN0004321'));
    });
  });

  testWidgets('a profile that will not load says so and can be retried', (tester) async {
    await _open(tester, _Artist(_profile(), failLoad: true));
    expect(find.text("Couldn't load your profile"), findsOneWidget);
    expect(find.text('The server is not reachable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
