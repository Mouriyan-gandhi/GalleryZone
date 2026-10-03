import 'dart:math' as math;

import '../../core/format.dart';
import '../../core/pricing.dart';
import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/mou.dart';
import '../../features/aggregator/aggregator_mou_data.dart' show aggregatorMouVersion;
import '../../features/shell/mou/mou_document.dart' show mouDetailLabel, mouPartyDetailsFor;
import '../../features/shell/portal_widgets.dart' show gstinPattern;
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

  /// This month's terms for one artwork. The same numbers the real service
  /// serves, so the offline reserve screen quotes what a reservation would hold.
  AggregatorOffer _buildOffer(Artwork artwork) {
    final month = _cycleMonthFor(artwork.id);
    final artistPrice = artistPriceOf(artwork);
    final past = _pastHoldingsFor(artwork.id);
    final cycleStartedAt = _cycleStartFor(artwork.id);
    // Client, 30 Sep 2026: if the month-1 aggregator priced above the offer, the
    // next one is back at the full price and the monthly drops start a month
    // later.
    final appreciated = past.isNotEmpty && past.first.displayPriceSetAt != null;

    // Before GST: the floor an aggregator may not go below, and what the
    // commission is worked from. The price a customer sees adds GST to it.
    final sellingPrice = aggregatorOfferPriceOf(artistPrice, month, appreciated: appreciated);
    final offerPrice = withGst(sellingPrice);
    final standardPrice = withGst(aggregatorOfferPriceOf(artistPrice, 1));

    final advance = aggregatorAdvanceForMonth(
      month: month,
      // Month 1 is charged on the price the aggregator sets, before GST; here
      // that is GalleryZone's own until they choose another when reserving.
      sellingPrice: sellingPrice,
      artistPrice: artistPrice,
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
      canSetPrice: canSetDisplayPrice(month),
      daysLeftInListing: cycleStartedAt == null
          ? aggregatorListingDays
          : daysLeftInListing(cycleStartedAt),
      sellingPrice: sellingPrice,
      standardPrice: standardPrice,
      monthlyReduction: math.max(0.0, standardPrice - offerPrice),
      // GalleryZone is told, never the aggregator blocked, once the price
      // reaches double its own.
      priceWarnFrom: canSetDisplayPrice(month) ? sellingPrice * 2 : null,
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
        // Of the pieces that have finished (sold or sent back), the share that sold;
        // one still on display is neither, so it isn't in the denominator.
        final returned = holdings.where((h) => h.status == HoldingStatus.returned).length;
        final finished = sold.length + returned;
        return AggregatorDashboardSummary(
          activeReservations:
              holdings.where((h) => h.status == HoldingStatus.reserved).length,
          commissionEarned: commission,
          pendingSettlements: sold.length,
          conversionRate: finished == 0 ? null : (sold.length / finished * 100).round(),
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
  Future<AggregatorHolding> reserve(
    String artworkId, {
    double? sellingPrice,
    bool simulateConflict = false,
  }) {
    if (simulateConflict) return mockError('Artwork no longer available');

    // MOU first, inventory second: an unsigned aggregator has no agreement
    // covering custody, pricing or settlement, so they cannot take possession
    // of anyone's artwork. Enforced here rather than only in the UI.
    if (_readProfile().mouAcceptance == null) {
      return mockError(
        'Sign your Aggregator MOU in My Profile before reserving artwork',
      );
    }

    // GST is the second precondition (client, 30 Sep 2026), in the API's words.
    if (_readProfile().gstStatus != ReviewStatus.approved) {
      return mockError(
        'Add your GST number in My Profile, and wait for GalleryZone to approve it, before reserving artwork',
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

    // Month 1 only: the aggregator may price the piece, once, as they reserve it
    // - whole rupees, before GST, never below GalleryZone's own price. From month
    // 2 the price is GalleryZone's and any figure sent is ignored.
    final chosen = offer.canSetPrice && sellingPrice != null ? sellingPrice : null;
    if (chosen != null) {
      if (chosen != chosen.roundToDouble() || chosen <= 0) {
        return mockError('Enter a price in whole rupees.');
      }
      if (chosen < offer.sellingPrice) {
        return mockError("It can't be lower than GalleryZone's price, ${formatInr(offer.sellingPrice)}.");
      }
    }
    final price = chosen ?? offer.sellingPrice;
    final raised = price > offer.sellingPrice;
    final advance = aggregatorAdvanceForMonth(
      month: offer.month,
      sellingPrice: price,
      artistPrice: artistPriceOf(artwork),
    );

    // The advance is not a fresh payment every time — it is LOCKED from the
    // aggregator's wallet. Deposit once, and each reservation holds what it
    // needs; only a shortfall has to be topped up. Enforced here so a stale
    // screen cannot reserve past the balance.
    final wallet = _readWallet();
    final free = wallet.balance - wallet.lockedBalance;
    if (free < advance.payable) {
      final shortfall = advance.payable - free;
      return mockError(
        'Add ${formatInr(shortfall)} to your wallet to reserve this piece — '
        '${formatInr(advance.payable)} needs to be held and only '
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
        advanceAmount: advance.advance,
        // Held alongside the advance (MOU §7). Returned on a sale; forfeited
        // if the piece goes back unsold.
        deliveryDeposit: advance.deliveryCharge,
        cycleMonth: offer.month,
        // What a customer sees: the price chosen (or GalleryZone's), plus GST.
        // Set here, once - a piece's price can't be changed after it is reserved.
        displayPrice: withGst(price),
        displayPriceSetAt: raised ? assignedAt.toIso8601String() : null,
        appreciated: raised,
        priceWarning: offer.priceWarnFrom != null && price >= offer.priceWarnFrom!,
        assignedAt: assignedAt.toIso8601String(),
        expiresAt: window.expiresAt.toIso8601String(),
        windowExtended: window.extended,
        status: HoldingStatus.reserved,
        assignmentSource: AssignmentSource.selfReserved,
      );

      _writeWallet(
        wallet.copyWith(lockedBalance: wallet.lockedBalance + advance.payable),
      );
      _pushTransactions([
        WalletTransaction(
          id: 'wt-${assignedAt.microsecondsSinceEpoch}',
          type: WalletTransactionType.adjustment,
          label:
              'Held for "${artwork.title}" — month ${offer.month} advance & delivery',
          amount: -advance.payable,
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
  Future<AggregatorHolding> requestExtension(String holdingId, String assurance) {
    final holdings = _readHoldings();
    final holding = holdings.where((h) => h.id == holdingId).firstOrNull;
    if (holding == null) return mockError('Holding not found');
    if (assurance.trim().length < 10) return mockError('Tell GalleryZone why this piece will sell');
    return mockDelay(() {
      final updated = holding.copyWith(
        extensionRequest: HoldingExtensionRequest(
          status: ExtensionStatus.pending,
          assurance: assurance.trim(),
          requestedAt: DateTime.now().toIso8601String(),
          previousExpiresAt: holding.expiresAt,
        ),
      );
      _writeHoldings([for (final h in holdings) h.id == holdingId ? updated : h]);
      return updated;
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
  Future<AggregatorHoldingView?> getHolding(String holdingId) => mockDelay(() {
        final holding = _readHoldings().where((h) => h.id == holdingId).firstOrNull;
        final artwork = holding == null ? null : _artworkById(holding.artworkId);
        return holding == null || artwork == null
            ? null
            : AggregatorHoldingView(holding: holding, artwork: artwork);
      });

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
        remitDueAt: input.paymentRoute == PaymentRoute.cashAtPremises
            ? now.add(const Duration(days: cashRemittanceDays)).toIso8601String()
            : null,
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
  Future<List<AggregatorSale>> listSales() =>
      mockDelay(() => _readSales()..sort((a, b) => b.soldAt.compareTo(a.soldAt)));

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
        return byEmail.values.toList()..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
      });

  @override
  Future<Map<String, double>> saleCommissions() =>
      mockDelay(() => {for (final sale in _readSales()) sale.id: _commissionForSale(sale)});

  @override
  Future<AggregatorSale> advanceShipment(String saleId, {String? courierRef}) {
    final sales = _readSales();
    final sale = sales.where((s) => s.id == saleId).firstOrNull;
    if (sale == null) return mockError('Sale not found');
    if (sale.shipmentStatus == ShipmentStatus.delivered) {
      return mockError('Shipment is already delivered');
    }

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final updated = sale.shipmentStatus == ShipmentStatus.preparing
          ? sale.copyWith(
              shipmentStatus: ShipmentStatus.dispatched,
              dispatchedAt: now,
              courierRef: courierRef != null && courierRef.trim().isNotEmpty ? courierRef.trim() : sale.courierRef,
            )
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
  Future<GallerySpace> addGallerySpace(GallerySpace space) => mockDelay(() {
        final spaces = MockDb.getCollection(
          _gallerySpacesKey,
          seedGallerySpaces,
          GallerySpace.fromJson,
          (s) => s.toJson(),
        );
        final added = space.copyWith(id: 'space-${DateTime.now().microsecondsSinceEpoch}');
        MockDb.setCollection(_gallerySpacesKey, [...spaces, added], (s) => s.toJson());
        return added;
      });

  @override
  Future<WalletSummary> getWallet() => mockDelay(_readWallet);

  @override
  Future<List<WalletTransaction>> listWalletTransactions() => mockDelay(_readTransactions);

  @override
  Future<WalletTransaction> addFunds(double amount) {
    if (amount < aggregatorTopupMin || amount > aggregatorTopupMax) {
      return mockError('Add between ₹1,000 and ₹5,00,000 at a time.');
    }
    return mockDelay(() {
      final wallet = _readWallet();
      _writeWallet(wallet.copyWith(balance: wallet.balance + amount));
      final transaction = WalletTransaction(
        id: 'wt-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletTransactionType.adjustment,
        label: 'Added to wallet',
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
  Future<AggregatorSale> markRemitted(String saleId, {RemitVia via = RemitVia.wallet}) {
    final sales = _readSales();
    final sale = sales.where((s) => s.id == saleId).firstOrNull;
    if (sale == null) return mockError('Sale not found');
    if (sale.paymentRoute != PaymentRoute.cashAtPremises) {
      return mockError('Only cash sales need paying in to GalleryZone');
    }
    if (sale.remittedAt != null) return mockError('Already marked as transferred');

    // From the wallet it is the FREE balance that pays - what is held for pieces
    // on display is not available. Checked here as the API checks it, so a
    // stale screen can't overdraw.
    final wallet = _readWallet();
    final free = math.max(0.0, wallet.balance - wallet.lockedBalance);
    if (via == RemitVia.wallet && free < sale.soldPrice) {
      return mockError(
        'Your wallet has ${formatInr(free)} free and this sale is ${formatInr(sale.soldPrice)}. '
        'Add ${formatInr(sale.soldPrice - free)} to your wallet, then pay it in.',
      );
    }

    return mockDelay(() {
      final now = DateTime.now();
      final updated = sale.copyWith(remittedAt: now.toIso8601String(), remittedVia: via);
      _writeSales([for (final s in sales) s.id == saleId ? updated : s]);
      // A bank transfer moves no wallet money: the cash the sale already counted
      // has arrived at GalleryZone's account.
      if (via == RemitVia.wallet) {
        _writeWallet(wallet.copyWith(balance: wallet.balance - sale.soldPrice));
        final title = _artworkById(sale.artworkId)?.title;
        _pushTransactions([
          WalletTransaction(
            id: 'wt-${now.microsecondsSinceEpoch}',
            type: WalletTransactionType.adjustment,
            label: title == null ? 'Cash sale paid to GalleryZone' : 'Cash sale paid to GalleryZone · $title',
            amount: -sale.soldPrice,
            date: now.toIso8601String().substring(0, 10),
            status: WalletTransactionStatus.completed,
          ),
        ]);
      }
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
    final gst = profile.gstNumber.trim().toUpperCase();
    if (gst.isNotEmpty && !gstinPattern.hasMatch(gst)) {
      return mockError('GSTIN must be the 15-character registration number');
    }
    return mockDelay(() {
      final current = _readProfile();
      // What a client may not set stays as it was: GalleryZone decides the GST
      // verdict, the agreement is signed through its own call, and a different
      // number goes back under review - as on the API.
      final next = profile.copyWith(
        gstNumber: gst,
        gstStatus: gst == current.gstNumber
            ? current.gstStatus
            : (gst.isEmpty ? ReviewStatus.notSubmitted : ReviewStatus.submitted),
        mouAcceptance: current.mouAcceptance,
        securityDepositStatus: current.securityDepositStatus,
        bankAccountMasked: current.bankAccountMasked,
        aadhaarStatus: current.aadhaarStatus,
        aadhaarMasked: current.aadhaarMasked,
      );
      _writeSingle(_profileKey, next, (p) => p.toJson());
      return next;
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

  /// Mirrors the API's checks: the current version, the contact person's name
  /// as on the profile, and every blank the agreement needs. The drawn signature
  /// is optional here only because the offline build has no pad in its unit
  /// tests.
  @override
  Future<AggregatorProfile> acceptMou({
    required String signatureName,
    required String version,
    String signatureDataUrl = '',
  }) async {
    if (signatureName.trim().isEmpty) throw Exception('Type your full name to sign');
    final state = await getMouState();
    final profile = _readProfile();
    if (version != state.draft.version) {
      throw Exception('This agreement has been updated. Reload the page to read and sign the current version');
    }
    if (signatureName.trim().toLowerCase() != profile.contactPerson.trim().toLowerCase()) {
      throw Exception('The signature must match the name on your profile');
    }
    if (state.draft.missing.isNotEmpty) {
      throw Exception('Add your ${state.draft.missing.map((key) => (mouDetailLabel[key] ?? key).toLowerCase()).join(', ')} to your profile before signing');
    }
    return mockDelay(() {
      final updated = profile.copyWith(
        mouAcceptance: MouAcceptance(
          acceptedAt: DateTime.now().toUtc().toIso8601String(),
          signatureName: signatureName.trim(),
          version: version,
          signatureDataUrl: signatureDataUrl,
          parties: state.draft.parties,
        ),
      );
      _writeSingle(_profileKey, updated, (p) => p.toJson());
      return updated;
    });
  }

  /// The agreement with its blanks filled from the profile exactly as the API
  /// does it ([mouPartyDetailsFor]).
  @override
  Future<MouState> getMouState() => mockDelay(() {
        final profile = _readProfile();
        final acceptance = profile.mouAcceptance;
        final filled = mouPartyDetailsFor(
          party: MouParty.aggregator,
          fullName: profile.contactPerson,
          email: profile.email,
          phone: profile.phone,
          gstin: profile.gstNumber,
          companyName: profile.companyName,
          pickupLine1: profile.addressLine1,
          pickupCity: profile.addressCity,
          pickupState: profile.addressState,
          pickupPincode: profile.addressPincode,
        );
        return MouState(
          draft: MouDraft(
            version: aggregatorMouVersion,
            parties: MouParties(
              party: filled.details,
              company: const MouCompanyDetails(name: 'Galleryzone Private Limited'),
            ),
            missing: filled.missing,
            asOf: DateTime.now().toUtc().toIso8601String(),
          ),
          acceptance: acceptance != null && acceptance.version == aggregatorMouVersion ? acceptance : null,
        );
      });

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
