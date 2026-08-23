import '../../models/artist_portal.dart';
import '../../models/artwork.dart';
import '../../models/customer.dart';

/// Ported from `frontend-web/lib/mock-collections.ts`'s artist block and
/// `features/dashboard/dashboard-data.ts`. Same fixed "today" anchor as
/// every other seed file, so relative dates stay stable across runs.
final _today = DateTime.utc(2026, 8, 11);

String _daysAgo(int days) => _today.subtract(Duration(days: days)).toIso8601String();

/// The single "signed in as" artist. There is no real artist session in this
/// mock phase — same fixture the web revolves around.
const currentArtistId = 'devika-rao';
const currentArtistName = 'Devika Rao';

/// Artist→customer markup. The artist names their own price; the customer
/// price is derived, and the artist's figure never leaves artist-scoped
/// screens (SAD §8.7).
const customerMarkupMultiplier = 1.3;

const _seeds = <({
  String id,
  String title,
  String image,
  String medium,
  String category,
  int year,
  double artistPrice,
  ArtworkStatus status,
  int submittedDaysAgo,
  ArtworkRarity rarity,
})>[
  (
    id: 'aw-1',
    title: 'Monsoon Reverie',
    image: '/ecosystem/artwork-1.png',
    medium: 'Oil on Canvas',
    category: 'landscape',
    year: 2025,
    artistPrice: 28000,
    status: ArtworkStatus.marketplace,
    submittedDaysAgo: 34,
    rarity: ArtworkRarity.original,
  ),
  (
    id: 'aw-2',
    title: 'Terracotta Study No. 4',
    image: '/ecosystem/artwork-2.png',
    medium: 'Ceramic & Mixed Media',
    category: 'sculpture',
    year: 2026,
    artistPrice: 15000,
    status: ArtworkStatus.pendingApproval,
    submittedDaysAgo: 7,
    rarity: ArtworkRarity.rare,
  ),
  (
    id: 'aw-3',
    title: 'Silent Horizon',
    image: '/ecosystem/artwork-3.png',
    medium: 'Acrylic on Canvas',
    category: 'painting',
    year: 2025,
    artistPrice: 22000,
    status: ArtworkStatus.draft,
    submittedDaysAgo: 5,
    rarity: ArtworkRarity.normal,
  ),
  (
    id: 'aw-4',
    title: 'Eclipse of Thoughts',
    image: '/journey/artwork-preview.png',
    medium: 'Acrylic on Canvas',
    category: 'painting',
    year: 2024,
    artistPrice: 18000,
    status: ArtworkStatus.withAggregator,
    submittedDaysAgo: 74,
    rarity: ArtworkRarity.unique,
  ),
  (
    id: 'aw-5',
    title: 'Whispers in Bronze',
    image: '/artworks/framed-painting.png',
    medium: 'Mixed Media',
    category: 'mixed media',
    year: 2023,
    artistPrice: 32000,
    status: ArtworkStatus.sold,
    submittedDaysAgo: 119,
    rarity: ArtworkRarity.rare,
  ),
  (
    id: 'aw-6',
    title: 'Fragments of Dawn',
    image: '/artworks/landscape.png',
    medium: 'Oil on Canvas',
    category: 'landscape',
    year: 2025,
    artistPrice: 19500,
    status: ArtworkStatus.marketplace,
    submittedDaysAgo: 17,
    rarity: ArtworkRarity.original,
  ),
  (
    id: 'aw-7',
    title: 'Portrait in Amber',
    image: '/artworks/portrait-woman.png',
    medium: 'Oil on Canvas',
    category: 'portraiture',
    year: 2026,
    artistPrice: 24000,
    status: ArtworkStatus.draft,
    submittedDaysAgo: 6,
    rarity: ArtworkRarity.unique,
  ),
];

