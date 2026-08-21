import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../repositories/aggregator_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/aggregator_seed.dart';

const _artworksKey = 'artworks';
const _holdingsKey = 'holdings';
const _salesKey = 'aggregatorSales';
const _gallerySpacesKey = 'aggregatorGallerySpaces';
const _walletKey = 'aggregatorWallet';
const _walletTransactionsKey = 'aggregatorWalletTransactions';
const _settlementsKey = 'aggregatorSettlements';
const _messagesKey = 'aggregatorMessages';
const _supportKey = 'aggregatorSupportTickets';
const _settingsKey = 'aggregatorSettings';
const _profileKey = 'aggregatorProfile';

/// Port of `aggregatorService.ts` + `aggregatorSalesService.ts`.
///
/// Reserving and recording a sale deliberately do **not** mutate the shared
/// `artworks` collection. That collection belongs to the marketplace and the
/// artist portal too, and writing an aggregator-only state into it would
/// leak side effects into screens this portal doesn't own. The consequence
/// is that an artwork's own `status` stays `marketplace` after this portal
/// reserves it — so every eligibility check here reads `holdings`, never
/// `artwork.status`.
class MockAggregatorRepository implements AggregatorRepository {
  T _readSingle<T>(
    String key,
    T Function() seed,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) =>
      MockDb.getCollection(key, () => [seed()], fromJson, toJson).first;

  void _writeSingle<T>(String key, T value, Map<String, dynamic> Function(T) toJson) =>
      MockDb.setCollection(key, [value], toJson);

  List<Artwork> _readArtworks() => MockDb.getCollection(
        _artworksKey,
        seedArtworksCollection,
        Artwork.fromJson,
        (a) => a.toJson(),
      );

  Artwork? _artworkById(String id) {
    for (final artwork in _readArtworks()) {
      if (artwork.id == id) return artwork;
    }
    return null;
  }

  List<AggregatorHolding> _readHoldings() => MockDb.getCollection(
        _holdingsKey,
        seedHoldingsCollection,
        AggregatorHolding.fromJson,
        (h) => h.toJson(),
      );

  void _writeHoldings(List<AggregatorHolding> holdings) =>
      MockDb.setCollection(_holdingsKey, holdings, (h) => h.toJson());

  List<AggregatorSale> _readSales() => MockDb.getCollection(
        _salesKey,
        () => const <AggregatorSale>[],
        AggregatorSale.fromJson,
        (s) => s.toJson(),
      );

  void _writeSales(List<AggregatorSale> sales) =>
      MockDb.setCollection(_salesKey, sales, (s) => s.toJson());

  WalletSummary _readWallet() => _readSingle(
        _walletKey,
        seedAggregatorWallet,
        WalletSummary.fromJson,
        (w) => w.toJson(),
      );

  List<WalletTransaction> _readTransactions() => MockDb.getCollection(
        _walletTransactionsKey,
        () => const <WalletTransaction>[],
        WalletTransaction.fromJson,
        (t) => t.toJson(),
      );

  void _writeTransactions(List<WalletTransaction> transactions) =>
      MockDb.setCollection(_walletTransactionsKey, transactions, (t) => t.toJson());

  List<Settlement> _readSettlements() => MockDb.getCollection(
        _settlementsKey,
        () => const <Settlement>[],
        Settlement.fromJson,
        (s) => s.toJson(),
      );

  List<MessageThread> _readMessages() => MockDb.getCollection(
        _messagesKey,
        seedAggregatorMessages,
        MessageThread.fromJson,
        (m) => m.toJson(),
      );

  List<SupportTicket> _readTickets() => MockDb.getCollection(
        _supportKey,
        seedAggregatorSupportTickets,
        SupportTicket.fromJson,
        (t) => t.toJson(),
      );

  AggregatorProfile _readProfile() => _readSingle(
        _profileKey,
        seedAggregatorProfile,
        AggregatorProfile.fromJson,
        (p) => p.toJson(),
      );

