import 'dart:convert';

import '../../core/format.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../repositories/artist_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart'
    show enqueueForReview, promoteApprovedSubmissions, seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/aggregator_seed.dart' show seedHoldingsCollection;
import 'seed/artist_seed.dart';

const _artworksKey = 'artworks';
const _pendingArtworksKey = 'pendingArtworks';
const _pricesKey = 'artistPrices';
const _walletKey = 'artistWallet';
const _walletTransactionsKey = 'artistWalletTransactions';
const _activityKey = 'artistActivity';
const _profileKey = 'artistProfile';
const _settingsKey = 'artistSettings';
const _messagesKey = 'artistMessages';
const _settlementsKey = 'artistSettlements';
const _holdingsKey = 'holdings';
const _supportKey = 'artistSupportTickets';
const _ordersKey = 'orders';
const _penaltiesKey = 'artistPenalties';
const _mouKey = 'artistMou';
const _physicalCoaKey = 'physicalCoaRequests';

/// Minimum a withdrawal request is allowed to be.
const minimumWithdrawal = 1000.0;

/// The price map is a `Map<String, double>`, not a list of records, so it
/// rides through `MockDb`'s collection API as a single JSON blob.
Map<String, double> readArtistPrices() {
  final stored = MockDb.getCollection<Map<String, double>>(
    _pricesKey,
    () => [seedArtistPrices()],
    (json) => (jsonDecode(json['value'] as String) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as num).toDouble())),
    (prices) => {'value': jsonEncode(prices)},
  );
  return stored.first;
}

void writeArtistPrices(Map<String, double> prices) =>
    MockDb.setCollection<Map<String, double>>(
      _pricesKey,
      [prices],
      (value) => {'value': jsonEncode(value)},
    );

/// What the artist actually receives on a sale.
///
/// **Provisional.** The real split is one of the project's open decisions —
/// the mocked code, the business requirement and the SAD's schema disagree.
/// This is the figure the artist portal has always shown (their own price
/// less a ~2% platform pass-through), kept in one function so settling the
/// argument is a one-line change rather than a hunt.
double artistPayoutFor(double artistPrice) => (artistPrice * 0.98).roundToDouble();

/// Credits the artist's *pending* balance when their piece sells.
///
/// Pending, not withdrawable: the money becomes available only once the
/// piece is delivered ([settleArtistForOrder]). Same shape as the aggregator
/// portal's commission accrual, deliberately — one mechanic, two portals.
/// A no-op for any artwork that isn't the demo artist's, since no other
/// artist has a wallet in this build.
void creditArtistForSale({required Artwork artwork, required String orderId}) {
  if (artwork.artistId != currentArtistId) return;
  final payout = artistPayoutFor(readArtistPrices()[artwork.id] ?? 0);
  if (payout <= 0) return;

  final now = DateTime.now();
  final wallet = _readArtistWallet();
  MockDb.setCollection(
    _walletKey,
    [wallet.copyWith(pendingBalance: wallet.pendingBalance + payout)],
    (w) => w.toJson(),
  );
  MockDb.setCollection(
    _walletTransactionsKey,
    [
      WalletTransaction(
        id: 'wt-${now.microsecondsSinceEpoch}',
        type: WalletTransactionType.settlement,
        label: 'Sale: "${artwork.title}"',
        amount: payout,
        date: now.toIso8601String().substring(0, 10),
        status: WalletTransactionStatus.pending,
      ),
      ..._readArtistTransactions(),
    ],
    (t) => t.toJson(),
  );
  _appendArtistActivity(
    ActivityKind.settlement,
    '"${artwork.title}" sold',
    '${formatInr(payout)} pending until delivery',
  );
}