/// A submission that hasn't cleared review yet lives in the `pendingArtworks`
/// collection, never in `artworks` — the same split the web makes, so a
/// draft can't leak onto the public marketplace.
const _pendingStatuses = {ArtworkStatus.draft, ArtworkStatus.pendingApproval};

List<Artwork> _buildAll() => [
      for (final seed in _seeds)
        Artwork(
          id: seed.id,
          title: seed.title,
          artistId: currentArtistId,
          artistName: currentArtistName,
          verifiedArtist: true,
          category: seed.category,
          medium: seed.medium,
          customerPrice: (seed.artistPrice * customerMarkupMultiplier).round().toDouble(),
          thumbnailUrl: seed.image,
          insured: seed.artistPrice > 20000,
          status: seed.status,
          listingType: ListingType.marketplaceAndAggregator,
          description:
              '${seed.medium}, ${seed.year}. Submitted by $currentArtistName through '
              'the Artist Dashboard.',
          yearCreated: seed.year,
          images: [
            ArtworkImage(
              url: seed.image,
              thumbnailUrl: seed.image,
              sortOrder: 0,
              altText: seed.title,
            ),
          ],
          coaCertificateNumber: 'GZ-COA-2026-${seed.id.toUpperCase()}',
          coaIssueDate: _daysAgo(seed.submittedDaysAgo),
          socialProofLinks: const [],
          statusHistory: [
            ArtworkStatusEvent(status: seed.status, changedAt: _daysAgo(seed.submittedDaysAgo)),
          ],
          rarityType: seed.rarity,
        ),
    ];

/// The artist's approved work — merged into the public `artworks` collection.
List<Artwork> seedArtistListedArtworks() =>
    _buildAll().where((a) => !_pendingStatuses.contains(a.status)).toList();

/// Drafts and in-review submissions.
List<Artwork> seedPendingArtworks() =>
    _buildAll().where((a) => _pendingStatuses.contains(a.status)).toList();

/// The artist's own asking price per artwork id, deliberately kept OUT of
/// the `Artwork` shape — only artist-scoped repository methods read it.
Map<String, double> seedArtistPrices() => {
      for (final seed in _seeds) seed.id: seed.artistPrice,
    };

WalletSummary seedArtistWallet() =>
    const WalletSummary(balance: 42180, pendingBalance: 6400, lockedBalance: 0);

List<WalletTransaction> seedArtistWalletTransactions() => const [
      WalletTransaction(
        id: 'wt-1',
        type: WalletTransactionType.settlement,
        label: 'Settlement: "Monsoon Reverie"',
        amount: 25200,
        date: '2026-08-09',
        status: WalletTransactionStatus.completed,
      ),
      WalletTransaction(
        id: 'wt-2',
        type: WalletTransactionType.withdrawal,
        label: 'Withdrawal to bank •••6142',
        amount: -20000,
        date: '2026-08-05',
        status: WalletTransactionStatus.completed,
      ),
      WalletTransaction(
        id: 'wt-3',
        type: WalletTransactionType.settlement,
        label: 'Settlement: "Fragments of Dawn"',
        amount: 17550,
        date: '2026-07-30',
        status: WalletTransactionStatus.completed,
      ),
      WalletTransaction(
        id: 'wt-4',
        type: WalletTransactionType.settlement,
        label: 'Settlement: "Whispers in Bronze"',
        amount: 6400,
        date: '2026-08-10',
        status: WalletTransactionStatus.pending,
      ),
      WalletTransaction(
        id: 'wt-5',
        type: WalletTransactionType.withdrawal,
        label: 'Withdrawal to bank •••6142',
        amount: -15000,
        date: '2026-06-22',
        status: WalletTransactionStatus.completed,
      ),
    ];

