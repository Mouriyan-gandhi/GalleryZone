import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The August meeting's Batch A rules, ported from `frontend-web`'s
/// `types/artwork.check.ts` plus the repository behaviour that reads them.
final _now = DateTime.utc(2026, 8, 20);

Artwork _listed(ArtworkStatus status, int daysAgo) => Artwork(
  id: 'aw-test',
  title: 'Test piece',
  artistId: 'artist-1',
  artistName: 'Test Artist',
  verifiedArtist: true,
  category: 'painting',
  medium: 'Oil on Canvas',
  customerPrice: 100000,
  thumbnailUrl: '',
  insured: false,
  status: status,
  listingType: ListingType.marketplaceOnly,
  description: '',
  images: const [],
  coaCertificateNumber: 'GZ-COA-TEST',
  coaIssueDate: '2026-08-01',
  socialProofLinks: const [],
  statusHistory: [
    ArtworkStatusEvent(
      status: status,
      changedAt: _now.subtract(Duration(days: daysAgo)).toIso8601String(),
    ),
  ],
);

SubmitArtworkInput _input({
  bool asDraft = false,
  ListingType listingType = ListingType.marketplaceOnly,
  String title = 'New piece',
}) => SubmitArtworkInput(
  title: title,
  description: 'Test piece.',
  category: 'painting',
  medium: 'Oil on Canvas',
  artistPrice: 20000,
  listingType: listingType,
  insuranceOpted: false,
  images: const [
    ArtworkImage(
      url: '/artworks/bird.png',
      thumbnailUrl: '/artworks/bird.png',
      sortOrder: 0,
      altText: 'New piece',
    ),
  ],
  asDraft: asDraft,
);