/// Moves that pending credit into the withdrawable balance and writes the
/// settlement row. Called when the order reaches `delivered`.
void settleArtistForOrder({
  required Artwork artwork,
  required String orderId,
  required double orderAmount,
}) {
  if (artwork.artistId != currentArtistId) return;
  final payout = artistPayoutFor(readArtistPrices()[artwork.id] ?? 0);
  if (payout <= 0) return;

  final settlements = MockDb.getCollection(
    _settlementsKey,
    seedArtistSettlements,
    Settlement.fromJson,
    (s) => s.toJson(),
  );
  if (settlements.any((s) => s.orderId == orderId)) return;

  final wallet = _readArtistWallet();
  if (wallet.pendingBalance < payout) return;

  final now = DateTime.now();
  MockDb.setCollection(
    _walletKey,
    [
      wallet.copyWith(
        pendingBalance: wallet.pendingBalance - payout,
        balance: wallet.balance + payout,
      ),
    ],
    (w) => w.toJson(),
  );

  // The pending sale row becomes the settlement row rather than a second
  // entry appearing beside it — one sale, one line in the ledger.
  final transactions = _readArtistTransactions();
  final pendingIndex = transactions.indexWhere(
    (t) =>
        t.status == WalletTransactionStatus.pending &&
        t.amount == payout &&
        t.label.contains(artwork.title),
  );
  MockDb.setCollection(
    _walletTransactionsKey,
    [
      for (var i = 0; i < transactions.length; i++)
        if (i == pendingIndex)
          transactions[i].copyWith(
            status: WalletTransactionStatus.completed,
            label: 'Settlement: "${artwork.title}"',
          )
        else
          transactions[i],
    ],
    (t) => t.toJson(),
  );

  MockDb.setCollection(
    _settlementsKey,
    [
      Settlement(
        id: 'stl-${now.microsecondsSinceEpoch}',
        orderId: orderId,
        artworkTitle: artwork.title,
        artistName: artwork.artistName,
        artistAmount: payout,
        aggregatorCommission: 0,
        platformRevenue: orderAmount - payout,
        status: SettlementStatus.processed,
        createdAt: now.toIso8601String(),
        processedAt: now.toIso8601String(),
      ),
      ...settlements,
    ],
    (s) => s.toJson(),
  );
  _appendArtistActivity(
    ActivityKind.settlement,
    'Settlement processed',
    '${formatInr(payout)} is now withdrawable',
  );
}

WalletSummary _readArtistWallet() => MockDb.getCollection(
      _walletKey,
      () => [seedArtistWallet()],
      WalletSummary.fromJson,
      (w) => w.toJson(),
    ).first;

List<WalletTransaction> _readArtistTransactions() => MockDb.getCollection(
      _walletTransactionsKey,
      seedArtistWalletTransactions,
      WalletTransaction.fromJson,
      (t) => t.toJson(),
    );

void _appendArtistActivity(ActivityKind kind, String title, String detail) {
  final activity = MockDb.getCollection(
    _activityKey,
    seedArtistActivity,
    ActivityEntry.fromJson,
    (e) => e.toJson(),
  );
  MockDb.setCollection(
    _activityKey,
    [
      ActivityEntry(
        id: 'act-${DateTime.now().microsecondsSinceEpoch}',
        kind: kind,
        title: title,
        detail: detail,
        time: 'Just now',
      ),
      ...activity,
    ],
    (e) => e.toJson(),
  );
}

class MockArtistRepository implements ArtistRepository {
  T _readSingle<T>(String key, T Function() seed, T Function(Map<String, dynamic>) fromJson,
          Map<String, dynamic> Function(T) toJson) =>
      MockDb.getCollection(key, () => [seed()], fromJson, toJson).first;

  void _writeSingle<T>(String key, T value, Map<String, dynamic> Function(T) toJson) =>
      MockDb.setCollection(key, [value], toJson);