List<ActivityEntry> seedArtistActivity() => const [
      ActivityEntry(
        id: 'act-1',
        kind: ActivityKind.artworkApproved,
        title: '"Monsoon Reverie" was approved',
        detail: 'Live on the marketplace at ₹28,000',
        time: '2 hours ago',
      ),
      ActivityEntry(
        id: 'act-2',
        kind: ActivityKind.settlement,
        title: 'Settlement received',
        detail: '₹25,200 credited after commission',
        time: 'Yesterday',
      ),
      ActivityEntry(
        id: 'act-3',
        kind: ActivityKind.artworkSubmitted,
        title: '"Terracotta Study No. 4" submitted',
        detail: 'Awaiting admin review',
        time: '2 days ago',
      ),
      ActivityEntry(
        id: 'act-4',
        kind: ActivityKind.verification,
        title: 'Tier 2 verification complete',
        detail: 'Active plan confirmed',
        time: '5 days ago',
      ),
    ];

ArtistProfileDetails seedArtistProfile() => const ArtistProfileDetails(
      fullName: currentArtistName,
      email: 'devika.rao@example.com',
      phone: '+91 98765 43210',
      bio:
          'Contemporary landscape and abstract painter based in Udaipur, working '
          'primarily in oil and acrylic. Exploring the intersection of monsoon '
          'light and memory.',
      instagram: 'devikarao.art',
      website: 'devikarao.com',
      bankAccountMasked: '•••• •••• •••• 6142',
      ifsc: 'HDFC0001234',
      aadhaarStatus: AadhaarStatus.verified,
      aadhaarMasked: '•••• •••• 4821',
    );

ArtistSettings seedArtistSettings() => const ArtistSettings(
      notifyArtworkApproved: true,
      notifyNewSale: true,
      notifyWithdrawalProcessed: true,
      notifyNewMessage: true,
    );

List<MessageThread> seedArtistMessages() => const [
      MessageThread(
        id: 'msg-1',
        from: 'GalleryZone Curation Team',
        subject: '"Terracotta Study No. 4" is pending review',
        preview: 'Your submission is with a curator for quality and authenticity review.',
        body:
            'Thanks for submitting "Terracotta Study No. 4." A curator is reviewing '
            'it for quality, authenticity, and pricing confidentiality. You\'ll be '
            'notified as soon as a decision is made — most reviews complete within '
            '2-3 business days.',
        unread: true,
        receivedAt: '2026-08-09T10:15:00.000Z',
      ),
      MessageThread(
        id: 'msg-2',
        from: 'GalleryZone Admin',
        subject: 'Additional documentation requested',
        preview: 'We need a clearer signature close-up before your KYC can be approved.',
        body:
            'Your Aadhaar and signature proof are on file, but the signature close-up '
            'photo is too blurred to verify against your Certificate of Authenticity. '
            'Please re-upload a sharper close-up from your Profile & KYC page.',
        unread: true,
        receivedAt: '2026-08-07T14:32:00.000Z',
      ),
      MessageThread(
        id: 'msg-3',
        from: 'GalleryZone Insurance Desk',
        subject: 'Consider transit insurance for high-value pieces',
        preview:
            'Artworks valued above ₹20,000 are strongly recommended for transit insurance.',
        body:
            'A couple of your listed pieces are priced above ₹20,000. Transit insurance '
            '(partnered with HDFC ERGO) protects you against unforeseen damage in '
            'shipping — uninsured artworks bear no platform liability if something goes '
            'wrong in transit.',
        unread: false,
        receivedAt: '2026-08-02T09:00:00.000Z',
      ),
      MessageThread(
        id: 'msg-4',
        from: 'GalleryZone Settlements',
        subject: 'Settlement processed for "Whispers in Bronze"',
        preview: 'Your payout has been credited to your GalleryZone wallet.',
        body:
            'Good news — "Whispers in Bronze" sold, and your settlement has been '
            'processed and credited to your wallet. You can withdraw to your linked '
            'bank account any time above the ₹1,000 minimum.',
        unread: false,
        receivedAt: '2026-07-20T11:45:00.000Z',
      ),
      MessageThread(
        id: 'msg-5',
        from: 'GalleryZone Team',
        subject: 'Welcome to GalleryZone',
        preview: "Your artist account is set up — here's what happens next.",
        body:
            'Welcome! Your profile is live. Submit your first artwork from My Artworks, '
            'keep your bank details current in Profile & KYC, and check Verification to '
            'unlock the Gold badge after your first sale.',
        unread: false,
        receivedAt: '2026-07-05T08:00:00.000Z',
      ),
    ];

