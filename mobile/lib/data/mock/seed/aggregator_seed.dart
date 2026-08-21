import '../../models/aggregator.dart';
import '../../models/artist_portal.dart';
import '../../models/customer.dart';
import 'artist_seed.dart' show seedArtistHoldings;

/// Ported from `frontend-web/lib/mock-data/aggregator-holdings.ts` and the
/// aggregator block of `lib/mock-collections.ts`.

/// The fixed "today" every holding fixture is generated against, matching the
/// web's `MOCK_TODAY` and the anchor the other seed files use. The seeded
/// holdings deliberately spread from "expires in 2 days" to "expires in 25
/// days"; measuring that spread against the real wall clock would silently
/// collapse it as actual time passes — three of the six read as expired
/// within a fortnight of the anchor. Every screen showing a holding's
/// remaining days reads "now" from here, on both the aggregator side and the
/// artist's Gallery Spaces screen.
final fixtureToday = DateTime.utc(2026, 8, 11);

/// The single "signed in as" aggregator — no real aggregator session exists
/// in this mock phase, same as [currentArtistName] on the artist side.
const currentAggregatorName = 'Verandah Art House';
const currentAggregatorContact = 'Meher Chatterjee';

String _daysFromToday(int offset) =>
    fixtureToday.add(Duration(days: offset)).toIso8601String();

/// Six holdings, mixed 5%/3% advance, expiry spread from 2 to 25 days out so
/// the collection screen's countdown has both urgent and comfortable cases,
/// one already sold and awaiting settlement. Every `artworkId` here must
/// resolve to a `marketplaceAndAggregator` artwork in `artworks_seed.dart`;
/// the web enforces that with a throw at module load, which Dart has no
/// equivalent of, so `test/aggregator_test.dart` asserts it instead.
List<AggregatorHolding> _publicHoldings() => [
      AggregatorHolding(
        id: 'hold-1',
        artworkId: 'ancestral-bronze-study',
        advancePercent: 5,
        advanceAmount: 6400,
        displayPrice: 128000,
        assignedAt: _daysFromToday(-5),
        expiresAt: _daysFromToday(25),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.gzAssigned,
      ),
      AggregatorHolding(
        id: 'hold-2',
        artworkId: 'balcony-seats-empty-reel',
        advancePercent: 3,
        advanceAmount: 492,
        displayPrice: 17200,
        assignedAt: _daysFromToday(-18),
        expiresAt: _daysFromToday(12),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.selfReserved,
      ),
      AggregatorHolding(
        id: 'hold-3',
        artworkId: 'college-street-folio',
        advancePercent: 5,
        advanceAmount: 710,
        displayPrice: 14200,
        assignedAt: _daysFromToday(-24),
        expiresAt: _daysFromToday(6),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.gzAssigned,
      ),
      AggregatorHolding(
        id: 'hold-4',
        artworkId: 'density-study-karol-bagh',
        advancePercent: 3,
        advanceAmount: 786,
        displayPrice: 28500,
        assignedAt: _daysFromToday(-28),
        expiresAt: _daysFromToday(2),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.selfReserved,
      ),
      AggregatorHolding(
        id: 'hold-5',
        artworkId: 'rust-and-ochre-wall-piece',
        advancePercent: 5,
        advanceAmount: 2900,
        displayPrice: 58000,
        assignedAt: _daysFromToday(-12),
        expiresAt: _daysFromToday(18),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.gzAssigned,
      ),
      AggregatorHolding(
        id: 'hold-6',
        artworkId: 'salvaged-frequencies',
        advancePercent: 3,
        advanceAmount: 1335,
        displayPrice: 44500,
        assignedAt: _daysFromToday(-37),
        expiresAt: _daysFromToday(-7),
        status: HoldingStatus.soldPendingSettlement,
        assignmentSource: AssignmentSource.selfReserved,
      ),
    ];

/// The one shared seed for the `holdings` collection: the public aggregator
/// fixtures plus the artist's own placed piece. **Every repository that
/// reads `holdings` must seed it through this function.** An earlier version
/// of the artist repository seeded the collection with only its own holding,
/// which then persisted a six-piece-short collection for whichever
/// repository happened to touch it first — the same trap
/// `seedArtworksCollection()` exists to close.
List<AggregatorHolding> seedHoldingsCollection() => [
      ..._publicHoldings(),
      ...seedArtistHoldings(),
    ];

List<GallerySpace> seedGallerySpaces() => const [
      GallerySpace(
        id: 'space-1',
        name: '$currentAggregatorName — Main Gallery',
        addressLine1: '14 Church Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
        capacity: 12,
        coordinatorName: currentAggregatorContact,
      ),
    ];

AggregatorProfile seedAggregatorProfile() => const AggregatorProfile(
      companyName: currentAggregatorName,
      contactPerson: currentAggregatorContact,
      avatar: '/early-program/avatar-2.png',
      gstNumber: '29ABCDE1234F1Z5',
      phone: '+91 98450 12345',
      addressLine1: '14 Church Street, Bengaluru, Karnataka 560001',
      bankAccountMasked: '•••• •••• •••• 4821',
      ifsc: 'HDFC0001234',
      securityDepositStatus: 'active',
    );