void main() {
  group('edit window', () {
    test('7 days from listing, counting down', () {
      final fresh = artworkEditState(_listed(ArtworkStatus.marketplace, 2), now: _now);
      expect(fresh.editable, isTrue);
      expect(fresh.daysLeft, 5);
    });

    test('closes after the window, and on the boundary day', () {
      final stale = artworkEditState(_listed(ArtworkStatus.marketplace, 8), now: _now);
      expect(stale.editable, isFalse);
      expect(stale.reason, ArtworkEditReason.windowClosed);

      final edge = artworkEditState(
        _listed(ArtworkStatus.marketplace, artworkEditWindowDays),
        now: _now,
      );
      expect(edge.editable, isFalse);
    });

    test('a purchase inside the window overrides the days remaining', () {
      final sold = artworkEditState(_listed(ArtworkStatus.sold, 2), now: _now);
      expect(sold.editable, isFalse);
      expect(sold.reason, ArtworkEditReason.purchased);
      expect(artworkEditState(_listed(ArtworkStatus.reserved, 1), now: _now).editable, isFalse);
    });

    test("a draft's clock hasn't started", () {
      expect(artworkEditState(_listed(ArtworkStatus.draft, 99), now: _now).editable, isTrue);
    });
  });

  group('sales channels', () {
    test('the predicates, not a literal comparison', () {
      expect(isMarketplaceListed(ListingType.marketplaceOnly), isTrue);
      expect(isMarketplaceListed(ListingType.aggregatorOnly), isFalse);
      expect(isMarketplaceListed(ListingType.marketplaceAndAggregator), isTrue);
      expect(isAggregatorListed(ListingType.marketplaceOnly), isFalse);
      expect(isAggregatorListed(ListingType.aggregatorOnly), isTrue);
      expect(isAggregatorListed(ListingType.marketplaceAndAggregator), isTrue);
    });
  });

  group('custody', () {
    test('derives from status when the record carries none', () {
      final derived = resolveCustody(_listed(ArtworkStatus.withAggregator, 30));
      expect(derived.legalOwner, CustodyParty.artist);
      expect(derived.custodian, CustodyParty.aggregator);
    });

    test('a stored custody wins over the derived one', () {
      final explicit = _listed(ArtworkStatus.marketplace, 1).copyWith(
        custody: const ArtworkCustody(
          legalOwner: CustodyParty.galleryzone,
          custodian: CustodyParty.aggregator,
          locationLabel: 'Bengaluru',
        ),
      );
      expect(resolveCustody(explicit).legalOwner, CustodyParty.galleryzone);
      expect(resolveCustody(explicit).locationLabel, 'Bengaluru');
    });
  });

  group('against the mock repositories', () {
    late MockArtistRepository artist;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      MockDb.resetForTesting();
      await MockDb.init();
      artist = MockArtistRepository();
    });

    test('an aggregator-only piece never reaches the marketplace grid', () async {
      final submitted = await artist.submitArtwork(_input(listingType: ListingType.aggregatorOnly));
      expect(isMarketplaceListed(submitted.listingType), isFalse);
      // Insurance is not the artist's call once the piece leaves the studio.
      expect(submitted.insured, isTrue);

      final browsable = await MockArtworkRepository().list(const ArtworkFilters());
      expect(browsable.map((a) => a.id), isNot(contains(submitted.id)));
    });

    test('marking a piece sold elsewhere pulls it from every channel', () async {
      final before = await MockArtworkRepository().list(const ArtworkFilters());
      expect(before.map((a) => a.id), contains('aw-1'));

      final withdrawn = await artist.markSoldElsewhere('aw-1');
      expect(withdrawn.status, ArtworkStatus.soldExternally);
      expect(withdrawn.statusHistory.last.status, ArtworkStatus.soldExternally);

      final after = await MockArtworkRepository().list(const ArtworkFilters());
      expect(after.map((a) => a.id), isNot(contains('aw-1')));
      // The passport must still resolve — a tag on the wall outlives the listing.
      expect(await MockArtworkRepository().get('aw-1'), isNotNull);
    });

    test('the withdrawal fee is 1% of the listed price, charged on the next listing', () async {
      final withdrawn = await artist.markSoldElsewhere('aw-1');
      final penalties = await artist.listPenalties();
      expect(penalties, hasLength(1));
      expect(penalties.single.amount, (withdrawn.customerPrice * 0.01).roundToDouble());
      expect(penalties.single.settledAt, isNull);

      // A draft is not a listing, so it doesn't trigger collection.
      await artist.submitArtwork(_input(asDraft: true, title: 'A draft'));
      expect((await artist.listPenalties()).single.settledAt, isNull);

      final balanceBefore = (await artist.getWallet()).balance;
      await artist.submitArtwork(_input(title: 'A real listing'));
      final settled = (await artist.listPenalties()).single;
      expect(settled.settledAt, isNotNull);
      expect((await artist.getWallet()).balance, balanceBefore - settled.amount);
      final transactions = await artist.listWalletTransactions();
      expect(transactions.first.amount, -settled.amount);
    });

    test('a piece GalleryZone has a claim on cannot be withdrawn', () async {
      await artist.markSoldElsewhere('aw-1');
      // Already gone: withdrawing twice is refused rather than charged twice.
      expect(artist.markSoldElsewhere('aw-1'), throwsA(isA<Exception>()));
      expect(await artist.listPenalties(), hasLength(1));
    });

    test('an edit inside the window saves; a locked piece is refused', () async {
      final draft = await artist.submitArtwork(_input(asDraft: true, title: 'Editable'));
      final updated = await artist.updateArtwork(
        artworkId: draft.id,
        patch: _input(title: 'Renamed', listingType: ListingType.marketplaceAndAggregator),
      );
      expect(updated.title, 'Renamed');
      expect(updated.listingType, ListingType.marketplaceAndAggregator);
      expect(updated.insured, isTrue, reason: 'aggregator channel forces insurance');

      // aw-4 is a delivered piece in the artist's own seed — past every window.
      final locked = (await artist.listArtworks())
          .map((entry) => entry.artwork)
          .firstWhere((a) => !artworkEditState(a).editable);
      expect(
        artist.updateArtwork(artworkId: locked.id, patch: _input()),
        throwsA(isA<Exception>()),
      );
    });
  });
}
