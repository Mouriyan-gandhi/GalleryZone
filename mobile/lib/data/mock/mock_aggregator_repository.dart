import '../../core/format.dart';
import '../../core/pricing.dart';
import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../repositories/aggregator_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artist_repository.dart'
    show artistPriceOf, creditArtistForSale;
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

  /// The commission a sale carries: MOU §8's 20% of the holding's markup over
  /// the ARTIST's price. Returns 0 if either record has gone missing.
  double _commissionForSale(AggregatorSale sale) {
    final holding = _readHoldings().where((h) => h.id == sale.holdingId).firstOrNull;
    final artwork = _artworkById(sale.artworkId);
    if (holding == null || artwork == null) return 0;
    return aggregatorCommissionFor(
      displayPrice: holding.displayPrice,
      artistPrice: artistPriceOf(artwork),
    );
  }

  // --- The five-month cycle -------------------------------------------------
  //
  // A piece that doesn't sell is offered to a different aggregator each month,
  // five times, each at a lower price and a different advance rate (see
  // `core/pricing.dart`). The month is a property of the ARTWORK's journey,
  // not of any one aggregator, so it is counted from how many aggregators have
  // already had it — which is why returned holdings are kept rather than
  // deleted.

  /// Placements this artwork has already been through, in order.
  List<AggregatorHolding> _pastHoldingsFor(String artworkId) => [
        for (final holding in _readHoldings())
          if (holding.artworkId == artworkId &&
              holding.status == HoldingStatus.returned)
            holding,
      ]..sort((a, b) => a.assignedAt.compareTo(b.assignedAt));

  /// Which month of the cycle the NEXT placement of this artwork would be.
  int _cycleMonthFor(String artworkId) => _pastHoldingsFor(artworkId).length + 1;

  /// When this artwork's 180-day listing started — the first time any
  /// aggregator took it. Null means it has never been placed, so the clock has
  /// not started.
  DateTime? _cycleStartFor(String artworkId) {
    final all = [
      for (final holding in _readHoldings())
        if (holding.artworkId == artworkId) holding,
    ]..sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
    return all.isEmpty ? null : DateTime.parse(all.first.assignedAt);
  }

  /// Can this piece go to another aggregator, or is its listing done?
  bool _isPlaceable(String artworkId, {DateTime? now}) =>
      canPlaceWithAnotherAggregator(
        cycleStartedAt: _cycleStartFor(artworkId),
        placementsSoFar: _pastHoldingsFor(artworkId).length,
        now: now,
      );

  /// This month's terms for one artwork.
  AggregatorOffer _buildOffer(Artwork artwork) {
    final month = _cycleMonthFor(artwork.id);
    final artistPrice = artistPriceOf(artwork);
    // GST-inclusive, exactly like Artwork.customerPrice — the aggregator's
    // floor and the customer's price have to be the same kind of number, or
    // the commission (which strips GST back out) is computed against the wrong
    // base.
    final offerPrice = withGst(aggregatorOfferPriceOf(artistPrice, month));
    final past = _pastHoldingsFor(artwork.id);
    final cycleStartedAt = _cycleStartFor(artwork.id);
    final previousChangedPrice =
        past.isNotEmpty && past.last.displayPriceSetAt != null;

    final advance = aggregatorAdvanceForMonth(
      month: month,
      // Month 1 is charged on the display price, which at reservation time is
      // the offer price — the aggregator has not set their own yet.
      displayPrice: offerPrice,
      artistPrice: artistPrice,
      previousAggregatorChangedPrice: previousChangedPrice,
    );

    return AggregatorOffer(
      artworkId: artwork.id,
      month: month,
      offerPrice: offerPrice,
      marketplacePrice: artwork.customerPrice,
      advance: advance.advance,
      advanceRate: advance.rate,
      advanceBase: advance.base,
      advanceBasis: advance.basis,
      deliveryCharge: advance.deliveryCharge,
      payable: advance.payable,
      previousAggregatorChangedPrice: previousChangedPrice,
      canSetPrice: canSetDisplayPrice(month),
      daysLeftInListing: cycleStartedAt == null
          ? aggregatorListingDays
          : daysLeftInListing(cycleStartedAt),
    );
  }

  void _writeWallet(WalletSummary wallet) =>
      _writeSingle(_walletKey, wallet, (w) => w.toJson());

  void _pushTransactions(List<WalletTransaction> rows) {
    if (rows.isEmpty) return;
    _writeTransactions([...rows, ..._readTransactions()]);
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
            artistPrice: artistPriceOf(artwork),
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
  Future<List<ReservableArtwork>> listReservableInventory() => mockDelay(() {
        // A returned holding no longer claims its artwork — that is the whole
        // point of the cycle: the piece goes back and the next aggregator can
        // take it, at the next month's price.
        final claimed = {
          for (final holding in _readHoldings())
            if (holding.status != HoldingStatus.returned) holding.artworkId,
        };
        return [
          for (final artwork in _readArtworks())
            // Ask the predicate, not the literal: an aggregator-only piece is
            // reservable here even though it never appears in the marketplace
            // grid.
            if (isAggregatorListed(artwork.listingType) &&
                artwork.status == ArtworkStatus.marketplace &&
                !claimed.contains(artwork.id) &&
                // Five placements, or fewer if the 180 days run out first. A
                // stub of under thirty days is never placed with a new
                // aggregator — it goes to whoever already has the piece.
                _isPlaceable(artwork.id))
              ReservableArtwork(artwork: artwork, offer: _buildOffer(artwork)),
        ];
      });

  @override
  Future<AggregatorHolding> reserve(String artworkId, {bool simulateConflict = false}) {
    if (simulateConflict) return mockError('Artwork no longer available');

    // MOU first, inventory second: an unsigned aggregator has no agreement
    // covering custody, pricing or settlement, so they cannot take possession
    // of anyone's artwork. Enforced here rather than only in the UI.
    if (_readProfile().mouAcceptance == null) {
      return mockError(
        'Sign your Aggregator MOU in My Profile before reserving artwork',
      );
    }

    final artwork = _artworkById(artworkId);
    final holdings = _readHoldings();
    final alreadyClaimed = holdings.any(
      (h) => h.artworkId == artworkId && h.status != HoldingStatus.returned,
    );
    if (artwork == null || alreadyClaimed) {
      return mockError('Artwork no longer available');
    }
    if (!_isPlaceable(artworkId)) {
      return mockError(
        'This piece has finished its listing period and is going back to the artist',
      );
    }

    final offer = _buildOffer(artwork);

    // The advance is not a fresh payment every time — it is LOCKED from the
    // aggregator's wallet. Deposit once, and each reservation holds what it
    // needs; only a shortfall has to be topped up. Enforced here so a stale
    // screen cannot reserve past the balance.
    final wallet = _readWallet();
    final free = wallet.balance - wallet.lockedBalance;
    if (free < offer.payable) {
      final shortfall = offer.payable - free;
      return mockError(
        'Add ${formatInr(shortfall)} to your wallet to reserve this piece — '
        '${formatInr(offer.payable)} needs to be held and only '
        '${formatInr(free < 0 ? 0 : free)} is free.',
      );
    }

    return mockDelay(() {
      final assignedAt = DateTime.now();
      // Thirty days, unless what would be left over afterwards is too short to
      // place with anyone else — then this aggregator keeps it to the end of
      // the artist's 180 days rather than the piece making one more pointless
      // trip.
      final window = placementWindow(
        cycleStartedAt: _cycleStartFor(artworkId) ?? assignedAt,
        assignedAt: assignedAt,
      );

      final holding = AggregatorHolding(
        id: 'hold-${holdings.length + 1}-${assignedAt.microsecondsSinceEpoch}',
        artworkId: artworkId,
        advancePercent: advancePercentFor(offer.month),
        advanceAmount: offer.advance,
        // Held alongside the advance (MOU §7). Returned on a sale; forfeited
        // if the piece goes back unsold.
        deliveryDeposit: offer.deliveryCharge,
        cycleMonth: offer.month,
        // This month's offer price is the floor — the collection screen can
        // raise it, never lower, and only in month one.
        displayPrice: offer.offerPrice,
        assignedAt: assignedAt.toIso8601String(),
        expiresAt: window.expiresAt.toIso8601String(),
        windowExtended: window.extended,
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.selfReserved,
      );

      _writeWallet(
        wallet.copyWith(lockedBalance: wallet.lockedBalance + offer.payable),
      );
      _pushTransactions([
        WalletTransaction(
          id: 'wt-${assignedAt.microsecondsSinceEpoch}',
          type: WalletTransactionType.adjustment,
          label:
              'Held for "${artwork.title}" — month ${offer.month} advance & delivery',
          amount: -offer.payable,
          date: assignedAt.toIso8601String().substring(0, 10),
          status: WalletTransactionStatus.pending,
        ),
      ]);
      _writeHoldings([...holdings, holding]);
      return holding;
    });
  }

  // The piece did not sell and goes back to GalleryZone. The money-flow sheet
  // is explicit that only the advance comes back in this case — the delivery
  // charge is settled only on a sale, so an unsold return costs the aggregator
  // that leg. Frees the artwork to be reserved again, by the NEXT aggregator
  // in the cycle.
  @override
  Future<HoldingRelease> releaseHolding(String holdingId) {
    final holdings = _readHoldings();
    final holding = holdings.where((h) => h.id == holdingId).firstOrNull;
    if (holding == null) return mockError('Reservation not found');
    if (holding.status != HoldingStatus.reserved) {
      return mockError('This piece has already sold and cannot be returned');
    }

    return mockDelay(() {
      final artwork = _artworkById(holding.artworkId);
      final title = artwork?.title ?? 'Artwork';
      final deliveryLost = holding.deliveryDeposit;
      final held = holding.advanceAmount + deliveryLost;
      final now = DateTime.now();
      final date = now.toIso8601String().substring(0, 10);

      // The advance and delivery were locked from the aggregator's own wallet,
      // never taken from it, so nothing is "credited back" here — the hold is
      // released. The delivery portion is the exception: the sheet settles it
      // only on a sale, so an unsold return actually spends it.
      final wallet = _readWallet();
      _writeWallet(
        wallet.copyWith(
          lockedBalance: (wallet.lockedBalance - held).clamp(0, double.infinity),
          balance: wallet.balance - deliveryLost,
        ),
      );
      _pushTransactions([
        WalletTransaction(
          id: 'wt-${now.microsecondsSinceEpoch}',
          type: WalletTransactionType.refund,
          label: 'Advance released: "$title"',
          amount: holding.advanceAmount,
          date: date,
          status: WalletTransactionStatus.completed,
        ),
        if (deliveryLost > 0)
          WalletTransaction(
            id: 'wt-${now.microsecondsSinceEpoch + 1}',
            type: WalletTransactionType.adjustment,
            label: 'Delivery charged — "$title" returned unsold',
            amount: -deliveryLost,
            date: date,
            status: WalletTransactionStatus.completed,
          ),
      ]);

      // Kept, not deleted: the next aggregator's price and advance are counted
      // off how many placements this artwork has already been through.
      _writeHoldings([
        for (final h in holdings)
          if (h.id == holdingId)
            h.copyWith(
              status: HoldingStatus.returned,
              returnedAt: now.toIso8601String(),
            )
          else
            h,
      ]);

      return HoldingRelease(
        refunded: holding.advanceAmount,
        deliveryLost: deliveryLost,
      );
    });
  }

  @override
  Future<List<AggregatorHoldingView>> listCollection() => mockDelay(() {
        final byId = {for (final artwork in _readArtworks()) artwork.id: artwork};
        return [
          // Returned pieces are history for the cycle counter, not part of
          // anyone's current collection.
          for (final holding in _readHoldings())
            if (holding.status != HoldingStatus.returned &&
                byId[holding.artworkId] != null)
              AggregatorHoldingView(holding: holding, artwork: byId[holding.artworkId]!),
        ];
      });

  @override
  Future<AggregatorHolding> updateDisplayPrice(String holdingId, double displayPrice) {
    final holdings = _readHoldings();
    final existing = holdings.where((h) => h.id == holdingId).firstOrNull;
    if (existing == null) return mockError('No holding "$holdingId"');

    // Only the FIRST aggregator prices the piece. After that the price is
    // GalleryZone's calculated figure, because from month two the aggregator
    // is already getting a cheaper advance — they don't get both.
    if (!canSetDisplayPrice(existing.cycleMonth)) {
      return mockError(
        'The selling price is set by GalleryZone for this piece — only the '
        'first aggregator to display a work can price it',
      );
    }
    // MOU §6: one opportunity only. Enforced here, not just by hiding the
    // button, so a stale screen can't post a second price.
    if (existing.displayPriceSetAt != null) {
      return mockError(
        'The selling price for this artwork has already been set and cannot '
        'be changed (MOU §6)',
      );
    }
    if (displayPrice < existing.displayPrice) {
      // Enforced here, not only in the form: the floor is a platform rule
      // (SAD §2.7), and a rule the UI alone upholds isn't a rule.
      return mockError('Display price cannot go below the offer price');
    }

    // Month one's advance is 5% of the DISPLAY price, so raising the price
    // raises the advance. The difference is held from the wallet on the spot —
    // "if the amount is on the higher side he needs to deposit the extra".
    final artwork = _artworkById(existing.artworkId);
    final newAdvance = artwork == null
        ? existing.advanceAmount
        : aggregatorAdvanceForMonth(
            month: existing.cycleMonth,
            displayPrice: displayPrice,
            artistPrice: artistPriceOf(artwork),
          ).advance;
    final topUp = newAdvance - existing.advanceAmount;

    if (topUp > 0) {
      final wallet = _readWallet();
      final free = wallet.balance - wallet.lockedBalance;
      if (free < topUp) {
        return mockError(
          'Raising the price raises the advance. Add '
          '${formatInr(topUp - free)} to your wallet first — '
          '${formatInr(topUp)} more needs to be held.',
        );
      }
    }

    return mockDelay(() {
      final now = DateTime.now();
      if (topUp > 0) {
        final wallet = _readWallet();
        _writeWallet(
          wallet.copyWith(lockedBalance: wallet.lockedBalance + topUp),
        );
        _pushTransactions([
          WalletTransaction(
            id: 'wt-${now.microsecondsSinceEpoch}',
            type: WalletTransactionType.adjustment,
            label:
                'Additional advance held — "${artwork?.title ?? 'Artwork'}" priced up',
            amount: -topUp,
            date: now.toIso8601String().substring(0, 10),
            status: WalletTransactionStatus.pending,
          ),
        ]);
      }

      final updated = existing.copyWith(
        displayPrice: displayPrice,
        advanceAmount: newAdvance,
        displayPriceSetAt: now.toIso8601String(),
      );
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
        paymentRoute: input.paymentRoute,
        // Cash taken at the counter is GalleryZone's money sitting in the
        // aggregator's till until they transfer it.
        remittedAt: null,
        courierRef: input.deliveryMode == DeliveryMode.courier
            ? 'CR-${stamp.toRadixString(36).toUpperCase()}'
            : null,
      );
      _writeSales([sale, ..._readSales()]);

      // A sale settles all three lines on the sheet — 7,500 advance + 2,500
      // delivery + 10,000 commission = 20,000. But the first two were LOCKED
      // from this aggregator's own wallet rather than taken from it, so they
      // are released, not credited. Only the commission is new money, and it
      // accrues as *pending* until the settlement is processed — the wallet
      // never shows money the aggregator can't yet take out.
      final artwork = _artworkById(input.artworkId);
      if (artwork != null) {
        final commission = aggregatorCommissionFor(
          displayPrice: holding.displayPrice,
          artistPrice: artistPriceOf(artwork),
        );
        final held = holding.advanceAmount + holding.deliveryDeposit;
        final date = now.toIso8601String().substring(0, 10);

        final wallet = _readWallet();
        _writeWallet(
          wallet.copyWith(
            lockedBalance: (wallet.lockedBalance - held).clamp(0, double.infinity),
            pendingBalance: wallet.pendingBalance + commission,
          ),
        );

        // The client's answer on the advance was "both" — it always comes back
        // AND it is adjusted against what is owed. Both are true at once if it
        // is settled as one statement rather than two movements: the advance
        // is set off against the sale, and the aggregator ends up whole either
        // way.
        _pushTransactions([
          if (held > 0)
            WalletTransaction(
              id: 'wt-$stamp',
              type: WalletTransactionType.refund,
              label: '"${artwork.title}" sold — ${formatInr(held)} '
                  'advance & delivery set off against settlement',
              amount: held,
              date: date,
              status: WalletTransactionStatus.completed,
            ),
          if (commission > 0)
            WalletTransaction(
              id: 'wt-${stamp + 1}',
              type: WalletTransactionType.commission,
              label: 'Commission: "${artwork.title}"',
              amount: commission,
              date: date,
              status: WalletTransactionStatus.pending,
            ),
        ]);

        // The artist's side of the same sale: their price less the delivery
        // leg and 2% convenience (1,00,000 -> 95,500 on the sheet).
        creditArtistForSale(
          artwork: artwork,
          orderId: sale.id,
          channel: SaleChannel.aggregator,
        );
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
  Future<WalletTransaction> addFunds(double amount) {
    if (amount <= 0) return mockError('Enter an amount to add');
    return mockDelay(() {
      final wallet = _readWallet();
      _writeWallet(wallet.copyWith(balance: wallet.balance + amount));
      final transaction = WalletTransaction(
        id: 'wt-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletTransactionType.adjustment,
        label: 'Wallet top-up',
        amount: amount,
        date: DateTime.now().toIso8601String().substring(0, 10),
        status: WalletTransactionStatus.completed,
      );
      _pushTransactions([transaction]);
      return transaction;
    });
  }

  @override
  Future<WalletTransaction> requestWithdrawal(double amount) {
    final wallet = _readWallet();
    final free = wallet.balance - wallet.lockedBalance;
    if (amount < aggregatorMinimumWithdrawal) {
      return mockError('Minimum withdrawal is ₹1,000');
    }
    // Money held against an active reservation is not yours to take out.
    if (amount > free) {
      return mockError(
        'Only ${formatInr(free < 0 ? 0 : free)} is free — the rest is held '
        'against artwork you have reserved',
      );
    }

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
  Future<List<AggregatorSale>> listRemittancesDue() => mockDelay(() => [
        for (final sale in _readSales())
          if (sale.paymentRoute == PaymentRoute.cashAtPremises &&
              sale.remittedAt == null)
            sale,
      ]);

  @override
  Future<AggregatorSale> markRemitted(String saleId) {
    final sales = _readSales();
    final sale = sales.where((s) => s.id == saleId).firstOrNull;
    if (sale == null) return mockError('Sale not found');
    if (sale.remittedAt != null) return mockError('Already marked as transferred');

    return mockDelay(() {
      final now = DateTime.now();
      final updated = sale.copyWith(remittedAt: now.toIso8601String());
      _writeSales([for (final s in sales) s.id == saleId ? updated : s]);
      _pushTransactions([
        WalletTransaction(
          id: 'wt-${now.microsecondsSinceEpoch}',
          type: WalletTransactionType.adjustment,
          label: 'Transferred to GalleryZone — sale ${sale.id}',
          amount: -sale.soldPrice,
          date: now.toIso8601String().substring(0, 10),
          status: WalletTransactionStatus.completed,
        ),
      ]);
      return updated;
    });
  }

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
  Future<AggregatorProfile> acceptMou({
    required String signatureName,
    required String version,
  }) {
    if (signatureName.trim().isEmpty) {
      return mockError('Type your full name to sign');
    }
    return mockDelay(() {
      final updated = _readProfile().copyWith(
        mouAcceptance: MouAcceptance(
          acceptedAt: DateTime.now().toIso8601String(),
          signatureName: signatureName.trim(),
          version: version,
        ),
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