List<Settlement> seedArtistSettlements() => [
      Settlement(
        id: 'settle-devika-1',
        orderId: 'order-seed-aw-5',
        artworkTitle: 'Whispers in Bronze',
        artistName: currentArtistName,
        artistAmount: (32000 * 0.98).round().toDouble(),
        aggregatorCommission: 0,
        platformRevenue: (32000 * 0.02).round().toDouble(),
        status: SettlementStatus.processed,
        createdAt: _daysAgo(119),
        processedAt: _daysAgo(118),
      ),
    ];

/// The public aggregator fixtures reference none of this artist's work, so
/// her already-`with_aggregator` piece (aw-4) needs its own holding or the
/// Gallery Spaces screen would always be empty despite that status existing.
List<AggregatorHolding> seedArtistHoldings() => [
      AggregatorHolding(
        id: 'hold-devika-1',
        artworkId: 'aw-4',
        advancePercent: 5,
        advanceAmount: (18000 * 1.3 * 0.05).round().toDouble(),
        displayPrice: (18000 * 1.3).round().toDouble(),
        assignedAt: '2026-07-24T00:00:00.000Z',
        expiresAt: '2026-08-23T00:00:00.000Z',
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.gzAssigned,
      ),
    ];

List<SupportTicket> seedArtistSupportTickets() => const [
      SupportTicket(
        id: 'ticket-1',
        subject: 'Question about insurance for high-value pieces',
        message:
            'One of my pieces is priced above ₹20,000 — can you confirm the HDFC ERGO '
            'transit insurance is opt-in per artwork, not per account?',
        status: SupportTicketStatus.answered,
        createdAt: '2026-07-28T09:20:00.000Z',
      ),
    ];

/// Display-only: nothing in this phase mutates the revenue history or the
/// verification ladder.
List<RevenuePoint> artistRevenueSeries() => const [
      RevenuePoint(month: 'Mar', amount: 62000),
      RevenuePoint(month: 'Apr', amount: 78500),
      RevenuePoint(month: 'May', amount: 71200),
      RevenuePoint(month: 'Jun', amount: 96800),
      RevenuePoint(month: 'Jul', amount: 118400),
      RevenuePoint(month: 'Aug', amount: 184320),
    ];

List<VerificationTier> artistVerificationTiers() => const [
      VerificationTier(
        tier: 1,
        title: 'Social media',
        description: 'Linked an official handle to authenticate your identity.',
        detail:
            'Link at least one official social media handle (Instagram, YouTube, or a '
            "personal site) so collectors can verify you're a real, active artist.",
        status: VerificationTierStatus.complete,
        completedOn: '2026-02-14',
      ),
      VerificationTier(
        tier: 2,
        title: 'Active plan',
        description: 'Maintained an active plan for 3 months.',
        detail:
            'Keep an active GalleryZone plan for 3 consecutive months. This is free '
            'with the physical/aggregator listing model.',
        status: VerificationTierStatus.complete,
        completedOn: '2026-05-20',
      ),
      VerificationTier(
        tier: 3,
        title: 'First sale',
        description: 'Complete your first confirmed sale on GalleryZone.',
        detail:
            'Sell one artwork through the marketplace or an aggregator. Once confirmed, '
            "you'll unlock the Gold ✦ Verified badge shown on your public profile and "
            'listings.',
        status: VerificationTierStatus.active,
      ),
    ];