  /// The commission a sale carries, from its holding's markup over the
  /// artwork's floor. Returns 0 if either record has gone missing.
  double _commissionForSale(AggregatorSale sale) {
    final holding = _readHoldings().where((h) => h.id == sale.holdingId).firstOrNull;
    final artwork = _artworkById(sale.artworkId);
    if (holding == null || artwork == null) return 0;
    return aggregatorCommissionFor(
      displayPrice: holding.displayPrice,
      customerPrice: artwork.customerPrice,
    );
  }

  @override
  Future<AggregatorDashboardSummary> getDashboardSummary() => mockDelay(() {
        final holdings = _readHoldings();
        final sold = holdings
            .where((h) => h.status == HoldingStatus.soldPendingSettlement)
            .toList();
        var commission = 0.0;
        for (final holding in sold) {
          final artwork = _artworkById(holding.artworkId);
          if (artwork == null) continue;
          commission += aggregatorCommissionFor(
            displayPrice: holding.displayPrice,
            customerPrice: artwork.customerPrice,
          );
        }
        return AggregatorDashboardSummary(
          activeReservations:
              holdings.where((h) => h.status == HoldingStatus.reserved).length,
          commissionEarned: commission,
          pendingSettlements: sold.length,
        );
      });

  @override
  Future<List<Artwork>> listReservableInventory() => mockDelay(() {
        final claimed = _readHoldings().map((h) => h.artworkId).toSet();
        return _readArtworks()
            .where((a) =>
                a.listingType == ListingType.marketplaceAndAggregator &&
                a.status == ArtworkStatus.marketplace &&
                !claimed.contains(a.id))
            .toList();
      });

  @override
  Future<AggregatorHolding> reserve(String artworkId, {bool simulateConflict = false}) {
    if (simulateConflict) return mockError('Artwork no longer available');

    final artwork = _artworkById(artworkId);
    final holdings = _readHoldings();
    if (artwork == null || holdings.any((h) => h.artworkId == artworkId)) {
      return mockError('Artwork no longer available');
    }

    return mockDelay(() {
      final assignedAt = DateTime.now();
      final percent = advancePercentFor(artwork.customerPrice);
      final holding = AggregatorHolding(
        id: 'hold-${holdings.length + 1}-${assignedAt.microsecondsSinceEpoch}',
        artworkId: artworkId,
        advancePercent: percent,
        advanceAmount: advanceAmountFor(artwork.customerPrice, percent),
        // Opens at the floor; the collection screen can raise it, never lower.
        displayPrice: artwork.customerPrice,
        assignedAt: assignedAt.toIso8601String(),
        expiresAt: assignedAt.add(holdingWindow).toIso8601String(),
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.selfReserved,
      );
      _writeHoldings([...holdings, holding]);
      return holding;
    });
  }

  @override
  Future<List<AggregatorHoldingView>> listCollection() => mockDelay(() {
        final byId = {for (final artwork in _readArtworks()) artwork.id: artwork};
        return [
          for (final holding in _readHoldings())
            if (byId[holding.artworkId] != null)
              AggregatorHoldingView(holding: holding, artwork: byId[holding.artworkId]!),
        ];
      });

  @override
  Future<AggregatorHolding> updateDisplayPrice(String holdingId, double displayPrice) {
    final holdings = _readHoldings();
    final existing = holdings.where((h) => h.id == holdingId).firstOrNull;
    if (existing == null) return mockError('No holding "$holdingId"');

    final artwork = _artworkById(existing.artworkId);
    if (artwork != null && displayPrice < artwork.customerPrice) {
      // Enforced here, not only in the form: the floor is a platform rule
      // (SAD §2.7), and a rule the UI alone upholds isn't a rule.
      return mockError('Display price cannot go below the marketplace price');
    }

    return mockDelay(() {
      final updated = existing.copyWith(displayPrice: displayPrice);
      _writeHoldings([for (final h in holdings) h.id == holdingId ? updated : h]);
      return updated;
    });
  }

