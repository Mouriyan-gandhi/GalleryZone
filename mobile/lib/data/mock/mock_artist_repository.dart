import 'dart:convert';

import '../../core/format.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../repositories/artist_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show seedArtworksCollection;
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

/// Minimum a withdrawal request is allowed to be.
const minimumWithdrawal = 1000.0;

class MockArtistRepository implements ArtistRepository {
  T _readSingle<T>(String key, T Function() seed, T Function(Map<String, dynamic>) fromJson,
          Map<String, dynamic> Function(T) toJson) =>
      MockDb.getCollection(key, () => [seed()], fromJson, toJson).first;

  void _writeSingle<T>(String key, T value, Map<String, dynamic> Function(T) toJson) =>
      MockDb.setCollection(key, [value], toJson);

  List<Artwork> _readListed() => MockDb.getCollection(
        _artworksKey,
        seedArtworksCollection,
        Artwork.fromJson,
        (a) => a.toJson(),
      );

  List<Artwork> _readPending() => MockDb.getCollection(
        _pendingArtworksKey,
        seedPendingArtworks,
        Artwork.fromJson,
        (a) => a.toJson(),
      );

  /// Everything this artist has, listed or not — the portal is the one place
  /// drafts and in-review submissions are visible.
  List<Artwork> _artistArtworks() => [
        ..._readListed().where((a) => a.artistId == currentArtistId),
        ..._readPending().where((a) => a.artistId == currentArtistId),
      ];

  /// The price map is a `Map<String, double>`, not a list of records, so it
  /// rides through `MockDb`'s collection API as a single JSON blob.
  Map<String, double> _readPrices() {
    final stored = MockDb.getCollection<Map<String, double>>(
      _pricesKey,
      () => [seedArtistPrices()],
      (json) => (jsonDecode(json['value'] as String) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      (prices) => {'value': jsonEncode(prices)},
    );
    return stored.first;
  }

  void _writePrices(Map<String, double> prices) => MockDb.setCollection<Map<String, double>>(
        _pricesKey,
        [prices],
        (value) => {'value': jsonEncode(value)},
      );

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
        insured: input.insuranceOpted,
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
      );

      _writePrices({..._readPrices(), id: input.artistPrice});
      // Straight into the pending queue either way — a submission is never
      // published without review, which is the whole point of the split.
      MockDb.setCollection(_pendingArtworksKey, [artwork, ..._readPending()], (a) => a.toJson());
      _appendActivity(
        ActivityKind.artworkSubmitted,
        input.asDraft ? '"${artwork.title}" saved as draft' : '"${artwork.title}" submitted',
        input.asDraft ? 'Not yet sent for review' : 'Awaiting admin review',
      );
      return artwork;
    });
  }

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
                // ~2% platform pass-through in this mock. The real formula is
                // an open product decision (see the plan's open decisions),
                // so this stays a clearly-marked placeholder.
                artistPayout: ((prices[order.artworkId] ?? 0) * 0.98).round().toDouble(),
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
