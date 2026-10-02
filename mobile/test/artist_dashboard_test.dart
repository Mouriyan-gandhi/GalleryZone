import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artist_dashboard_screen.dart';
import 'package:gallery_zone/features/artist/verification_tiers.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';

ArtistProfileDetails _profile({String instagram = '', String website = '', FreeAccess? freeAccess}) => ArtistProfileDetails(
      fullName: 'Ananya Rao',
      email: 'a@b.co',
      phone: '9000000000',
      bio: '',
      instagram: instagram,
      website: website,
      bankAccountMasked: '',
      ifsc: '',
      aadhaarStatus: ReviewStatus.notSubmitted,
      aadhaarMasked: '',
      freeAccess: freeAccess,
    );

ArtistArtwork _entry(ArtworkStatus status, {List<ArtworkStatusEvent> history = const []}) =>
    ArtistArtwork(artwork: fixtureArtwork(status: status, history: history), artistPrice: 40000);

Settlement _settlement(SettlementStatus status) => Settlement(
      id: 's-${status.name}',
      orderId: 'o-1',
      artworkTitle: 'Monsoon, Madurai',
      artistName: 'Ananya Rao',
      artistAmount: 38000,
      aggregatorCommission: 0,
      platformRevenue: 2000,
      status: status,
      createdAt: '2026-09-01T00:00:00.000Z',
    );

class _Artist implements ArtistRepository {
  _Artist({this.artworks = const [], this.profile});

  final List<ArtistArtwork> artworks;
  final ArtistProfileDetails? profile;

  @override
  Future<List<ArtistArtwork>> listArtworks() async => artworks;

  @override
  Future<ArtistProfileDetails> getProfile() async => profile ?? _profile();

  @override
  Future<MouAcceptance?> getMouAcceptance() async => null;

  @override
  Future<List<Settlement>> listSettlements() async => [_settlement(SettlementStatus.processed)];

  @override
  Future<List<ArtistKpi>> getKpis() async => const [
        ArtistKpi(label: 'Total revenue', value: '₹0', delta: 'No sales settled yet', positive: false),
        ArtistKpi(label: 'Wallet balance', value: '₹0', delta: 'Available to withdraw', positive: true),
        ArtistKpi(label: 'Pending approval', value: '1', delta: 'Awaiting admin review', positive: false),
      ];

  @override
  Future<List<ActivityEntry>> listActivity() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('the verification ladder is worked out from the account', () {
    test('a handle ticks the first rung and opens the second', () {
      final tiers = verificationTiersFor(profile: _profile(instagram: '@ananya'), mou: null, artworks: const []);
      expect(tiers.map((t) => t.status), [
        VerificationTierStatus.complete,
        VerificationTierStatus.active,
        VerificationTierStatus.locked,
      ]);
    });

    test('a website counts as a handle, and nothing counts as nothing', () {
      expect(
        verificationTiersFor(profile: _profile(website: 'https://ananya.art'), mou: null, artworks: const []).first.status,
        VerificationTierStatus.complete,
      );
      expect(
        verificationTiersFor(profile: _profile(), mou: null, artworks: const []).first.status,
        VerificationTierStatus.active,
      );
    });

    test('the signed agreement is rung two, dated by when it was signed', () {
      final tiers = verificationTiersFor(
        profile: _profile(instagram: '@ananya'),
        mou: const MouAcceptance(version: '2026.3', acceptedAt: '2026-09-20T09:30:00.000Z'),
        artworks: const [],
      );
      expect(tiers[1].status, VerificationTierStatus.complete);
      expect(tiers[1].completedOn, '2026-09-20');
      expect(tiers[2].status, VerificationTierStatus.active);
    });

    test('the first sale is the earliest sold event across every artwork', () {
      final tiers = verificationTiersFor(
        profile: _profile(instagram: '@ananya'),
        mou: const MouAcceptance(version: '2026.3', acceptedAt: '2026-09-20T09:30:00.000Z'),
        artworks: [
          _entry(
            ArtworkStatus.delivered,
            history: const [
              ArtworkStatusEvent(status: ArtworkStatus.sold, changedAt: '2026-10-01T00:00:00.000Z'),
            ],
          ),
          _entry(
            ArtworkStatus.sold,
            history: const [
              ArtworkStatusEvent(status: ArtworkStatus.sold, changedAt: '2026-09-25T00:00:00.000Z'),
            ],
          ),
        ],
      );
      expect(tiers[2].status, VerificationTierStatus.complete);
      expect(tiers[2].completedOn, '2026-09-25');
    });

    test('a piece sold outside GalleryZone is not a GalleryZone sale', () {
      final tiers = verificationTiersFor(
        profile: _profile(instagram: '@ananya'),
        mou: const MouAcceptance(version: '2026.3', acceptedAt: '2026-09-20T09:30:00.000Z'),
        artworks: [
          _entry(
            ArtworkStatus.soldExternally,
            history: const [
              ArtworkStatusEvent(status: ArtworkStatus.soldExternally, changedAt: '2026-09-25T00:00:00.000Z'),
            ],
          ),
        ],
      );
      expect(tiers[2].status, VerificationTierStatus.active);
    });
  });