  @override
  Future<AggregatorSale> recordSale(RecordSaleInput input) {
    if (input.soldPrice <= 0) return mockError('Enter the sold price');
    if (input.buyerName.trim().isEmpty) return mockError("Enter the buyer's name");

    final holdings = _readHoldings();
    final holding = holdings
        .where((h) => h.artworkId == input.artworkId && h.status == HoldingStatus.reserved)
        .firstOrNull;
    if (holding == null) {
      return mockError('No active reservation found for this artwork');
    }

    return mockDelay(() {
      // The holding moves to sold rather than disappearing, so the piece
      // stays visible (and price-locked) in the collection.
      final updated = holding.copyWith(status: HoldingStatus.soldPendingSettlement);
      _writeHoldings([for (final h in holdings) h.id == holding.id ? updated : h]);

      final now = DateTime.now();
      final stamp = now.microsecondsSinceEpoch;
      final sale = AggregatorSale(
        id: 'sale-$stamp',
        holdingId: holding.id,
        artworkId: input.artworkId,
        soldPrice: input.soldPrice,
        buyerName: input.buyerName.trim(),
        buyerEmail: input.buyerEmail.trim(),
        buyerPhone: input.buyerPhone.trim(),
        deliveryAddress: input.deliveryAddress,
        deliveryMode: input.deliveryMode,
        soldAt: now.toIso8601String(),
        shipmentStatus: ShipmentStatus.preparing,
        courierRef: input.deliveryMode == DeliveryMode.courier
            ? 'CR-${stamp.toRadixString(36).toUpperCase()}'
            : null,
      );
      _writeSales([sale, ..._readSales()]);

      // Commission accrues as *pending* now and only becomes withdrawable
      // once the settlement is processed — the wallet never shows money the
      // aggregator can't yet take out.
      final artwork = _artworkById(input.artworkId);
      if (artwork != null) {
        final commission = aggregatorCommissionFor(
          displayPrice: holding.displayPrice,
          customerPrice: artwork.customerPrice,
        );
        if (commission > 0) {
          final wallet = _readWallet();
          _writeSingle(
            _walletKey,
            wallet.copyWith(pendingBalance: wallet.pendingBalance + commission),
            (w) => w.toJson(),
          );
          _writeTransactions([
            WalletTransaction(
              id: 'wt-$stamp',
              type: WalletTransactionType.commission,
              label: 'Commission: "${artwork.title}"',
              amount: commission,
              date: now.toIso8601String().substring(0, 10),
              status: WalletTransactionStatus.pending,
            ),
            ..._readTransactions(),
          ]);
        }
      }

      return sale;
    });
  }

  @override
  Future<List<AggregatorSale>> listSales() => mockDelay(_readSales);

  @override
  Future<List<AggregatorCustomer>> listCustomers() => mockDelay(() {
        final byEmail = <String, AggregatorCustomer>{};
        for (final sale in _readSales()) {
          final existing = byEmail[sale.buyerEmail];
          byEmail[sale.buyerEmail] = AggregatorCustomer(
            // Latest sale wins on name/phone — a buyer who corrects their
            // details on a second purchase shouldn't stay stale here.
            buyerName: sale.buyerName,
            buyerEmail: sale.buyerEmail,
            buyerPhone: sale.buyerPhone,
            orderCount: (existing?.orderCount ?? 0) + 1,
            totalSpend: (existing?.totalSpend ?? 0) + sale.soldPrice,
          );
        }
        return byEmail.values.toList();
      });