  List<Artwork> _readListed() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
  }

  List<Artwork> _readPending() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(
      _pendingArtworksKey,
      seedPendingArtworks,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
  }

  /// Everything this artist has, listed or not — the portal is the one place
  /// drafts and in-review submissions are visible.
  List<Artwork> _artistArtworks() => [
        ..._readListed().where((a) => a.artistId == currentArtistId),
        ..._readPending().where((a) => a.artistId == currentArtistId),
      ];

  Map<String, double> _readPrices() => readArtistPrices();

  void _writePrices(Map<String, double> prices) => writeArtistPrices(prices);

  List<ActivityEntry> _readActivity() => MockDb.getCollection(
        _activityKey,
        seedArtistActivity,
        ActivityEntry.fromJson,
        (e) => e.toJson(),
      );

  void _appendActivity(ActivityKind kind, String title, String detail) {
    final entry = ActivityEntry(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      title: title,
      detail: detail,
      time: 'Just now',
    );
    MockDb.setCollection(_activityKey, [entry, ..._readActivity()], (e) => e.toJson());
  }

  List<WalletTransaction> _readTransactions() => MockDb.getCollection(
        _walletTransactionsKey,
        seedArtistWalletTransactions,
        WalletTransaction.fromJson,
        (t) => t.toJson(),
      );

  List<MessageThread> _readMessages() => MockDb.getCollection(
        _messagesKey,
        seedArtistMessages,
        MessageThread.fromJson,
        (m) => m.toJson(),
      );

  List<SupportTicket> _readTickets() => MockDb.getCollection(
        _supportKey,
        seedArtistSupportTickets,
        SupportTicket.fromJson,
        (t) => t.toJson(),
      );

  WalletSummary _readWallet() => _readSingle(
        _walletKey,
        seedArtistWallet,
        WalletSummary.fromJson,
        (w) => w.toJson(),
      );

  List<ExternalSalePenalty> _readPenalties() => MockDb.getCollection(
        _penaltiesKey,
        () => const <ExternalSalePenalty>[],
        ExternalSalePenalty.fromJson,
        (p) => p.toJson(),
      );

  /// Any fee the artist owes for selling a piece elsewhere is collected the
  /// next time they actually list something — drafts don't trigger it.
  /// Charged as a wallet adjustment; the balance floors at 0 because there is
  /// no negative-balance/recovery flow in the mock.
  void _settlePendingPenalties(String listingTitle) {
    final penalties = _readPenalties();
    final outstanding = penalties.where((p) => p.settledAt == null).toList();
    if (outstanding.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final total = outstanding.fold<double>(0, (sum, p) => sum + p.amount);
    final settledIds = outstanding.map((p) => p.id).toSet();

    MockDb.setCollection(
      _penaltiesKey,
      [
        for (final penalty in penalties)
          settledIds.contains(penalty.id) ? penalty.copyWith(settledAt: now) : penalty,
      ],
      (p) => p.toJson(),
    );

    final wallet = _readWallet();
    _writeSingle(
      _walletKey,
      wallet.copyWith(balance: (wallet.balance - total).clamp(0, double.infinity)),
      (w) => w.toJson(),
    );

    final plural = outstanding.length > 1 ? 'artworks' : 'artwork';
    MockDb.setCollection(
      _walletTransactionsKey,
      [
        WalletTransaction(
          id: 'wt-${DateTime.now().microsecondsSinceEpoch}',
          type: WalletTransactionType.adjustment,
          label: 'Off-platform sale fee (${outstanding.length} $plural), '
              'charged on "$listingTitle"',
          amount: -total,
          date: now.substring(0, 10),
          status: WalletTransactionStatus.completed,
        ),
        ..._readTransactions(),
      ],
      (t) => t.toJson(),
    );
  }

  /// Writes an updated artwork back into whichever collection holds it. A
  /// piece is in exactly one of `artworks` (live) and `pendingArtworks`
  /// (drafts and in-review), and the caller has already resolved which.
  void _replaceArtwork(Artwork updated, {required bool inLive}) {
    final key = inLive ? _artworksKey : _pendingArtworksKey;
    final list = inLive ? _readListed() : _readPending();
    MockDb.setCollection(
      key,
      [for (final a in list) a.id == updated.id ? updated : a],
      (a) => a.toJson(),
    );
  }

  @override
  Future<List<ArtistKpi>> getKpis() => mockDelay(() {
        final wallet = _readWallet();
        final pending =
            _artistArtworks().where((a) => a.status == ArtworkStatus.pendingApproval).length;
        return [
          // Total revenue is the one figure with no source in the mock data
          // (there is no historical ledger), so it stays the fixture value —
          // marked here rather than dressed up as computed.
          const ArtistKpi(
            label: 'Total revenue',
            value: '₹1,84,320',
            delta: '+12.4% vs. last month',
            positive: true,
          ),
          ArtistKpi(
            label: 'Wallet balance',
            value: formatInr(wallet.balance),
            delta: wallet.pendingBalance > 0
                ? '${formatInr(wallet.pendingBalance)} pending settlement'
                : 'No pending settlements',
            positive: true,
          ),
          ArtistKpi(
            label: 'Pending approval',
            value: '$pending',
            delta: pending > 0 ? 'Awaiting admin review' : 'All caught up',
            positive: pending == 0,
          ),
        ];
      });

  @override
  Future<List<ActivityEntry>> listActivity() => mockDelay(_readActivity);

  @override
  Future<List<ArtistArtwork>> listArtworks() => mockDelay(() {
        final prices = _readPrices();
        return [
          for (final artwork in _artistArtworks())
            ArtistArtwork(artwork: artwork, artistPrice: prices[artwork.id] ?? 0),
        ];
      });

  @override
  Future<Artwork> submitArtwork(SubmitArtworkInput input) {
    if (input.title.trim().isEmpty) return mockError('A title is required');
    if (input.artistPrice <= 0) return mockError('Enter your price for this artwork');

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final status = input.asDraft ? ArtworkStatus.draft : ArtworkStatus.pendingApproval;
      final id = 'aw-${DateTime.now().microsecondsSinceEpoch}';

      final artwork = Artwork(
        id: id,
        title: input.title.trim(),
        artistId: currentArtistId,
        artistName: currentArtistName,
        verifiedArtist: true,
        category: input.category,
        medium: input.medium,
        customerPrice: (input.artistPrice * customerMarkupMultiplier).round().toDouble(),
        thumbnailUrl: input.images.isEmpty ? '' : input.images.first.url,
        // Aggregator display puts the physical piece in someone else's
        // custody, so insurance stops being a choice the moment that channel
        // is picked. Enforced here rather than only in the form, so the rule
        // holds whatever calls this.
        insured: input.insuranceOpted || isAggregatorListed(input.listingType),
        status: status,
        listingType: input.listingType,
        description: input.description,
        dimensions: input.dimensions,
        yearCreated: input.yearCreated,
        images: input.images,
        coaCertificateNumber: 'GZ-COA-${DateTime.now().year}-${id.toUpperCase()}',
        coaIssueDate: now,
        socialProofLinks: const [],
        statusHistory: [ArtworkStatusEvent(status: status, changedAt: now)],
        nfcTagId: input.nfcTagId,
        physical: input.physical,
      );

      _writePrices({..._readPrices(), id: input.artistPrice});
      // Straight into the pending queue either way — a submission is never
      // published without review, which is the whole point of the split.
      MockDb.setCollection(_pendingArtworksKey, [artwork, ..._readPending()], (a) => a.toJson());
      if (!input.asDraft) {
        _settlePendingPenalties(artwork.title);
        enqueueForReview(id);
      }
      _appendActivity(
        ActivityKind.artworkSubmitted,
        input.asDraft ? '"${artwork.title}" saved as draft' : '"${artwork.title}" submitted',
        input.asDraft ? 'Not yet sent for review' : 'Awaiting admin review',
      );
      return artwork;
    });
  }

  @override
  Future<Artwork> updateArtwork({
    required String artworkId,
    required SubmitArtworkInput patch,
  }) {
    final inLive = _readListed().where((a) => a.id == artworkId).firstOrNull;
    final existing = inLive ?? _readPending().where((a) => a.id == artworkId).firstOrNull;
    if (existing == null || existing.artistId != currentArtistId) {
      return mockError('Artwork not found');
    }

    final editState = artworkEditState(existing);
    if (!editState.editable) {
      return mockError(
        editState.reason == ArtworkEditReason.purchased
            ? 'This artwork has been claimed or sold — it can no longer be edited'
            : 'The $artworkEditWindowDays-day edit window for this artwork has closed',
      );
    }
    if (patch.title.trim().isEmpty) return mockError('A title is required');
    if (patch.artistPrice <= 0) return mockError('Enter your price for this artwork');

    return mockDelay(() {
      final updated = existing.copyWith(
        title: patch.title.trim(),
        description: patch.description,
        category: patch.category,
        medium: patch.medium,
        dimensions: patch.dimensions,
        yearCreated: patch.yearCreated,
        customerPrice: (patch.artistPrice * customerMarkupMultiplier).round().toDouble(),
        listingType: patch.listingType,
        insured: patch.insuranceOpted || isAggregatorListed(patch.listingType),
        nfcTagId: patch.nfcTagId,
        physical: patch.physical ?? existing.physical,
        images: patch.images.isEmpty ? existing.images : patch.images,
        thumbnailUrl: patch.images.isEmpty ? existing.thumbnailUrl : patch.images.first.url,
      );

      _replaceArtwork(updated, inLive: inLive != null);
      _writePrices({..._readPrices(), updated.id: patch.artistPrice});
      _appendActivity(
        ActivityKind.artworkSubmitted,
        '"${updated.title}" updated',
        editState.reason == ArtworkEditReason.draft
            ? 'Draft changes saved'
            : '${editState.daysLeft} ${editState.daysLeft == 1 ? "day" : "days"} '
                'left in the edit window',
      );
      return updated;
    });
  }

  @override
  Future<Artwork> markSoldElsewhere(String artworkId) {
    final inLive = _readListed().where((a) => a.id == artworkId).firstOrNull;
    final existing = inLive ?? _readPending().where((a) => a.id == artworkId).firstOrNull;
    if (existing == null || existing.artistId != currentArtistId) {
      return mockError('Artwork not found');
    }
    if (existing.status == ArtworkStatus.soldExternally) {
      return mockError('This artwork is already marked as sold elsewhere');
    }
    if (!withdrawableStatuses.contains(existing.status)) {
      return mockError(
        'This artwork is already claimed on GalleryZone and can no longer be withdrawn',
      );
    }

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final updated = existing.copyWith(
        status: ArtworkStatus.soldExternally,
        statusHistory: [
          ...existing.statusHistory,
          ArtworkStatusEvent(status: ArtworkStatus.soldExternally, changedAt: now),
        ],
        custody: const ArtworkCustody(
          legalOwner: CustodyParty.customer,
          custodian: CustodyParty.customer,
          locationLabel: 'Sold outside GalleryZone',
        ),
      );
      _replaceArtwork(updated, inLive: inLive != null);

      final penalty = ExternalSalePenalty(
        id: 'pen-${DateTime.now().microsecondsSinceEpoch}',
        artworkId: artworkId,
        artworkTitle: existing.title,
        amount: (existing.customerPrice * externalSalePenaltyRate).roundToDouble(),
        createdAt: now,
      );
      MockDb.setCollection(_penaltiesKey, [penalty, ..._readPenalties()], (p) => p.toJson());

      _appendActivity(
        ActivityKind.artworkSubmitted,
        '"${existing.title}" marked sold elsewhere',
        'Removed from GalleryZone. ${formatInr(penalty.amount)} will be charged '
            'on your next listing.',
      );
      return updated;
    });
  }

  @override
  Future<Artwork> submitForReview(String artworkId) {
    final existing = _readPending().where((a) => a.id == artworkId).firstOrNull;
    if (existing == null || existing.artistId != currentArtistId) {
      return mockError('Artwork not found');
    }
    if (existing.status != ArtworkStatus.draft) {
      return mockError('This artwork has already been sent for review');
    }

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final updated = existing.copyWith(
        status: ArtworkStatus.pendingApproval,
        statusHistory: [
          ...existing.statusHistory,
          ArtworkStatusEvent(status: ArtworkStatus.pendingApproval, changedAt: now),
        ],
      );
      _replaceArtwork(updated, inLive: false);
      _settlePendingPenalties(updated.title);
      enqueueForReview(artworkId);
      _appendActivity(
        ActivityKind.artworkSubmitted,
        '"${updated.title}" submitted',
        'Awaiting review',
      );
      return updated;
    });
  }

  @override
  Future<List<ExternalSalePenalty>> listPenalties() => mockDelay(_readPenalties);

  @override
  Future<WalletSummary> getWallet() => mockDelay(_readWallet);

  @override
  Future<List<WalletTransaction>> listWalletTransactions() => mockDelay(_readTransactions);

  @override
  Future<WalletTransaction> requestWithdrawal(double amount) {
    final wallet = _readWallet();
    if (amount < minimumWithdrawal) return mockError('Minimum withdrawal is ₹1,000');
    if (amount > wallet.balance) return mockError('Exceeds your available balance');

    return mockDelay(() {
      _writeSingle(
        _walletKey,
        wallet.copyWith(balance: wallet.balance - amount),
        (w) => w.toJson(),
      );
      final masked = _readSingle(
        _profileKey,
        seedArtistProfile,
        ArtistProfileDetails.fromJson,
        (p) => p.toJson(),
      ).bankAccountMasked;
      final transaction = WalletTransaction(
        id: 'wt-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletTransactionType.withdrawal,
        label: 'Withdrawal to bank ${masked.substring(masked.length - 4)}',
        amount: -amount,
        date: DateTime.now().toIso8601String().substring(0, 10),
        status: WalletTransactionStatus.completed,
      );
      MockDb.setCollection(
        _walletTransactionsKey,
        [transaction, ..._readTransactions()],
        (t) => t.toJson(),
      );
      _appendActivity(
        ActivityKind.withdrawal,
        'Withdrawal requested',
        '${formatInr(amount)} sent to your bank account',
      );
      return transaction;
    });
  }

  @override
  Future<ArtistProfileDetails> getProfile() => mockDelay(
        () => _readSingle(
          _profileKey,
          seedArtistProfile,
          ArtistProfileDetails.fromJson,
          (p) => p.toJson(),
        ),
      );

  @override
  Future<ArtistProfileDetails> updateProfile(ArtistProfileDetails profile) => mockDelay(() {
        _writeSingle(_profileKey, profile, (p) => p.toJson());
        return profile;
      });

  @override
  Future<ArtistProfileDetails> updateBankDetails({
    required String accountNumber,
    required String ifsc,
  }) {
    if (accountNumber.trim().isEmpty) return mockError('Enter an account number');
    return mockDelay(() {
      final current = _readSingle(
        _profileKey,
        seedArtistProfile,
        ArtistProfileDetails.fromJson,
        (p) => p.toJson(),
      );
      // Only the last four digits are ever stored — the full account number
      // is never persisted anywhere on the device.
      final trimmed = accountNumber.trim();
      final last4 = trimmed.substring(trimmed.length < 4 ? 0 : trimmed.length - 4);
      final updated = current.copyWith(
        bankAccountMasked: '•••• •••• •••• $last4',
        ifsc: ifsc.trim(),
      );
      _writeSingle(_profileKey, updated, (p) => p.toJson());
      return updated;
    });
  }

  @override
  Future<List<ArtistOrder>> listOrders() => mockDelay(() {
        final ids = _artistArtworks().map((a) => a.id).toSet();
        final prices = _readPrices();
        final orders = MockDb.getCollection(
          _ordersKey,
          () => const <Order>[],
          Order.fromJson,
          (o) => o.toJson(),
        );
        return [
          for (final order in orders)
            if (ids.contains(order.artworkId))
              ArtistOrder(
                order: order,
                artistPayout: artistPayoutFor(prices[order.artworkId] ?? 0),
              ),
        ];
      });

  @override
  Future<List<Settlement>> listSettlements() => mockDelay(
        () => MockDb.getCollection(
          _settlementsKey,
          seedArtistSettlements,
          Settlement.fromJson,
          (s) => s.toJson(),
        ),
      );

  @override
  Future<List<GallerySpacePlacement>> listGallerySpaces() => mockDelay(() {
        final byId = {for (final artwork in _artistArtworks()) artwork.id: artwork};
        // Seeded through the shared function, not this artist's own
        // holding alone: `holdings` is one collection shared with the
        // aggregator portal, and whichever repository reads it first
        // persists whatever it seeded.
        final holdings = MockDb.getCollection(
          _holdingsKey,
          seedHoldingsCollection,
          AggregatorHolding.fromJson,
          (h) => h.toJson(),
        );
        return [
          for (final holding in holdings)
            if (byId[holding.artworkId] != null)
              GallerySpacePlacement(holding: holding, artwork: byId[holding.artworkId]!),
        ];
      });

  @override
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests() => mockDelay(
        () => MockDb.getCollection(
          _physicalCoaKey,
          () => const <PhysicalCoaRequest>[],
          PhysicalCoaRequest.fromJson,
          (r) => r.toJson(),
        ),
      );

  @override
  Future<PhysicalCoaRequest> dispatchPhysicalCoa(String requestId, String courierRef) {
    if (courierRef.trim().isEmpty) return mockError('Enter a courier reference');
    final requests = MockDb.getCollection(
      _physicalCoaKey,
      () => const <PhysicalCoaRequest>[],
      PhysicalCoaRequest.fromJson,
      (r) => r.toJson(),
    );
    final existing = requests.where((r) => r.id == requestId).firstOrNull;
    if (existing == null) return mockError('Request not found');
    if (existing.status == PhysicalCoaStatus.dispatched) {
      return mockError('This certificate has already been dispatched');
    }

    return mockDelay(() {
      final updated = existing.copyWith(
        status: PhysicalCoaStatus.dispatched,
        dispatchedAt: DateTime.now().toIso8601String(),
        courierRef: courierRef.trim(),
      );
      MockDb.setCollection(
        _physicalCoaKey,
        [for (final r in requests) r.id == requestId ? updated : r],
        (r) => r.toJson(),
      );
      _appendActivity(
        ActivityKind.artworkSubmitted,
        'Certificate dispatched',
        '"${updated.artworkTitle}" · ${updated.courierRef}',
      );
      return updated;
    });
  }

  @override
  Future<MouAcceptance?> getMouAcceptance() => mockDelay(
        () => MockDb.getCollection(
          _mouKey,
          () => const <MouAcceptance>[],
          MouAcceptance.fromJson,
          (a) => a.toJson(),
        ).firstOrNull,
      );

  @override
  Future<MouAcceptance> acceptMou(String version) => mockDelay(() {
        final acceptance = MouAcceptance(
          version: version,
          acceptedAt: DateTime.now().toIso8601String(),
        );
        // One row, replaced: only the current acceptance matters, and keeping
        // a history of them would imply a legal record this build does not
        // actually keep.
        MockDb.setCollection(_mouKey, [acceptance], (a) => a.toJson());
        _appendActivity(
          ActivityKind.verification,
          'MOU accepted',
          'Version $version',
        );
        return acceptance;
      });

  @override
  Future<ArtistSettings> getSettings() => mockDelay(
        () => _readSingle(
          _settingsKey,
          seedArtistSettings,
          ArtistSettings.fromJson,
          (s) => s.toJson(),
        ),
      );

  @override
  Future<ArtistSettings> updateSettings(ArtistSettings settings) => mockDelay(() {
        _writeSingle(_settingsKey, settings, (s) => s.toJson());
        return settings;
      });

  @override
  Future<List<MessageThread>> listMessages() => mockDelay(_readMessages);

  @override
  Future<MessageThread> markMessageRead(String id) {
    final messages = _readMessages();
    final existing = messages.where((m) => m.id == id).firstOrNull;
    if (existing == null) return mockError('Message "$id" not found');
    return mockDelay(() {
      final updated = existing.copyWith(unread: false);
      MockDb.setCollection(
        _messagesKey,
        messages.map((m) => m.id == id ? updated : m).toList(),
        (m) => m.toJson(),
      );
      return updated;
    });
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() => mockDelay(_readTickets);

  @override
  Future<SupportTicket> submitSupportTicket({
    required String subject,
    required String message,
  }) {
    if (subject.trim().isEmpty) return mockError('A subject is required');
    if (message.trim().isEmpty) return mockError('Enter a message');
    return mockDelay(() {
      final ticket = SupportTicket(
        id: 'ticket-${DateTime.now().microsecondsSinceEpoch}',
        subject: subject.trim(),
        message: message.trim(),
        status: SupportTicketStatus.open,
        createdAt: DateTime.now().toIso8601String(),
      );
      MockDb.setCollection(_supportKey, [ticket, ..._readTickets()], (t) => t.toJson());
      return ticket;
    });
  }
}