  group('what needs attention', () {
    test('lists drafts, work in review, unpaid settlements and the badge still to earn, in that order', () {
      final tiers = verificationTiersFor(profile: _profile(), mou: null, artworks: const []);
      final items = attentionItemsFor(
        artworks: [
          _entry(ArtworkStatus.draft),
          _entry(ArtworkStatus.draft),
          _entry(ArtworkStatus.pendingApproval),
        ],
        settlements: [_settlement(SettlementStatus.pending), _settlement(SettlementStatus.processed)],
        tiers: tiers,
      );
      expect(items.map((i) => i.message), [
        '2 artworks still in draft',
        '1 artwork awaiting curator review',
        '1 settlement pending payout',
        'Complete your first sale to unlock the Gold ✦ Verified badge',
      ]);
      expect(items.first.path, '/dashboard/artworks');
      expect(items[2].path, '/dashboard/settlements');
    });

    test('an artist with the badge and nothing waiting is all caught up', () {
      final tiers = verificationTiersFor(
        profile: _profile(instagram: '@a'),
        mou: const MouAcceptance(version: '2026.3', acceptedAt: '2026-09-20T09:30:00.000Z'),
        artworks: [
          _entry(
            ArtworkStatus.completed,
            history: const [ArtworkStatusEvent(status: ArtworkStatus.sold, changedAt: '2026-09-25T00:00:00.000Z')],
          ),
        ],
      );
      expect(attentionItemsFor(artworks: const [], settlements: const [], tiers: tiers), isEmpty);
    });
  });

  test('the greeting follows the phone\'s clock', () {
    expect(ArtistDashboardScreen.greeting(DateTime(2026, 10, 2, 9)), 'Good morning');
    expect(ArtistDashboardScreen.greeting(DateTime(2026, 10, 2, 12)), 'Good afternoon');
    expect(ArtistDashboardScreen.greeting(DateTime(2026, 10, 2, 17)), 'Good evening');
  });

  testWidgets('the dashboard shows the free period, what is next, the artworks at a glance and the figures',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repository = _Artist(
      artworks: [_entry(ArtworkStatus.marketplace), _entry(ArtworkStatus.draft), _entry(ArtworkStatus.draft)],
      profile: _profile(
        instagram: '@ananya',
        freeAccess: const FreeAccess(until: '2027-03-20T00:00:00.000Z', months: 6),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          artistRepositoryProvider.overrideWithValue(repository),
          initialRoleProvider.overrideWithValue(null),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ArtistDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Free access to every premium feature, for your first six months.', findRichText: true), findsOneWidget);
    expect(find.textContaining('It runs until 20 March 2027.', findRichText: true), findsOneWidget);
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('2 artworks still in draft'), findsNWidgets(2), reason: 'next up, and the attention list');
    expect(find.text('Your artworks'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Sold'), findsNothing, reason: 'groups with nothing in them are left out');
    expect(find.text('Wallet balance'), findsOneWidget);
    expect(find.text('Tier 1: Social media'), findsOneWidget);
  });
}