AggregatorSettings seedAggregatorSettings() => const AggregatorSettings(
      notifyNewAssignment: true,
      notifySaleRecorded: true,
      notifySettlementProcessed: true,
      notifyExpiryReminder: true,
    );

/// The wallet starts empty: every rupee in it is earned by recording a sale
/// and settling it in-session. Nothing is pre-credited, so the numbers on
/// screen always trace back to an action taken in the app.
WalletSummary seedAggregatorWallet() =>
    const WalletSummary(balance: 0, pendingBalance: 0, lockedBalance: 0);

List<MessageThread> seedAggregatorMessages() => const [
      MessageThread(
        id: 'agg-msg-1',
        from: 'GalleryZone Audit Team',
        subject: 'Scheduled inventory audit — Verandah Art House',
        preview:
            'A GalleryZone auditor will visit on 18 Aug 2026 to reconcile on-premises '
            'inventory.',
        body:
            'Per MOU §8, GalleryZone will conduct a physical inventory audit at your '
            'premises on 18 Aug 2026 between 10:00–14:00 IST. Please ensure all '
            'GalleryZone-assigned pieces are accessible and match your My Inventory '
            'register. Contact your coordinator if any piece is in transit.',
        unread: true,
        receivedAt: '2026-08-10T09:00:00.000Z',
      ),
      MessageThread(
        id: 'agg-msg-2',
        from: 'GalleryZone Custody Desk',
        subject: '"Density Study, Karol Bagh" custody expires in 2 days',
        preview: 'The 30-day display window for this reserved piece ends on 13 Aug 2026.',
        body:
            '"Density Study, Karol Bagh" (holding hold-4) expires on 13 Aug 2026. '
            'Record a sale before expiry or request a return shipment from Shipping — '
            'unreturned pieces after expiry may incur custody fees per MOU §4.',
        unread: true,
        receivedAt: '2026-08-11T08:30:00.000Z',
      ),
      MessageThread(
        id: 'agg-msg-3',
        from: 'GalleryZone Insurance Desk',
        subject: 'Damage report acknowledged — "Salvaged Frequencies"',
        preview: 'We received your transit-damage report and have opened a claim review.',
        body:
            'Your damage report for "Salvaged Frequencies" (minor corner abrasion noted '
            'on receipt) is logged under claim REF-DMG-2026-0810. A GalleryZone adjuster '
            'will follow up within 2 business days. Do not attempt repairs until '
            'instructed — photos on file are sufficient for now.',
        unread: false,
        receivedAt: '2026-08-08T15:20:00.000Z',
      ),
      MessageThread(
        id: 'agg-msg-4',
        from: 'GalleryZone Coordinator Program',
        subject: 'Welcome — your nominated coordinator is on file',
        preview:
            'Meher Chatterjee is registered as Verandah Art House\'s GalleryZone '
            'coordinator.',
        body:
            'Welcome to the Aggregator Portal. MOU §10 requires one nominated '
            'GalleryZone coordinator per premises — we have Meher Chatterjee on file '
            'for Verandah Art House — Main Gallery. They will receive audit notices, '
            'expiry reminders, and inbound shipment alerts on your behalf.',
        unread: false,
        receivedAt: '2026-07-15T10:00:00.000Z',
      ),
      MessageThread(
        id: 'agg-msg-5',
        from: 'GalleryZone Settlements',
        subject: 'Settlement pending for "Salvaged Frequencies"',
        preview:
            'Sale recorded — aggregator commission will credit after delivery '
            'confirmation.',
        body:
            'You recorded a sale for "Salvaged Frequencies" on 5 Jul 2026. Settlement '
            '(20% of your markup over the listed price) will credit to your wallet once '
            'delivery is confirmed and the 7-day settlement window clears. Track status '
            'under Wallet and Settlements.',
        unread: false,
        receivedAt: '2026-07-05T18:45:00.000Z',
      ),
    ];

List<SupportTicket> seedAggregatorSupportTickets() => const [
      SupportTicket(
        id: 'agg-ticket-1',
        subject: 'Clarification on security deposit refund terms',
        message:
            'Our MOU security deposit is marked active — if we exit the program, is the '
            '₹50,000 deposit refunded after the final audit and return of all assigned '
            'inventory, or is there a waiting period?',
        status: SupportTicketStatus.answered,
        createdAt: '2026-07-22T11:10:00.000Z',
      ),
    ];

/// Illustrative sell-through trend. Six fixture rows cannot produce a
/// believable six-month curve, so this one series is demo data and the
/// analytics screen says so — every other figure there is live.
const aggregatorSellThroughSeries = <({String month, double rate})>[
  (month: 'Mar', rate: 38),
  (month: 'Apr', rate: 44),
  (month: 'May', rate: 41),
  (month: 'Jun', rate: 52),
  (month: 'Jul', rate: 58),
  (month: 'Aug', rate: 61),
];