  @override
  Future<AggregatorSale> advanceShipment(String saleId) {
    final sales = _readSales();
    final sale = sales.where((s) => s.id == saleId).firstOrNull;
    if (sale == null) return mockError('Sale not found');
    if (sale.shipmentStatus == ShipmentStatus.delivered) {
      return mockError('Shipment is already delivered');
    }

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final updated = sale.shipmentStatus == ShipmentStatus.preparing
          ? sale.copyWith(shipmentStatus: ShipmentStatus.dispatched, dispatchedAt: now)
          : sale.copyWith(shipmentStatus: ShipmentStatus.delivered, deliveredAt: now);
      _writeSales([for (final s in sales) s.id == saleId ? updated : s]);
      return updated;
    });
  }

  @override
  Future<List<GallerySpace>> listGallerySpaces() => mockDelay(
        () => MockDb.getCollection(
          _gallerySpacesKey,
          seedGallerySpaces,
          GallerySpace.fromJson,
          (s) => s.toJson(),
        ),
      );

  @override
  Future<WalletSummary> getWallet() => mockDelay(_readWallet);

  @override
  Future<List<WalletTransaction>> listWalletTransactions() => mockDelay(_readTransactions);

  @override
  Future<WalletTransaction> requestWithdrawal(double amount) {
    final wallet = _readWallet();
    if (amount < aggregatorMinimumWithdrawal) {
      return mockError('Minimum withdrawal is ₹1,000');
    }
    if (amount > wallet.balance) return mockError('Exceeds your available balance');

    return mockDelay(() {
      _writeSingle(
        _walletKey,
        wallet.copyWith(balance: wallet.balance - amount),
        (w) => w.toJson(),
      );
      final masked = _readProfile().bankAccountMasked;
      final transaction = WalletTransaction(
        id: 'wt-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletTransactionType.withdrawal,
        label: 'Withdrawal to bank ${masked.substring(masked.length - 4)}',
        amount: -amount,
        date: DateTime.now().toIso8601String().substring(0, 10),
        status: WalletTransactionStatus.completed,
      );
      _writeTransactions([transaction, ..._readTransactions()]);
      return transaction;
    });
  }

  @override
  Future<List<Settlement>> listSettlements() => mockDelay(_readSettlements);

  @override
  Future<Settlement> processSettlement(String saleId) {
    final sale = _readSales().where((s) => s.id == saleId).firstOrNull;
    if (sale == null) return mockError('Sale not found');
    if (_readSettlements().any((s) => s.orderId == saleId)) {
      return mockError('Settlement already processed');
    }

    final commission = _commissionForSale(sale);
    if (commission <= 0) return mockError('No commission to settle for this sale');

    final wallet = _readWallet();
    if (wallet.pendingBalance < commission) {
      return mockError('Insufficient pending balance to settle');
    }

    return mockDelay(() {
      _writeSingle(
        _walletKey,
        wallet.copyWith(
          pendingBalance: wallet.pendingBalance - commission,
          balance: wallet.balance + commission,
        ),
        (w) => w.toJson(),
      );

      final artwork = _artworkById(sale.artworkId);
      // The pending commission row becomes the settlement row rather than a
      // second entry appearing beside it — one sale, one line in the ledger.
      final transactions = _readTransactions();
      final pendingIndex = transactions.indexWhere((t) =>
          t.type == WalletTransactionType.commission &&
          t.status == WalletTransactionStatus.pending &&
          t.amount == commission &&
          (artwork == null || t.label.contains(artwork.title)));
      if (pendingIndex != -1) {
        _writeTransactions([
          for (var i = 0; i < transactions.length; i++)
            if (i == pendingIndex)
              transactions[i].copyWith(
                type: WalletTransactionType.settlement,
                status: WalletTransactionStatus.completed,
                label: artwork == null
                    ? transactions[i].label
                    : 'Settlement: "${artwork.title}"',
              )
            else
              transactions[i],
        ]);
      }

      final settlement = Settlement(
        id: 'settle-${DateTime.now().microsecondsSinceEpoch}',
        orderId: saleId,
        artworkTitle: artwork?.title ?? sale.artworkId,
        artistName: artwork?.artistName ?? '—',
        // Zero, and honestly so: the artist's side of this settlement isn't
        // wired yet (it waits on the same payout decision the commission
        // formula does), and this portal has no visibility into it either
        // way. See the plan's open decisions.
        artistAmount: 0,
        aggregatorCommission: commission,
        platformRevenue: 0,
        status: SettlementStatus.processed,
        createdAt: sale.soldAt,
        processedAt: DateTime.now().toIso8601String(),
      );
      MockDb.setCollection(
        _settlementsKey,
        [settlement, ..._readSettlements()],
        (s) => s.toJson(),
      );
      return settlement;
    });
  }

  @override
  Future<AggregatorAnalyticsSummary> getAnalytics() => mockDelay(() {
        final sales = _readSales();
        final holdings = _readHoldings();
        final wallet = _readWallet();

        var revenue = 0.0;
        var markupTotal = 0.0;
        for (final sale in sales) {
          revenue += sale.soldPrice;
          final holding = holdings.where((h) => h.id == sale.holdingId).firstOrNull;
          final artwork = _artworkById(sale.artworkId);
          if (holding == null || artwork == null) continue;
          final markup = holding.displayPrice - artwork.customerPrice;
          markupTotal += markup > 0 ? markup : 0;
        }

        return AggregatorAnalyticsSummary(
          salesCount: sales.length,
          totalRevenue: revenue,
          commissionPending: wallet.pendingBalance,
          commissionAvailable: wallet.balance,
          customerCount: sales.map((s) => s.buyerEmail).toSet().length,
          activeReservations:
              holdings.where((h) => h.status == HoldingStatus.reserved).length,
          averageSoldPrice: sales.isEmpty ? 0 : (revenue / sales.length).roundToDouble(),
          averageDisplayMarkup:
              sales.isEmpty ? 0 : (markupTotal / sales.length).roundToDouble(),
        );
      });

  @override
  Future<List<CategoryPerformance>> getCategoryPerformance() => mockDelay(() {
        final revenue = <String, double>{};
        final orders = <String, int>{};
        for (final sale in _readSales()) {
          final artwork = _artworkById(sale.artworkId);
          if (artwork == null) continue;
          revenue[artwork.category] = (revenue[artwork.category] ?? 0) + sale.soldPrice;
          orders[artwork.category] = (orders[artwork.category] ?? 0) + 1;
        }
        return [
          for (final entry in revenue.entries)
            CategoryPerformance(
              category: entry.key,
              revenue: entry.value,
              orders: orders[entry.key] ?? 0,
            ),
        ];
      });

  @override
  Future<AggregatorProfile> getProfile() => mockDelay(_readProfile);

  @override
  Future<AggregatorProfile> updateProfile(AggregatorProfile profile) {
    if (profile.companyName.trim().isEmpty) return mockError('Enter your company name');
    return mockDelay(() {
      _writeSingle(_profileKey, profile, (p) => p.toJson());
      return profile;
    });
  }

  @override
  Future<AggregatorProfile> updateBankDetails({
    required String accountNumber,
    required String ifsc,
  }) {
    if (accountNumber.trim().isEmpty) return mockError('Enter an account number');
    return mockDelay(() {
      // Only the last four digits are ever stored — the full account number
      // never lands on the device, same contract as the artist side.
      final trimmed = accountNumber.trim();
      final last4 = trimmed.substring(trimmed.length < 4 ? 0 : trimmed.length - 4);
      final updated = _readProfile().copyWith(
        bankAccountMasked: '•••• •••• •••• $last4',
        ifsc: ifsc.trim().toUpperCase(),
      );
      _writeSingle(_profileKey, updated, (p) => p.toJson());
      return updated;
    });
  }

  @override
  Future<AggregatorSettings> getSettings() => mockDelay(
        () => _readSingle(
          _settingsKey,
          seedAggregatorSettings,
          AggregatorSettings.fromJson,
          (s) => s.toJson(),
        ),
      );

  @override
  Future<AggregatorSettings> updateSettings(AggregatorSettings settings) => mockDelay(() {
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
        [for (final m in messages) m.id == id ? updated : m],
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
